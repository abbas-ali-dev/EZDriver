import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/my_icons.dart';
import 'package:ezdriver/core/utils/helper.dart';
import 'package:ezdriver/core/utils/marker_helper.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduledRideNavigationController extends GetxController {
  // Current ride and passenger
  ScheduledRideModel? currentRide;
  ScheduledRidePassenger? currentPassenger;
  
  // Location variables
  LatLng? driverLocation;
  LatLng? passengerLocation;
  
  // Map and navigation
  GoogleMapController? mapController;
  Set<Marker> markers = <Marker>{};
  Set<Polyline> polylines = <Polyline>{};
  
  // Navigation data
  double distance = 0.0; // in meters
  double duration = 0.0; // in seconds
  List<LatLng> routePoints = [];
  
  // Location tracking
  StreamSubscription<Position>? locationSubscription;
  Timer? updateTimer;
  
  // Custom icons
  BitmapDescriptor? driverIcon;
  BitmapDescriptor? passengerIcon;
  
  // Loading states
  bool isLoadingRoute = false;
  bool isUpdatingLocation = false;
  
  // Distance threshold for "reached" status (in meters)
  static const double reachedThreshold = 100.0;
  
  @override
  void onInit() {
    super.onInit();
    _createCustomIcons();
  }
  
  @override
  void dispose() {
    locationSubscription?.cancel();
    updateTimer?.cancel();
    super.dispose();
  }
  
  // Initialize navigation with ride and passenger data
  void initializeNavigation(ScheduledRideModel ride, ScheduledRidePassenger passenger) {
    currentRide = ride;
    currentPassenger = passenger;
    
    // Set passenger location
    if (passenger.pickupLatitude != null && passenger.pickupLongitude != null) {
      passengerLocation = LatLng(
        double.parse(passenger.pickupLatitude!),
        double.parse(passenger.pickupLongitude!),
      );
    }
    
    // Start location tracking
    _startLocationTracking();
    
    update();
  }
  
  // Create custom map icons
  Future<void> _createCustomIcons() async {
    try {
      // Load driver car icon from assets
      final Uint8List? carIconBytes = await Helper.getBytesFromAsset(
        MyIcons.carMarkerIcon,
        120, // Size for car marker
      );
      if (carIconBytes != null) {
        driverIcon = BitmapDescriptor.fromBytes(carIconBytes);
      }

      // Try to load passenger person icon from assets, fallback to programmatic creation
      try {
        final Uint8List? personIconBytes = await Helper.getBytesFromAsset(
          MyIcons.personMarkerIcon,
          100, // Size for person marker
        );
        if (personIconBytes != null) {
          passengerIcon = BitmapDescriptor.fromBytes(personIconBytes);
        }
      } catch (e) {
        // If asset doesn't exist, create programmatically
        print('Person marker asset not found, creating programmatically');
        passengerIcon = await MarkerHelper.createPersonMarker(
          color: MyColor.getPrimaryColor(),
          size: 100,
        );
      }
      
      update();
    } catch (e) {
      print('Error creating custom icons: $e');
      // Fallback to default icons
      driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      passengerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
  }
  
  // Start location tracking
  void _startLocationTracking() {
    locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((Position position) {
      _updateDriverLocation(position);
    });
    
    // Also get initial location
    _getCurrentLocation();
    
    // Start periodic updates for route calculation
    updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (driverLocation != null && passengerLocation != null) {
        _calculateRoute();
      }
    });
  }
  
  // Get current driver location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateDriverLocation(position);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }
  
  // Update driver location
  void _updateDriverLocation(Position position) {
    driverLocation = LatLng(position.latitude, position.longitude);
    _updateMarkers();
    
    // Calculate route if we have both locations
    if (passengerLocation != null) {
      _calculateRoute();
    }
    
    // Update camera position to follow driver
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(driverLocation!),
      );
    }
    
    update();
  }
  
  // Update map markers
  void _updateMarkers() {
    markers.clear();
    
    // Add driver marker
    if (driverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation!,
          icon: driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Add passenger marker
    if (passengerLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('passenger'),
          position: passengerLocation!,
          icon: passengerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '${currentPassenger?.user?.firstname ?? 'Passenger'} ${currentPassenger?.user?.lastname ?? ''}',
            snippet: 'Pickup Location',
          ),
        ),
      );
    }
    
    update();
  }
  
  // Calculate route between driver and passenger
  Future<void> _calculateRoute() async {
    if (driverLocation == null || passengerLocation == null || isLoadingRoute) {
      return;
    }
    
    isLoadingRoute = true;
    update();
    
    try {
      // For demo purposes, create a simple route calculation
      // In a real app, you'd use Google Directions API or similar
      await _calculateDirectRoute();
      
      // Update polylines
      _updatePolylines();
      
    } catch (e) {
      print('Error calculating route: $e');
    } finally {
      isLoadingRoute = false;
      update();
    }
  }
  
  // Calculate direct route (simplified)
  Future<void> _calculateDirectRoute() async {
    if (driverLocation == null || passengerLocation == null) return;
    
    // Calculate distance using Haversine formula
    distance = _calculateDistance(driverLocation!, passengerLocation!);
    
    // Estimate duration (assuming average speed of 30 km/h in city)
    duration = (distance / 1000) * 2 * 60; // 2 minutes per km
    
    // Create simple route points (straight line for demo)
    routePoints = [driverLocation!, passengerLocation!];
    
    // In a real implementation, you would call Google Directions API here
    // and get the actual route polyline points
  }
  
  // Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  // Update polylines for route
  void _updatePolylines() {
    polylines.clear();
    
    if (routePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: MyColor.primaryColor,
          width: 6,
          patterns: [], // Solid line (no dashes)
          geodesic: true, // Draw smooth curved lines
        ),
      );
    }
    
    update();
  }
  
  // Set map controller
  void setMapController(GoogleMapController controller) {
    mapController = controller;
    
    // Fit camera to show both markers
    if (driverLocation != null && passengerLocation != null) {
      _fitCameraToMarkers();
    }
  }
  
  // Fit camera to show both driver and passenger markers
  void _fitCameraToMarkers() {
    if (mapController == null || driverLocation == null || passengerLocation == null) {
      return;
    }
    
    double minLat = min(driverLocation!.latitude, passengerLocation!.latitude);
    double maxLat = max(driverLocation!.latitude, passengerLocation!.latitude);
    double minLng = min(driverLocation!.longitude, passengerLocation!.longitude);
    double maxLng = max(driverLocation!.longitude, passengerLocation!.longitude);
    
    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
  
  // Check if driver is near passenger
  bool get isDriverNearPassenger {
    if (driverLocation == null || passengerLocation == null) return false;
    return distance <= reachedThreshold;
  }
  
  // Formatted distance string
  String get formattedDistance {
    if (distance == 0) return 'Calculating...';
    
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
  
  // Formatted duration string
  String get formattedDuration {
    if (duration == 0) return 'Calculating...';
    
    int minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = (minutes / 60).floor();
      int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
  
  // Open Google Maps navigation
  Future<void> openGoogleMaps() async {
    if (passengerLocation == null) {
      Get.snackbar(
        'Error',
        'Passenger location not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    final String destinationLat = passengerLocation!.latitude.toString();
    final String destinationLng = passengerLocation!.longitude.toString();
    
    // Create Google Maps URL
    final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving';
    
    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to Apple Maps on iOS
        final String appleMapsUrl = 'http://maps.apple.com/?daddr=$destinationLat,$destinationLng&dirflg=d';
        if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(
            Uri.parse(appleMapsUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          Get.snackbar(
            'Error',
            'Could not open maps application',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      print('Error opening maps: $e');
      Get.snackbar(
        'Error',
        'Could not open maps application',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Start passenger pickup
  void startPassengerPickup() {
    if (currentRide == null || currentPassenger == null) return;
    
    final scheduledRideController = Get.find<ScheduledRideController>();
    scheduledRideController.startPassengerPickup(currentRide!.id!, currentPassenger!.id!);
    
    Get.snackbar(
      'Pickup Started',
      'Navigation to ${currentPassenger!.user?.firstname ?? 'passenger'} has started',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
  
  // Mark passenger as reached
  void markPassengerReached() {
    if (currentRide == null || currentPassenger == null) return;
    
    final scheduledRideController = Get.find<ScheduledRideController>();
    scheduledRideController.markPassengerReached(currentRide!.id!, currentPassenger!.id!);
    
    Get.snackbar(
      'Passenger Reached',
      'You have reached ${currentPassenger!.user?.firstname ?? 'passenger'}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    
    // Optionally navigate back
    Get.back();
  }
  
  // Show cancel pickup confirmation
  void showCancelPickupConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 24,
            ),
            spaceSide(Dimensions.space8),
            Text(
              'Cancel Pickup',
              style: boldDefault.copyWith(
                color: MyColor.colorBlack,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel pickup for this passenger?',
              style: regularDefault.copyWith(
                color: MyColor.colorBlack.withOpacity(0.6),
              ),
            ),
            spaceDown(Dimensions.space12),
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentPassenger?.user?.firstname ?? ''} ${currentPassenger?.user?.lastname ?? ''}',
                    style: boldDefault.copyWith(
                      color: MyColor.colorBlack,
                    ),
                  ),
                  spaceDown(Dimensions.space4),
                  Text(
                    currentPassenger?.pickupLocation ?? 'Location not specified',
                    style: regularSmall.copyWith(
                      color: MyColor.colorBlack.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Keep Pickup',
              style: regularDefault.copyWith(
                color: MyColor.colorBlack.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _cancelPassengerPickup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Text(
              'Cancel Pickup',
              style: boldDefault.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Cancel passenger pickup
  void _cancelPassengerPickup() {
    if (currentRide == null || currentPassenger == null) return;
    
    final scheduledRideController = Get.find<ScheduledRideController>();
    scheduledRideController.cancelPassengerPickup(currentRide!.id!, currentPassenger!.id!);
    
    Get.snackbar(
      'Pickup Cancelled',
      'Pickup for ${currentPassenger!.user?.firstname ?? 'passenger'} has been cancelled',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    
    // Navigate back
    Get.back();
  }
}
