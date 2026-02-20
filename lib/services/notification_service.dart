import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel IDs
  static const String orderStatusChannelId = 'order_status_channel';
  static const String foregroundServiceChannelId = 'foreground_service_channel';

  // Callback for notification taps
  Function(String? payload)? onNotificationTap;

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      if (result == true) {
        await _createNotificationChannels();
        _isInitialized = true;
        _logger.i('Notification service initialized successfully');
      }

      return _isInitialized;
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
      return false;
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Order status channel - high importance for status updates
    const orderStatusChannel = AndroidNotificationChannel(
      orderStatusChannelId,
      'Order Status Updates',
      description: 'Notifications for laundry order status changes',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Foreground service channel - low importance for persistent notification
    const foregroundChannel = AndroidNotificationChannel(
      foregroundServiceChannelId,
      'Order Monitoring Service',
      description: 'Shows when the app is monitoring your orders',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await androidPlugin.createNotificationChannel(orderStatusChannel);
    await androidPlugin.createNotificationChannel(foregroundChannel);

    _logger.i('Notification channels created');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        return granted ?? false;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    } catch (e) {
      _logger.e('Failed to request notification permissions: $e');
      return false;
    }
  }

  /// Show order status change notification
  Future<void> showOrderStatusNotification({
    required int orderId,
    required String orderNumber,
    required String status,
    String? customerName,
  }) async {
    if (!_isInitialized) {
      _logger.w('Notification service not initialized');
      return;
    }

    final notificationInfo = _getStatusNotificationInfo(status, orderNumber);

    const androidDetails = AndroidNotificationDetails(
      orderStatusChannelId,
      'Order Status Updates',
      channelDescription: 'Notifications for laundry order status changes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      orderId,
      notificationInfo['title'],
      notificationInfo['body'],
      details,
      payload: 'order_$orderId',
    );

    _logger.i('Showed notification for order #$orderNumber: $status');
  }

  /// Get notification title and body based on status
  Map<String, String> _getStatusNotificationInfo(String status, String orderNumber) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'title': 'Order Received',
          'body': 'Your order #$orderNumber has been received and is pending.',
        };
      case 'washing':
        return {
          'title': 'Laundry Update',
          'body': 'Your order #$orderNumber is now being washed.',
        };
      case 'drying':
        return {
          'title': 'Laundry Update',
          'body': 'Your order #$orderNumber is now drying.',
        };
      case 'ready':
        return {
          'title': 'Ready for Pickup!',
          'body': 'Your order #$orderNumber is ready to collect.',
        };
      case 'completed':
        return {
          'title': 'Order Complete',
          'body': 'Your order #$orderNumber has been picked up. Thank you!',
        };
      default:
        return {
          'title': 'Order Update',
          'body': 'Your order #$orderNumber status: $status',
        };
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Handle notification tap when app is in foreground/background
  void _onNotificationResponse(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    onNotificationTap?.call(response.payload);
  }

  /// Handle notification tap when app is terminated (background isolate)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // This runs in a background isolate
    // We'll handle navigation when the app is launched
    debugPrint('Background notification tapped: ${response.payload}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true; // iOS handles this differently
  }
}
