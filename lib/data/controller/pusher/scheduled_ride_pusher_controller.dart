import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ezdriver/core/helper/shared_preference_helper.dart';
import 'package:ezdriver/core/helper/string_format_helper.dart';
import 'package:ezdriver/core/utils/url_container.dart';
import 'package:ezdriver/core/utils/util.dart';
import 'package:ezdriver/data/model/general_setting/general_setting_response_model.dart';
import 'package:ezdriver/data/services/api_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ScheduledRidePusherController extends GetxController {
  final ApiClient apiClient;

  ScheduledRidePusherController({required this.apiClient});

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  PusherChannel? channel;

  bool isPusherLoading = false;
  String appKey = '';
  String cluster = '';
  String token = '';
  String driverId = '';
  String scheduledRideId = '';

  Timer? _locationTimer;
  Position? _lastPosition;

  PusherConfig pusherConfig = PusherConfig();

  void initializePusher({required String rideId}) async {
    scheduledRideId = rideId;
    driverId = apiClient.sharedPreferences
            .getString(SharedPreferenceHelper.userIdKey) ?? '-1';

    isPusherLoading = true;
    pusherConfig = apiClient.getPushConfig();
    appKey = pusherConfig.appKey ?? '';
    cluster = pusherConfig.cluster ?? '';
    token = apiClient.sharedPreferences
            .getString(SharedPreferenceHelper.accessTokenKey) ?? '';
    update();

    printX('Scheduled Ride Pusher - Driver ID: $driverId');
    printX('Scheduled Ride Pusher - Ride ID: $scheduledRideId');
    printX('Scheduled Ride Pusher - App Key: $appKey');
    printX('Scheduled Ride Pusher - Cluster: $cluster');

    await configure("private-scheduled-ride-$scheduledRideId");

    isPusherLoading = false;
    update();
  }

  Future<void> configure(String channelName) async {
    try {
      await pusher.init(
        apiKey: appKey,
        cluster: cluster,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onConnectionStateChange: onConnectionStateChange,
        onAuthorizer: onAuthorizer,
      );

      channel = await pusher.subscribe(channelName: channelName);
      await pusher.connect();

      printX('Connected to Pusher channel: $channelName');

    } catch (e) {
      printX('Error connecting to Pusher: $e');
    }
  }

  Future<Map<String, dynamic>?> onAuthorizer(
      String channelName, String socketId, options) async {
    try {
      String authUrl =
          "${UrlContainer.baseUrl}${UrlContainer.pusherAuthenticate}$socketId/$channelName";
      printX("Authorizing: $authUrl");

      http.Response result = await http.post(
        Uri.parse(authUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          "dev-token":
              "\$2y\$12\$mEVBW3QASB5HMBv8igls3ejh6zw2A0Xb480HWAmYq6BY9xEifyBjG",
        },
      );

      if (result.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(result.body);
        printX('Authorization successful');
        return json;
      } else {
        printX('Authorization failed: ${result.statusCode}');
        return null;
      }
    } catch (e) {
      printX('Authorization error: $e');
      return null;
    }
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    printX("Connection state: $previousState -> $currentState");
  }

  void onEvent(PusherEvent event) {
    printX('Scheduled Ride Event: ${event.eventName}');
    // Handle incoming events if needed
  }

  void onError(String message, int? code, dynamic e) {
    printX("Pusher Error: $message");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    printX("Subscribed to: $channelName");
    // Start broadcasting location once connected
    startLocationBroadcasting();
  }

  void onSubscriptionError(String message, dynamic e) {
    printX("Subscription Error: $message");
  }

  /// Start broadcasting driver's location every 5 seconds
  void startLocationBroadcasting() {
    printX('🚀 Starting location broadcasting for scheduled ride');
    printX('📍 Scheduled Ride ID: $scheduledRideId');
    printX('👤 Driver ID: $driverId');

    // Cancel any existing timer
    _locationTimer?.cancel();

    // Broadcast location every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      printX('⏰ Timer triggered - Broadcasting location (every 5 seconds)');
      broadcastCurrentLocation();
    });

    // Immediately broadcast current location
    printX('📡 Sending initial location broadcast');
    broadcastCurrentLocation();
  }

  /// Broadcast current driver location to riders
  Future<void> broadcastCurrentLocation() async {
    try {
      // Get current location
      Position position = await MyUtils.getCurrentLocation();

      // Check if location has changed significantly (more than 10 meters)
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < 10) {
          // Location hasn't changed much, skip broadcasting
          printX('📍 Location unchanged (moved only ${distance.toStringAsFixed(2)}m < 10m threshold) - Skipping broadcast');
          return;
        } else {
          printX('📍 Location changed by ${distance.toStringAsFixed(2)}m - Broadcasting update');
        }
      }

      _lastPosition = position;

      printX('📍 Location update: Lat ${position.latitude}, Lng ${position.longitude}');
      printX('🚗 Speed: ${position.speed} m/s, Heading: ${position.heading}°, Accuracy: ${position.accuracy}m');

      // Since client events are disabled in Pusher, only send through API
      // The backend should then broadcast to Pusher
      printX('📤 Sending location to API endpoint...');
      await sendLocationToAPI(position);

      // Try client event - it might work if enabled in Pusher dashboard
      if (channel != null) {
        try {
          Map<String, dynamic> locationData = {
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
            'driver_latitude': position.latitude.toString(),
            'driver_longitude': position.longitude.toString(),
            'driver_id': driverId,
            'scheduled_ride_id': scheduledRideId,
            'timestamp': DateTime.now().toIso8601String(),
            'speed': position.speed,
            'heading': position.heading,
            'accuracy': position.accuracy,
          };

          // Only use client- prefixed event (required by Pusher for client events)
          try {
            channel!.trigger(
              PusherEvent(
                channelName: "private-scheduled-ride-$scheduledRideId",
                eventName: 'client-driver_location',
                data: jsonEncode(locationData),
              ),
            );
            printX('📡 Pusher client event broadcast: client-driver_location');
          } catch (e) {
            printX('⚠️ Failed to send Pusher event: $e');
          }
        } catch (e) {
          printX('❌ Pusher client event error: $e');
        }
      }

    } catch (e) {
      printX("Error broadcasting location: $e");
    }
  }

  /// Send driver location to backend API (fallback mechanism)
  Future<void> sendLocationToAPI(Position position) async {
    try {
      // Use the backend-provided endpoint for scheduled ride location updates
      String url = "${UrlContainer.baseUrl}driver/scheduled-rides/live-location/$scheduledRideId";

      // Use JSON format (matching Postman exactly)
      String jsonBody = '{"latitude":${position.latitude},"longitude":${position.longitude}}';

      printX('📤 ========== FULL REQUEST DEBUG ==========');
      printX('📤 URL: $url');
      printX('📤 Method: POST');
      printX('📤 Format: JSON');
      printX('📤 Headers:');
      printX('   Accept: application/json');
      printX('   Content-Type: application/json');
      printX('   Authorization: Bearer $token');
      printX('   dev-token: \$2y\$12\$mEVBW3QASB5HMBv8igls3ejh6zw2A0Xb480HWAmYq6BY9xEifyBjG');
      printX('📤 Body: $jsonBody');
      printX('📤 =========================================');

      http.Response response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          "dev-token": "\$2y\$12\$mEVBW3QASB5HMBv8igls3ejh6zw2A0Xb480HWAmYq6BY9xEifyBjG",
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        printX('✅ Location sent to API successfully');
        printX('📍 Location sent: Lat ${position.latitude}, Lng ${position.longitude}');
        printX('📍 Endpoint: /driver/scheduled-rides/live-location/$scheduledRideId');

        // Log the API response
        Map<String, dynamic> responseData = jsonDecode(response.body);
        printX('📡 API Response: $responseData');
        printX('🚗 Driver ID: $driverId, Scheduled Ride ID: $scheduledRideId');

        // The backend should broadcast this location to Pusher channel: private-scheduled-ride-$scheduledRideId
        printX('✅ Backend should now broadcast to Pusher channel: private-scheduled-ride-$scheduledRideId');
      } else {
        printX('❌ Failed to send location to API: ${response.statusCode}');
        printX('❌ Response body: ${response.body}');
        printX('📍 Failed endpoint: /driver/scheduled-rides/live-location/$scheduledRideId');
        printX('🔑 Full Token: $token');
        printX('👤 Driver ID: $driverId');

        if (response.statusCode == 404) {
          printX('⚠️ Endpoint not found - Backend needs to implement this endpoint');
        } else if (response.statusCode == 401) {
          printX('⚠️ Authentication failed - Check token');
        } else if (response.statusCode == 400) {
          printX('⚠️ Bad request - Check data format');
        } else if (response.statusCode == 500) {
          printX('⚠️ Server error - Check if driver owns this ride or backend logs');
        }
      }
    } catch (e) {
      printX('Error sending location to API: $e');
    }
  }

  /// Stop broadcasting location
  void stopLocationBroadcasting() {
    printX('Stopping location broadcasting');
    _locationTimer?.cancel();
    _locationTimer = null;
    _lastPosition = null;
  }

  /// Clean up and disconnect
  void clearData() {
    stopLocationBroadcasting();
    closePusher();
  }

  void closePusher() async {
    if (scheduledRideId.isNotEmpty) {
      await pusher.unsubscribe(channelName: "private-scheduled-ride-$scheduledRideId");
      await pusher.disconnect();
      printX('Disconnected from scheduled ride Pusher channel');
    }
  }
  @override
  void onClose() {
    clearData();
    super.onClose();
  }
}