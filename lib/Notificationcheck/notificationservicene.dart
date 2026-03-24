import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:pickcab_partner/splash_screen.dart';

class NotificationServiceNew {
  static final NotificationServiceNew _instance =
      NotificationServiceNew._internal();
  factory NotificationServiceNew() => _instance;
  NotificationServiceNew._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  void handleInitialMessage(RemoteMessage message) {
    Future.delayed(const Duration(milliseconds: 10), () {
      _navigateToBookingDetails(message.data);
    });
  }

  // Initialize notification service
  Future<void> init() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initLocalNotifications();

    // Get FCM token
    await _getToken();

    // Setup message handlers
    _setupMessageHandlers();
  }

  // Request permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not granted permission');
    }
  }

  // Initialize local notifications
  Future<void> _initLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pickcab_high_priority',
      'High Priority Notifications',
      description: 'This channel is used for important ride notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS initialization
    DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  // iOS local notification handler
  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    _handleNotificationTap(payload);
  }

  // Get FCM token
  Future<void> _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('Error getting token: $e');
    }
  }

  // Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app from background: ${message.messageId}');

      _navigateToBookingDetails(message.data);
    });

    // Handle messages when app is terminated
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
            'Message opened app from terminated state: ${message.messageId}');

        // Use WidgetsBinding to ensure navigation happens after app is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToBookingDetails(message.data);
        });
      }
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    _showLocalNotification(message);

    // Print payload data
    _printPayloadData(message.data);
  }

  // Print payload data
  void _printPayloadData(Map<String, dynamic> data) {
    debugPrint('===== Notification Payload =====');
    data.forEach((key, value) {
      debugPrint('$key: $value');
    });
    debugPrint('===============================');
  }

  // Navigate to booking details screen
  void _navigateToBookingDetails(Map<String, dynamic> data) {
    // Print payload data
    _printPayloadData(data);

    String bookingId = data['booking_id']?.toString() ?? '';
    String type = data['type']?.toString() ?? '';

    debugPrint('Navigating with bookingId: $bookingId, type: $type');

    // Use GetX navigation with proper error handling
    try {
      // Check if Get is ready
      if (Get.context != null) {
        Get.off(() => SplashScreen(
              bookingId: bookingId,
              bookingType: type,
            ));
      } else {
        // If Get context is not ready, use delayed navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.off(() => SplashScreen(
                bookingId: bookingId,
                bookingType: type,
              ));
        });
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback - try again after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        try {
          Get.off(() => SplashScreen(
                bookingId: bookingId,
                bookingType: type,
              ));
        } catch (e) {
          debugPrint('Second navigation attempt failed: $e');
        }
      });
    }
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Extract data from message
    Map<String, dynamic> data = message.data;

    // Prepare payload
    String payload = jsonEncode(data);

    // Android notification details with correct channel ID
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pickcab_high_priority',
      'High Priority Notifications',
      channelDescription: 'Channel for important ride notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      colorized: true,
      fullScreenIntent: true,
      showWhen: true,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      int.parse(data['booking_id'] ?? DateTime.now().millisecond.toString()),
      message.notification?.title ?? data['title'] ?? 'New Ride Available',
      message.notification?.body ?? data['body'] ?? 'New ride notification',
      platformDetails,
      payload: payload,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(String? payload) {
    debugPrint('Notification tapped with payload: $payload');

    if (payload != null) {
      try {
        // Parse and print payload data
        Map<String, dynamic> data = jsonDecode(payload);
        _navigateToBookingDetails(data);
      } catch (e) {
        debugPrint('Error parsing payload: $e');
        debugPrint('Raw payload: $payload');
      }
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
}
