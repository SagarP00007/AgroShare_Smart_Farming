import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Set up message handlers
      _setupMessageHandlers();

      if (kDebugMode) {
        print('Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
      }
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }
  }

  // Get and save FCM token
  Future<void> _getFCMToken() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Save token to Firestore
        await _firestore.collection('users').doc(currentUserId).update({
          'fcmToken': token,
          'lastTokenUpdate': Timestamp.now(),
        });

        if (kDebugMode) {
          print('FCM Token: $token');
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) async {
        await _firestore.collection('users').doc(currentUserId).update({
          'fcmToken': token,
          'lastTokenUpdate': Timestamp.now(),
        });
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  // Set up message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    _messageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (kDebugMode) {
        print('Received foreground message: ${message.messageId}');
      }

      // Save notification to Firestore
      _saveNotificationToFirestore(message);

      // Show in-app notification or update UI
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from notification
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      if (kDebugMode) {
        print('App opened from notification: ${message.messageId}');
      }

      _handleNotificationTap(message);
    });

    // Check for initial message (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state: ${message.messageId}');
        }
        _handleNotificationTap(message);
      }
    });
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final userId =
          message.data['userId'] ?? AuthService.instance.currentUser?.uid;
      if (userId == null) return;

      final notification = AppNotification(
        id: '',
        userId: userId,
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        type: _parseNotificationType(message.data['type']),
        timestamp: DateTime.now(),
        isRead: false,
        data: message.data,
        imageUrl: message.notification?.android?.imageUrl,
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification to Firestore: $e');
      }
    }
  }

  // Parse notification type from string
  NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'newMessage':
        return NotificationType.newMessage;
      case 'equipmentRequest':
        return NotificationType.equipmentRequest;
      case 'bookingConfirmed':
        return NotificationType.bookingConfirmed;
      case 'bookingCancelled':
        return NotificationType.bookingCancelled;
      case 'paymentReceived':
        return NotificationType.paymentReceived;
      case 'equipmentAvailable':
        return NotificationType.equipmentAvailable;
      default:
        return NotificationType.system;
    }
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    // TODO: Show in-app notification banner or update UI
    // This can be handled by a notification provider or state management
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // TODO: Navigate to appropriate screen based on notification type
    final type = message.data['type'];

    switch (type) {
      case 'newMessage':
        // Navigate to chat screen
        // TODO: Navigate to chat screen with chatId from message.data['chatId']
        break;
      case 'equipmentRequest':
        // Navigate to equipment requests
        break;
      case 'bookingConfirmed':
      case 'bookingCancelled':
        // Navigate to bookings
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  // Send push notification
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) return;

      // Create notification document
      final notification = AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        data: data,
      );

      await _firestore.collection('notifications').add(notification.toMap());

      // TODO: Send via Firebase Cloud Functions or direct FCM API
      // For now, we'll save to Firestore and handle client-side

      if (kDebugMode) {
        print('Push notification sent to user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push notification: $e');
      }
    }
  }

  // Get user's notifications stream
  Stream<QuerySnapshot> getUserNotificationsStream() {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final unreadNotifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadNotifications.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return 0;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final currentUserId = AuthService.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .get();

    for (final doc in notifications.docs) {
      await doc.reference.delete();
    }
  }

  // Dispose subscriptions
  void dispose() {
    _messageSubscription?.cancel();
    _onMessageOpenedSubscription?.cancel();
  }
}
