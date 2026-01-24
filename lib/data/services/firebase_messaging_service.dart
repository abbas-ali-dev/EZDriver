import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ezdriver/data/services/notification_handler_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationHandlerService _notificationHandler = NotificationHandlerService();

  // Initialize Firebase messaging
  Future<void> initialize() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else {
      print('User declined or has not accepted permission for notifications');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    _handleInitialMessage();
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    print('Message data: ${message.data}');
    
    // Handle the notification data
    if (message.data.containsKey('type')) {
      // You might want to store this for when the app is opened
      // or handle it differently for background messages
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');
    
    // Show in-app notification or handle directly
    if (message.data.containsKey('type')) {
      _notificationHandler.handleScheduledRideNotification(message.data);
    }
  }

  // Handle notification tap when app is in background
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Message data: ${message.data}');
    
    // Handle navigation based on notification data
    if (message.data.containsKey('type')) {
      _notificationHandler.handleScheduledRideNotification(message.data);
    }
  }

  // Handle notification tap when app is terminated
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('App opened from terminated state via notification');
      print('Message data: ${initialMessage.data}');
      
      // Handle navigation based on notification data
      if (initialMessage.data.containsKey('type')) {
        _notificationHandler.handleScheduledRideNotification(initialMessage.data);
      }
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}

