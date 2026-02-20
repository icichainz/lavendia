import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/receipt_model.dart';
import 'notification_service.dart';

/// The callback for the foreground task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(OrderMonitorTaskHandler());
}

/// Task handler that runs in the foreground service
class OrderMonitorTaskHandler extends TaskHandler {
  final _logger = Logger();

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

  /// Poll the API for status changes
  Future<void> _pollForStatusChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userRole = prefs.getString('user_role');

      // Only poll for customers
      if (accessToken == null || userRole != 'customer') {
        _logger.d('Skipping poll - not a logged-in customer');
        return;
      }

      _logger.d('Polling for order status changes...');

      // Fetch current orders
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: ApiConstants.authHeaders(accessToken),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get(ApiConstants.myReceipts);

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
        _logger.w('Token expired, need to refresh');
        // Could implement token refresh here
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

  /// Save user info for background polling
  Future<void> saveUserCredentials({
    required String accessToken,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('user_role', userRole);
    _logger.i('User credentials saved for background polling');
  }

  /// Clear user credentials (call on logout)
  Future<void> clearUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await clearCache();
    _logger.i('User credentials cleared');
  }
}
