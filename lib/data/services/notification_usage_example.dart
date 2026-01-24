// Example usage of the notification system for driver app

import 'package:ezdriver/data/services/firebase_messaging_service.dart';
import 'package:ezdriver/data/services/notification_handler_service.dart';

class NotificationUsageExample {
  
  // Initialize the notification system in your main.dart or app initialization
  static Future<void> initializeNotifications() async {
    // Initialize Firebase messaging
    await FirebaseMessagingService().initialize();
    
    // Get FCM token and send to your backend
    String? token = await FirebaseMessagingService().getToken();
    if (token != null) {
      // Send token to your backend to associate with user
      await _sendTokenToBackend(token);
    }
    
    // Subscribe to driver-specific topics
    await FirebaseMessagingService().subscribeToTopic('drivers');
    await FirebaseMessagingService().subscribeToTopic('scheduled_rides');
  }
  
  // Example of handling a notification payload
  static void handleNotificationExample() {
    // Example notification payload from your backend
    Map<String, dynamic> notificationPayload = {
      "type": "new_passenger_request",
      "title": "New Passenger Request",
      "body": "John Doe wants to join your ride",
      "recipient_id": "driver_123",
      "data": {
        "ride_id": "ride_456",
        "screen": "passenger_requests"
      }
    };
    
    // Handle the notification
    NotificationHandlerService().handleScheduledRideNotification(notificationPayload);
  }
  
  // Send FCM token to your backend
  static Future<void> _sendTokenToBackend(String token) async {
    // Make API call to your backend to store the FCM token
    // This allows your backend to send notifications to this device
    print('Sending FCM token to backend: $token');
    
    // Example API call:
    // await apiService.updateFCMToken(token);
  }
  
  // Example of different notification types
  static void notificationExamples() {
    // Passenger request notification
    Map<String, dynamic> passengerRequest = {
      "type": "new_passenger_request",
      "title": "New Passenger Request",
      "body": "Sarah wants to join your ride",
      "recipient_id": "driver_123",
      "data": {
        "ride_id": "ride_789",
        "screen": "passenger_requests"
      }
    };
    
    // Passenger left notification
    Map<String, dynamic> passengerLeft = {
      "type": "passenger_left",
      "title": "Passenger Left Ride",
      "body": "Mike has left your ride",
      "recipient_id": "driver_123",
      "data": {
        "ride_id": "ride_789",
        "screen": "ride_details"
      }
    };
    
    // Cash payment notification
    Map<String, dynamic> cashPayment = {
      "type": "cash_payment_received",
      "title": "Cash Payment Received",
      "body": "Cash payment of \$25 received from passenger",
      "recipient_id": "driver_123",
      "data": {
        "ride_id": "ride_789",
        "screen": "payment_summary"
      }
    };
    
    // Handle each notification
    NotificationHandlerService().handleScheduledRideNotification(passengerRequest);
    NotificationHandlerService().handleScheduledRideNotification(passengerLeft);
    NotificationHandlerService().handleScheduledRideNotification(cashPayment);
  }
}

