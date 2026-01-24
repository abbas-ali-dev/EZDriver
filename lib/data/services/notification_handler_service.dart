import 'package:get/get.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';

class NotificationHandlerService {
  static final NotificationHandlerService _instance = NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  // Handle scheduled ride notifications for driver
  void handleScheduledRideNotification(Map<String, dynamic> payload) {
    try {
      String type = payload['type'] ?? '';
      String rideId = payload['data']?['ride_id'] ?? '';
      String screen = payload['data']?['screen'] ?? '';

      // Get current route
      String currentRoute = Get.currentRoute;

      switch (type) {
        case 'new_passenger_request':
          _handleNewPassengerRequest(rideId, screen, currentRoute);
          break;
        case 'passenger_left':
          _handlePassengerLeft(rideId, screen, currentRoute);
          break;
        case 'cash_payment_received':
          _handleCashPaymentReceived(rideId, screen, currentRoute);
          break;
        default:
          print('Unknown notification type: $type');
      }
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  void _handleNewPassengerRequest(String rideId, String screen, String currentRoute) {
    if (rideId.isEmpty) return;

    // Check if user is already on passenger requests screen for this ride
    if (currentRoute == '/passenger_requests' && _isCurrentRide(rideId)) {
      // Refresh passenger requests data
      _refreshPassengerRequests(rideId);
    } else {
      // Navigate to passenger requests screen
      // Note: You'll need to get the ride object from the controller
      // For now, we'll refresh the data instead of navigating
      _refreshScheduledRidesList();
    }
  }

  void _handlePassengerLeft(String rideId, String screen, String currentRoute) {
    if (rideId.isEmpty) return;

    // Check if user is on ride details screen for this ride
    if (currentRoute == '/scheduled_ride_detail' && _isCurrentRide(rideId)) {
      // Refresh ride details data
      _refreshRideDetails(rideId);
    } else if (currentRoute == '/scheduled_rides') {
      // Refresh scheduled rides list
      _refreshScheduledRidesList();
    } else {
      // Navigate to ride details screen
      // Note: You'll need to get the ride object from the controller
      // For now, we'll refresh the data instead of navigating
      _refreshScheduledRidesList();
    }
  }

  void _handleCashPaymentReceived(String rideId, String screen, String currentRoute) {
    if (rideId.isEmpty) return;

    // Check if user is on payment summary screen for this ride
    if (currentRoute == '/payment_summary' && _isCurrentRide(rideId)) {
      // Refresh payment summary data
      _refreshPaymentSummary(rideId);
    } else {
      // Navigate to payment summary screen
      // Note: You'll need to get the ride object from the controller
      // For now, we'll refresh the data instead of navigating
      _refreshScheduledRidesList();
    }
  }

  // Helper methods
  bool _isCurrentRide(String rideId) {
    // This would need to be implemented based on how you track current ride
    // For now, we'll assume we can get it from the controller
    try {
      // You might need to add a method to check current ride ID
      return true; // Simplified for now
    } catch (e) {
      return false;
    }
  }

  void _refreshPassengerRequests(String rideId) {
    try {
      final controller = Get.find<ScheduledRideController>();
      controller.loadPendingPassengers(rideId);
    } catch (e) {
      print('Error refreshing passenger requests: $e');
    }
  }

  void _refreshRideDetails(String rideId) {
    try {
      final controller = Get.find<ScheduledRideController>();
      // You might need to add a refresh method for ride details
      controller.loadScheduledRides(refresh: true);
    } catch (e) {
      print('Error refreshing ride details: $e');
    }
  }

  void _refreshScheduledRidesList() {
    try {
      final controller = Get.find<ScheduledRideController>();
      controller.loadScheduledRides(refresh: true);
    } catch (e) {
      print('Error refreshing scheduled rides list: $e');
    }
  }

  void _refreshPaymentSummary(String rideId) {
    try {
      final controller = Get.find<ScheduledRideController>();
      // You might need to add a refresh method for payment summary
      controller.loadScheduledRides(refresh: true);
    } catch (e) {
      print('Error refreshing payment summary: $e');
    }
  }
}
