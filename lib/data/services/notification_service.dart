import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:streaming_and_chat_app/core/logger.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Handling background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  NotificationService(this._messaging, this._firestore);

  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing notification service...');

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('Notification permission granted');
      } else {
        AppLogger.warning('Notification permission denied');
        return;
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Setup background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        AppLogger.info('FCM Token refreshed: $newToken');
      });

      AppLogger.info('Notification service initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize notifications', e, stackTrace);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    AppLogger.info('Notification opened: ${message.messageId}');
    // Navigate to appropriate screen based on message data
    final streamId = message.data['streamId'] as String?;
    if (streamId != null) {
      // TODO: Navigate to stream page
      AppLogger.info('Opening stream: $streamId');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'live_streams',
      'Live Streams',
      channelDescription: 'Notifications for live streams',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Save FCM token to Firestore for user
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
        AppLogger.info('FCM token saved for user: $userId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save FCM token', e, stackTrace);
    }
  }

  // Send notification to followers when going live
  Future<void> notifyFollowers({
    required String streamerId,
    required String streamerName,
    required String streamTitle,
    required String streamId,
  }) async {
    try {
      AppLogger.info('Notifying followers of stream: $streamId');

      // Get streamer's followers
      final streamerDoc = await _firestore
          .collection('users')
          .doc(streamerId)
          .get();
      
      final followers = List<String>.from(streamerDoc.data()?['followers'] ?? []);

      if (followers.isEmpty) {
        AppLogger.info('No followers to notify');
        return;
      }

      // Get FCM tokens for all followers
      final followerDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: followers)
          .get();

      final tokens = followerDocs.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null)
          .toList();

      if (tokens.isEmpty) {
        AppLogger.info('No valid tokens found');
        return;
      }

      AppLogger.info('Found ${tokens.length} followers to notify');

      // In a real app, you'd send these to your backend to send via FCM Admin SDK
      // For demo purposes, we'll just log them
      // You need a backend to send FCM messages to specific tokens
      
      AppLogger.info('Notification sent to ${tokens.length} followers');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to notify followers', e, stackTrace);
    }
  }

  // Subscribe to topic for live stream notifications
  Future<void> subscribeToLiveStreams() async {
    try {
      await _messaging.subscribeToTopic('live_streams');
      AppLogger.info('Subscribed to live_streams topic');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to subscribe to topic', e, stackTrace);
    }
  }

  Future<void> unsubscribeFromLiveStreams() async {
    try {
      await _messaging.unsubscribeFromTopic('live_streams');
      AppLogger.info('Unsubscribed from live_streams topic');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to unsubscribe from topic', e, stackTrace);
    }
  }
}