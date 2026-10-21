import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import 'notification_service.dart';
import '../screens/notification_page.dart';
import '../screens/emergency/emergency_page.dart';

final _local = FlutterLocalNotificationsPlugin();

// ── Notification Channels based on Type ─────────────────────────────────────
const _channelAlerts = AndroidNotificationChannel(
  'alerts',
  'Emergency & Health Alerts',
  description: 'Urgent medical notifications and warning signs',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const _channelReminders = AndroidNotificationChannel(
  'reminders',
  'Pregnancy Reminders',
  description: 'Checkups, scans, and gestational milestones',
  importance: Importance.high,
  playSound: true,
);

const _channelTips = AndroidNotificationChannel(
  'tips',
  'Wellness & Nutrition Tips',
  description: 'Nutrition, sleep, and exercise recommendations',
  importance: Importance.defaultImportance,
);

const _channelGeneral = AndroidNotificationChannel(
  'general',
  'General Notifications',
  description: 'System announcements and updates',
  importance: Importance.high,
);

class PushService {
  static final _fcm = FirebaseMessaging.instance;
  static IO.Socket? _socket;

  /// Setup push notifications (both FCM and WebSocket in-app)
  static Future<void> init({
    required String jwt,
    required void Function(Map<String, dynamic> data) onTap,
    required void Function(Map<String, dynamic> n) onInApp,
  }) async {
    try {
      // 1. Request notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushService] Notification permission was denied');
        return;
      }

      // 2. Initialize FlutterLocalNotifications for banners
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _local.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final payloadData = jsonDecode(response.payload!) as Map<String, dynamic>;
              onTap(payloadData);
            } catch (e) {
              debugPrint('[PushService] Error decoding notification response payload: $e');
            }
          }
        },
      );

      // Create Android Notification Channels
      final androidPlugin = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channelAlerts);
        await androidPlugin.createNotificationChannel(_channelReminders);
        await androidPlugin.createNotificationChannel(_channelTips);
        await androidPlugin.createNotificationChannel(_channelGeneral);
      }

      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Register FCM Token with backend
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[PushService] FCM token obtained: $token');
        await _register(jwt, token);
      }
      _fcm.onTokenRefresh.listen((t) => _register(jwt, t));

      // 4. Handle FCM notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushService] Notification tapped from background: ${message.data}');
        onTap(message.data);
      });

      final initialMsg = await _fcm.getInitialMessage();
      if (initialMsg != null) {
        debugPrint('[PushService] App launched from terminated state via notification: ${initialMsg.data}');
        onTap(initialMsg.data);
      }

      // 5. Handle FCM foreground push
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushService] Foreground push arrived: ${message.messageId}');
        final n = <String, dynamic>{
          'id': message.data['notificationId'] ?? message.messageId,
          'title': message.notification?.title ?? message.data['title'],
          'body': message.notification?.body ?? message.data['body'],
          'type': message.data['type'] ?? 'reminder',
          'week': message.data['week'],
          'month': message.data['month'],
          'trimester': message.data['trimester'],
          'data': message.data,
        };
        _onNotificationArrived(notification: n, onInApp: onInApp);
      });

      // 6. Connect live WebSocket
      connectSocket(jwt, onTap, onInApp);

      // 7. Initial fetch of unread count for top navbar red badge
      NotificationService.fetchUnreadCount();
    } catch (e) {
      debugPrint('[PushService] Error during PushService.init: $e');
    }
  }

  static final Set<String> _recentlyReceivedIds = {};

  static void _onNotificationArrived({
    required Map<String, dynamic> notification,
    required void Function(Map<String, dynamic> n) onInApp,
  }) {
    final id = (notification['id'] ?? notification['notificationId'] ?? notification['title'] ?? '').toString();
    if (id.isNotEmpty) {
      if (_recentlyReceivedIds.contains(id)) return;
      _recentlyReceivedIds.add(id);
      Future.delayed(const Duration(seconds: 15), () => _recentlyReceivedIds.remove(id));
    }

    // Increment reactive unread counter for top navbar badge and sync count
    NotificationService.incrementUnread();
    NotificationService.fetchUnreadCount();

    // Trigger in-app UI callback and heads-up banner
    onInApp(notification);
    showLocalNotification(notification);
  }

  /// Connect to WebSocket server for instant in-app notification dispatch
  static void connectSocket(
    String jwt,
    void Function(Map<String, dynamic> data) onTap,
    void Function(Map<String, dynamic> n) onInApp,
  ) {
    _socket?.dispose();
    final socketUrl = ApiEndpoints.serverHost;

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': jwt})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );

      void handleIncoming(dynamic payload) {
        if (payload is Map) {
          final n = Map<String, dynamic>.from(payload);
          debugPrint('[PushService] In-app notification received via socket: ${n['title']} (type: ${n['type']})');
          _onNotificationArrived(notification: n, onInApp: onInApp);
        }
      }

      _socket!.on('notification', handleIncoming);
      _socket!.on('notification:new', handleIncoming);
      _socket!.on('notification:count_update', (_) {
        NotificationService.fetchUnreadCount();
      });

      _socket!.onConnect((_) {
        debugPrint('[PushService] WebSocket connected to $socketUrl');
      });

      _socket!.onDisconnect((_) {
        debugPrint('[PushService] WebSocket disconnected');
      });
    } catch (e) {
      debugPrint('[PushService] WebSocket connection error: $e');
    }
  }

  /// Disconnect socket when app goes to background
  static void disconnectSocket() {
    _socket?.dispose();
    _socket = null;
  }

  /// Display a local heads-up notification banner styled by notification type
  static Future<void> showLocalNotification(Map<String, dynamic> n) async {
    try {
      final notifId = (n['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch) & 0x7FFFFFFF;
      final title = (n['title'] ?? n['title_en'] ?? n['title_am'] ?? 'MomCare Notification').toString();
      final body = (n['body'] ?? n['body_en'] ?? n['body_am'] ?? '').toString();
      final type = (n['type'] ?? n['data']?['type'] ?? 'reminder').toString().toLowerCase();

      final details = _getNotificationDetails(type);
      final payloadData = n['data'] is Map ? Map<String, dynamic>.from(n['data']) : n;

      await _local.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(payloadData),
      );
    } catch (e) {
      debugPrint('[PushService] Error showing local notification: $e');
    }
  }

  /// Resolve notification details with specific sound, vibration and channel
  static NotificationDetails _getNotificationDetails(String type) {
    if (type == 'alert') {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelAlerts.id,
          _channelAlerts.name,
          channelDescription: _channelAlerts.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFDC2626), // Red badge for health alerts
          enableVibration: true,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else if (type == 'tip') {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelTips.id,
          _channelTips.name,
          channelDescription: _channelTips.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2563EB), // Blue badge for wellness tips
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    } else {
      // Reminder / Default
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelReminders.id,
          _channelReminders.name,
          channelDescription: _channelReminders.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF61183E), // Brand maroon for reminders
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
    }
  }

  /// Smart navigation router triggered when user taps any notification
  static void handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    debugPrint('[PushService] Navigating directly from notification data: $data');
    final screen = (data['screen'] ?? '').toString().toLowerCase();
    final type = (data['type'] ?? '').toString().toLowerCase();

    // 1. If notification is specifically an emergency / urgent alert
    if (type == 'alert' || screen == 'emergency') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const EmergencyPage(),
        ),
      );
      return;
    }

    // 2. Default: Open Notification page directly so user views their notification
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationPage(),
      ),
    );
  }

  /// Register device FCM token with backend
  static Future<void> _register(String jwt, String token) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationDevices}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );
      debugPrint('[PushService] FCM device token registered on server: ${response.statusCode}');
    } catch (e) {
      debugPrint('[PushService] Device registration failed: $e');
    }
  }

  /// Clean up token and disconnect on user logout
  static Future<void> logout(String jwt) async {
    try {
      final token = await _fcm.getToken();
      disconnectSocket();
      if (token != null) {
        final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.notificationDevices}');
        await http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode({'token': token}),
        );
      }
      await _fcm.deleteToken();
      debugPrint('[PushService] Successfully logged out and unregistered push device');
    } catch (e) {
      debugPrint('[PushService] Logout cleanup error: $e');
    }
  }
}