import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/storage_keys.dart';
import '../models/receipt_model.dart';
import 'notification_service.dart';

/// The callback for the foreground task
@pragma('vm:entry-point')
void startCallback() {
  // Belt and braces: setTaskHandler() below already calls this (and
  // WidgetsFlutterBinding.ensureInitialized) before wiring up the channel, so
  // plugins do work in this isolate. Kept as an explicit statement of the
  // dependency, since the handler reads secure storage.
  DartPluginRegistrant.ensureInitialized();
  FlutterForegroundTask.setTaskHandler(OrderMonitorTaskHandler());
}

/// Task handler that runs in the foreground service
class OrderMonitorTaskHandler extends TaskHandler {
  final _logger = Logger();
  final _secureStorage = const FlutterSecureStorage();

  /// One long-lived client, so polls reuse the connection instead of paying a
  /// fresh TCP+TLS handshake every 30 seconds. The auth header is set per
  /// request rather than on BaseOptions, since the token changes on refresh.
  ///
  /// Deliberately interceptor-free - a retry-on-401 interceptor here would
  /// recurse through the refresh call below.
  late final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: ApiConstants.headers,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// The in-flight refresh, if any.
  ///
  /// Overlapping polls are guaranteed, not hypothetical: flutter_foreground_task
  /// dispatches onStart and onRepeatEvent without awaiting them, and the repeat
  /// loop fires before its first delay. Holding the future (rather than a bool)
  /// means a second poll joins the running refresh and gets the real result,
  /// instead of being told the session is dead.
  Future<String?>? _refreshInFlight;

  /// Serialises polls so two runs cannot interleave their read-modify-write of
  /// the cached status map and double-notify for the same change.
  Future<void>? _pollInFlight;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _logger.i('Order monitor service started at $timestamp');

    // Initialize notification service in isolate
    await NotificationService().initialize();

    // Start polling immediately
    await _pollForStatusChanges();
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Called periodically by the foreground task
    await _pollForStatusChanges();
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) {
    _logger.i('Order monitor service destroyed at $timestamp');
  }

  @override
  void onNotificationButtonPressed(String id) {
    _logger.i('Notification button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    _logger.i('Notification pressed - opening app');
    FlutterForegroundTask.launchApp('/');
  }

  /// Per-request auth header for [token].
  Options _auth(String token) =>
      Options(headers: ApiConstants.authHeaders(token));

  /// Exchange the stored refresh token for a new access token.
  ///
  /// Concurrent callers share one in-flight request rather than each issuing
  /// their own - important because the backend blacklists the token it was
  /// given, so two simultaneous refreshes would kill each other's session.
  Future<String?> _refreshAccessToken() =>
      _refreshInFlight ??= _doRefresh().whenComplete(() {
        _refreshInFlight = null;
      });

  /// Returns the new access token, or null if the session is unrecoverable.
  Future<String?> _doRefresh() async {
    // Hoisted so the catch below can compare it against what is in storage
    // after a rejection.
    String? refreshTokenSent;

    try {
      refreshTokenSent =
          await _secureStorage.read(key: StorageKeys.refreshToken);
      if (refreshTokenSent == null) {
        _logger.w('No refresh token stored - cannot recover session');
        return null;
      }

      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refresh': refreshTokenSent},
      );

      if (response.statusCode != 200) return null;

      final newAccessToken = response.data['access'] as String?;
      if (newAccessToken == null) return null;

      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: newAccessToken,
      );

      // The backend runs ROTATE_REFRESH_TOKENS with BLACKLIST_AFTER_ROTATION,
      // so the response carries a replacement refresh token and the one we
      // just sent is now dead. Failing to persist this would make the next
      // refresh fail and silently end the session.
      final newRefreshToken = response.data['refresh'] as String?;
      if (newRefreshToken != null) {
        await _secureStorage.write(
          key: StorageKeys.refreshToken,
          value: newRefreshToken,
        );
      }

      _logger.i('Access token refreshed in background service');
      return newAccessToken;
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 400 || status == 401) {
        // The refresh token was rejected. That can mean the session really is
        // over - or that the foreground app refreshed first and blacklisted
        // the token we just sent. Re-read storage: if it changed underneath
        // us, the other isolate won and left us a usable access token.
        final current =
            await _secureStorage.read(key: StorageKeys.refreshToken);
        if (current != null && current != refreshTokenSent) {
          _logger.i('Refresh raced with the app; adopting its new token');
          return _secureStorage.read(key: StorageKeys.accessToken);
        }

        _logger.w('Refresh token rejected ($status) - session ended');
        return null;
      }

      // Timeout, DNS, no connectivity: transient, keep the session.
      _logger.w('Background token refresh failed transiently: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Background token refresh failed: $e');
      return null;
    }
  }

  /// Tear down a session the server will no longer honour.
  ///
  /// Clears the role marker so later polls short-circuit, tells the user why
  /// monitoring stopped, and stops the service rather than leaving a wakelock
  /// held on a persistent notification that is no longer true.
  Future<void> _endSession() async {
    _logger.w('Session ended - stopping order monitoring');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.userRole);
      await prefs.remove('cached_order_statuses');

      await NotificationService().showSessionExpiredNotification();
    } catch (e) {
      _logger.e('Error while ending session: $e');
    } finally {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Poll the API for status changes.
  ///
  /// Serialised: overlapping invocations join the running poll instead of
  /// racing on the cached status map and double-notifying.
  Future<void> _pollForStatusChanges() =>
      _pollInFlight ??= _doPoll().whenComplete(() {
        _pollInFlight = null;
      });

  Future<void> _doPoll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString(StorageKeys.userRole);

      // Only poll for customers
      if (userRole != 'customer') {
        _logger.d('Skipping poll - not a logged-in customer');
        return;
      }

      // Tokens live in secure storage, never in SharedPreferences.
      final accessToken =
          await _secureStorage.read(key: StorageKeys.accessToken);
      if (accessToken == null) {
        _logger.d('Skipping poll - no access token');
        return;
      }

      _logger.d('Polling for order status changes...');

      // Fetch current orders, refreshing once if the access token has aged
      // out. ACCESS_TOKEN_LIFETIME defaults to 60 minutes, so without this
      // the service goes permanently silent an hour after login.
      Response response;
      try {
        response = await _dio.get(
          ApiConstants.myReceipts,
          options: _auth(accessToken),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 401) rethrow;

        _logger.i('Access token expired during poll, refreshing');
        final refreshedToken = await _refreshAccessToken();
        if (refreshedToken == null) {
          // The session is over. Keep polling and we would issue two doomed
          // requests every 30s forever, on a wakelock, while the persistent
          // notification still claims orders are being monitored.
          await _endSession();
          return;
        }
        response = await _dio.get(
          ApiConstants.myReceipts,
          options: _auth(refreshedToken),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['results'] ?? [];

        // Get cached statuses
        final cachedStatusesJson = prefs.getString('cached_order_statuses') ?? '{}';
        final Map<String, dynamic> cachedStatuses = jsonDecode(cachedStatusesJson);

        // Check for status changes
        final Map<String, String> newStatuses = {};

        for (final orderJson in data) {
          final receipt = ReceiptModel.fromJson(orderJson);
          final orderId = receipt.id.toString();
          final currentStatus = receipt.status;
          final previousStatus = cachedStatuses[orderId];

          newStatuses[orderId] = currentStatus;

          // If status changed and it's not the first time we're seeing this order
          if (previousStatus != null && previousStatus != currentStatus) {
            _logger.i('Order #${receipt.receiptNumber} status changed: $previousStatus -> $currentStatus');

            // Show notification
            await NotificationService().showOrderStatusNotification(
              orderId: receipt.id,
              orderNumber: receipt.receiptNumber,
              status: currentStatus,
            );
          }
        }

        // Save new statuses
        await prefs.setString('cached_order_statuses', jsonEncode(newStatuses));
        _logger.d('Polled ${data.length} orders, cached statuses updated');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // A 401 here means the retry after a successful refresh was itself
        // rejected, so the session is genuinely over rather than just stale.
        _logger.w('Still unauthorized after refresh - session ended');
      } else {
        _logger.e('API error during polling: ${e.message}');
      }
    } catch (e) {
      _logger.e('Error polling for status changes: $e');
    }
  }
}

/// Service to manage the foreground task lifecycle
class OrderMonitorService {
  static final OrderMonitorService _instance = OrderMonitorService._internal();
  factory OrderMonitorService() => _instance;
  OrderMonitorService._internal();

  final _logger = Logger();
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Initialize the foreground task configuration
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      _logger.w('Foreground service only available on Android');
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: NotificationService.foregroundServiceChannelId,
        channelName: 'Order Monitoring Service',
        channelDescription: 'Shows when the app is monitoring your orders',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 30000, // 30 seconds
        isOnceEvent: false,
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _logger.i('Order monitor service initialized');
  }

  /// Start the foreground service
  Future<bool> start() async {
    if (!Platform.isAndroid) {
      _logger.w('Foreground service only available on Android');
      return false;
    }

    if (_isRunning) {
      _logger.i('Service already running');
      return true;
    }

    // Check permissions
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      final granted =
          await FlutterForegroundTask.requestNotificationPermission();
      if (granted != NotificationPermission.granted) {
        _logger.w('Notification permission not granted');
        return false;
      }
    }

    // Check if battery optimization is disabled
    final batteryOptimizationDisabled =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!batteryOptimizationDisabled) {
      _logger.i('Requesting battery optimization exemption');
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Start the service
    final started = await FlutterForegroundTask.startService(
      notificationTitle: 'Lavendia',
      notificationText: 'Monitoring your laundry orders',
      callback: startCallback,
    );

    _isRunning = started;
    _logger.i('Foreground service started: $started');
    return _isRunning;
  }

  /// Stop the foreground service
  Future<bool> stop() async {
    if (!Platform.isAndroid) return true;

    if (!_isRunning) {
      _logger.i('Service not running');
      return true;
    }

    final stopped = await FlutterForegroundTask.stopService();
    _isRunning = !stopped;
    _logger.i('Foreground service stopped: $stopped');
    return stopped;
  }

  /// Restart the service (useful after login/logout)
  Future<bool> restart() async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    return start();
  }

  /// Check if the service is currently running
  Future<bool> checkIfRunning() async {
    if (!Platform.isAndroid) return false;
    _isRunning = await FlutterForegroundTask.isRunningService;
    return _isRunning;
  }

  /// Update the notification text
  Future<void> updateNotification({
    String? title,
    String? text,
  }) async {
    if (!Platform.isAndroid || !_isRunning) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: title ?? 'Lavendia',
      notificationText: text ?? 'Monitoring your laundry orders',
    );
  }

  /// Clear cached order statuses (call on logout)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_order_statuses');
    _logger.i('Order status cache cleared');
  }

  /// Record which role is signed in, so the task handler knows whether to poll.
  ///
  /// Access tokens are deliberately not passed here. The task handler reads
  /// them from secure storage directly - an earlier version copied the access
  /// token into SharedPreferences (plaintext, and stale the moment the
  /// foreground app refreshed it).
  Future<void> saveUserCredentials({required String userRole}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userRole, userRole);

    // Purge the plaintext token written by previous builds.
    await prefs.remove(StorageKeys.accessToken);

    _logger.i('Background polling enabled for role: $userRole');
  }

  /// Clear user credentials (call on logout)
  Future<void> clearUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.userRole);
    await prefs.remove(StorageKeys.accessToken); // legacy plaintext copy
    await clearCache();
    _logger.i('User credentials cleared');
  }
}
