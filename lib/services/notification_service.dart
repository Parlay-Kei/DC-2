import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Service for handling push notifications via OneSignal
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final _client = SupabaseConfig.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _playerId;
  bool _initialized = false;

  // Stream controllers for notification events
  final _notificationOpenedController =
      StreamController<OSNotificationClickEvent>.broadcast();
  final _notificationReceivedController =
      StreamController<OSNotificationWillDisplayEvent>.broadcast();

  Stream<OSNotificationClickEvent> get onNotificationOpened =>
      _notificationOpenedController.stream;
  Stream<OSNotificationWillDisplayEvent> get onNotificationReceived =>
      _notificationReceivedController.stream;

  /// Initialize notifications (OneSignal + local)
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize OneSignal if configured
      if (AppConfig.isOneSignalConfigured) {
        await _initializeOneSignal();
        Logger.info(
            'NotificationService: OneSignal + Local notifications ready');
      } else {
        Logger.info('NotificationService: Local notifications only');
      }
    } catch (e) {
      Logger.error('NotificationService initialization failed', e);
    }
  }

  /// OneSignal initialization
  Future<void> _initializeOneSignal() async {
    try {
      // Set log level based on debug mode
      OneSignal.Debug.setLogLevel(
        AppConfig.debugMode ? OSLogLevel.verbose : OSLogLevel.none,
      );

      // Initialize with App ID from config
      OneSignal.initialize(AppConfig.oneSignalAppId);

      // Request permission (shows prompt on iOS)
      OneSignal.Notifications.requestPermission(true);

      // Setup notification handlers
      _setupNotificationHandlers();

      // Get player ID for device registration
      _playerId = OneSignal.User.pushSubscription.id;
      if (_playerId != null) {
        await registerDeviceToken(_playerId!);
      }

      // Listen for subscription changes
      OneSignal.User.pushSubscription.addObserver((state) {
        final newId = state.current.id;
        if (newId != null && newId != _playerId) {
          _playerId = newId;
          registerDeviceToken(newId);
        }
      });

      Logger.debug('OneSignal initialized');
    } catch (e) {
      Logger.error('OneSignal initialization failed', e);
    }
  }

  void _setupNotificationHandlers() {
    // Handle notification opened (user tapped)
    OneSignal.Notifications.addClickListener((event) {
      Logger.debug('Notification clicked');
      _notificationOpenedController.add(event);
      _handleNotificationClick(event);
    });

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      Logger.debug('Notification received');
      _notificationReceivedController.add(event);

      // Show the notification
      event.preventDefault();
      _showLocalNotification(
        title: event.notification.title ?? 'Direct Cuts',
        body: event.notification.body ?? '',
        data: event.notification.additionalData,
      );
      event.notification.display();
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        Logger.debug('Local notification tapped');
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'direct_cuts_channel',
        'Direct Cuts Notifications',
        description: 'Notifications for bookings, messages, and updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Register device token with backend
  Future<bool> registerDeviceToken(String token) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      _playerId = token;

      await _client.from('user_devices').upsert(
        {
          'user_id': userId,
          'device_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, device_token',
      );

      // Also set external user ID in OneSignal for targeting
      OneSignal.login(userId);

      Logger.debug('Device token registered successfully');
      return true;
    } catch (e) {
      Logger.error('Device token registration failed', e);
      return false;
    }
  }

  /// Unregister device token (on logout)
  Future<bool> unregisterDeviceToken() async {
    if (_playerId == null) return true;

    try {
      await _client
          .from('user_devices')
          .update({'is_active': false}).eq('device_token', _playerId!);

      // Logout from OneSignal
      OneSignal.logout();

      _playerId = null;
      return true;
    } catch (e) {
      Logger.error('Device token unregistration failed', e);
      return false;
    }
  }

  /// Set user tags for segmentation
  Future<void> setUserTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
    } catch (e) {
      Logger.error('Failed to set user tags', e);
    }
  }

  /// Remove user tags
  Future<void> removeUserTags(List<String> keys) async {
    try {
      OneSignal.User.removeTags(keys);
    } catch (e) {
      Logger.error('Failed to remove user tags', e);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'direct_cuts_channel',
      'Direct Cuts Notifications',
      channelDescription: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data?.toString(),
    );
  }

  /// Show local notification (public method)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(title: title, body: body, data: data);
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'direct_cuts_channel',
      'Direct Cuts Notifications',
      channelDescription: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: data?.toString(),
    );
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Handle notification click
  void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData;
    if (data == null) return;

    final type = data['type'] as String?;

    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        _handleBookingNotification(data);
        break;
      case 'new_message':
        _handleMessageNotification(data);
        break;
      case 'new_review':
        _handleReviewNotification(data);
        break;
      default:
        Logger.warning('Unknown notification type received');
    }
  }

  void _handleBookingNotification(Map<String, dynamic> data) {
    Logger.debug('Navigating to booking');
    // Navigation would be handled by the app's router
  }

  void _handleMessageNotification(Map<String, dynamic> data) {
    Logger.debug('Navigating to conversation');
  }

  void _handleReviewNotification(Map<String, dynamic> data) {
    Logger.debug('Navigating to review');
  }

  /// Get pending notifications from server
  Future<List<AppNotification>> getPendingNotifications() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
    } catch (e) {
      Logger.error('Failed to get notifications', e);
      return [];
    }
  }

  /// Get all notifications (read and unread)
  Future<List<AppNotification>> getAllNotifications({int limit = 50}) async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((n) => AppNotification.fromJson(n))
          .toList();
    } catch (e) {
      Logger.error('Failed to get all notifications', e);
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
      return true;
    } catch (e) {
      Logger.error('Failed to mark notification as read', e);
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return false;

    try {
      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      Logger.error('Failed to mark all notifications as read', e);
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      Logger.error('Failed to delete notification', e);
      return false;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationOpenedController.close();
    _notificationReceivedController.close();
  }
}

/// App notification model
class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}';
  }

  String get icon {
    switch (type) {
      case 'booking_confirmed':
        return '✅';
      case 'booking_cancelled':
        return '❌';
      case 'booking_reminder':
        return '⏰';
      case 'new_message':
        return '💬';
      case 'new_review':
        return '⭐';
      case 'payment_received':
        return '💰';
      case 'promotion':
        return '🎉';
      default:
        return '🔔';
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
