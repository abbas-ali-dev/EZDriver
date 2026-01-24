import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/route/route.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/my_icons.dart';
import 'package:ezdriver/core/utils/helper.dart';
import 'package:ezdriver/core/utils/marker_helper.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/controller/pusher/scheduled_ride_pusher_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/data/services/api_service.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/bottom_sheets/passenger_bottom_sheet.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/payment_summary_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/create_scheduled_ride_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/passenger_requests_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/scheduled_ride_navigation_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ezdriver/environment.dart';
import 'dart:convert';
import 'dart:async';

class ScheduledRideDetailScreen extends StatefulWidget {
  final ScheduledRideModel ride;
  final bool isFromDashboard; // New parameter to indicate navigation source
  
  const ScheduledRideDetailScreen({
    super.key, 
    required this.ride,
    this.isFromDashboard = false, // Default to false for backward compatibility
  });

  @override
  State<ScheduledRideDetailScreen> createState() => _ScheduledRideDetailScreenState();
}

class _ScheduledRideDetailScreenState extends State<ScheduledRideDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Map related variables
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  final List<LatLng> _passengerLocations = [];
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _passengerIcon;
  
  // Location broadcasting variables
  ScheduledRidePusherController? _pusherController;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationTimer;
  bool _isLocationBroadcasting = false;
  String? _driverId;
  LatLng? _lastBroadcastedLocation;

  @override
  void initState() {
    super.initState();
    // Ensure controller is instantiated
    Get.find<ScheduledRideController>();

    // Debug: Print ride details to understand the data
    print('=== RIDE DETAILS DEBUG ===');
    print('Ride ID: ${widget.ride.id}');
    print('Ride Driver ID: ${widget.ride.driverId}');
    print('Ride Status: ${widget.ride.status}');
    print('Scheduled DateTime: ${widget.ride.scheduledDateTime}');
    print('Pickup Location: ${widget.ride.pickupLocation}');
    print('Pickup Latitude: ${widget.ride.pickupLatitude}');
    print('Pickup Longitude: ${widget.ride.pickupLongitude}');
    print('Destination: ${widget.ride.destination}');
    print('Destination Latitude: ${widget.ride.destinationLatitude}');
    print('Destination Longitude: ${widget.ride.destinationLongitude}');
    print('Is From Dashboard: ${widget.isFromDashboard}');
    print('========================');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();

    // Initialize map data
    _initializeMapData();

    // Create custom car icon
    _createCarIcon();

    // Get driver location immediately
    _getCurrentLocation();

    // Initialize location broadcasting only if ride is started
    if (_isRideStarted(widget.ride.status ?? '')) {
      _initializeLocationBroadcasting();
    }

    // Load pending passengers and refresh ride data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<ScheduledRideController>();

      // Load both pending passengers AND full ride details with all passengers
      await Future.wait([
        controller.loadPendingPassengers(widget.ride.id!),
        controller.loadScheduledRideById(widget.ride.id!),
      ]);

      // Refresh map markers with updated passenger data
      _updateMarkers();

      // Auto-suggest nearest passenger only if ride is started
      if (_isRideStarted(widget.ride.status ?? '')) {
        _suggestNearestPassenger();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopLocationBroadcasting();
    super.dispose();
  }

  // Create custom car icon for driver marker
  Future<void> _createCarIcon() async {
    try {
      // Load car icon from assets
      final Uint8List? carIconBytes = await Helper.getBytesFromAsset(
        MyIcons.carMarkerIcon,
        120, // Size for car marker
      );
      if (carIconBytes != null) {
        _carIcon = BitmapDescriptor.fromBytes(carIconBytes);
      }
      
      // Load passenger person icon from assets
      try {
        final Uint8List? personIconBytes = await Helper.getBytesFromAsset(
          MyIcons.personMarkerIcon,
          100, // Size for person marker
        );
        if (personIconBytes != null) {
          _passengerIcon = BitmapDescriptor.fromBytes(personIconBytes);
        }
      } catch (e) {
        // If asset doesn't exist, create programmatically
        print('Person marker asset not found, creating programmatically');
        _passengerIcon = await MarkerHelper.createPersonMarker(
          color: MyColor.getPrimaryColor(),
          size: 100,
        );
      }
    } catch (e) {
      print('Error loading car icon: $e');
      // Fallback to default marker
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _passengerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // Initialize location broadcasting
  void _initializeLocationBroadcasting() {
    print('Initializing location broadcasting for scheduled ride ${widget.ride.id}');

    // Get current driver ID from shared preferences
    final apiClient = Get.find<ApiClient>();
    final currentDriverId = apiClient.sharedPreferences.getString('user_id') ?? '';
    final rideDriverId = widget.ride.driverId ?? '';

    print('=== DRIVER OWNERSHIP CHECK ===');
    print('Current Driver ID: $currentDriverId');
    print('Ride Driver ID: $rideDriverId');
    print('Ride ID: ${widget.ride.id}');

    // Validate driver ownership
    if (currentDriverId.isNotEmpty && rideDriverId.isNotEmpty && currentDriverId != rideDriverId) {
      print('⚠️ WARNING: Current driver ($currentDriverId) does not own this ride (owned by driver $rideDriverId)');
      print('⚠️ Location broadcasting may fail due to authorization issues');
    } else {
      print('✅ Driver ownership verified');
    }
    print('==============================');

    // Initialize Pusher controller for this scheduled ride
    _pusherController = Get.put(
      ScheduledRidePusherController(apiClient: Get.find<ApiClient>()),
      tag: 'scheduled_ride_${widget.ride.id}',
    );

    // Initialize Pusher and start broadcasting
    _pusherController!.initializePusher(rideId: widget.ride.id ?? '');

    // The Pusher controller will handle location broadcasting automatically
    _isLocationBroadcasting = true;

    print('Location broadcasting initialized for ride ${widget.ride.id}');
  }

  // Stop location broadcasting
  void _stopLocationBroadcasting() {
    print('Stopping location broadcasting for ride ${widget.ride.id}');

    _isLocationBroadcasting = false;
    _locationSubscription?.cancel();
    _locationTimer?.cancel();

    // Clean up Pusher controller
    if (_pusherController != null) {
      _pusherController!.clearData();
      Get.delete<ScheduledRidePusherController>(
        tag: 'scheduled_ride_${widget.ride.id}',
      );
    }

    print('Location broadcasting stopped');
  }

  // Initialize map data
  void _initializeMapData() async {
    // Set pickup location
    if (widget.ride.pickupLatitude != null &&
        widget.ride.pickupLongitude != null &&
        widget.ride.pickupLatitude!.isNotEmpty &&
        widget.ride.pickupLongitude!.isNotEmpty) {
      try {
        double lat = double.parse(widget.ride.pickupLatitude!);
        double lng = double.parse(widget.ride.pickupLongitude!);
        _pickupLocation = LatLng(lat, lng);
        print('Pickup location initialized from coordinates: $lat, $lng');
      } catch (e) {
        print('Error parsing pickup location: $e');
        print('Pickup Lat: ${widget.ride.pickupLatitude}, Lng: ${widget.ride.pickupLongitude}');
      }
    } else {
      print('Pickup coordinates missing, attempting geocoding from address...');
      // Try to geocode from address
      if (widget.ride.pickupLocation != null && widget.ride.pickupLocation!.isNotEmpty) {
        await _geocodeAddress(widget.ride.pickupLocation!, isPickup: true);
      }
    }

    // Set destination location
    if (widget.ride.destinationLatitude != null &&
        widget.ride.destinationLongitude != null &&
        widget.ride.destinationLatitude!.isNotEmpty &&
        widget.ride.destinationLongitude!.isNotEmpty) {
      try {
        double lat = double.parse(widget.ride.destinationLatitude!);
        double lng = double.parse(widget.ride.destinationLongitude!);
        _destinationLocation = LatLng(lat, lng);
        print('Destination location initialized from coordinates: $lat, $lng');
      } catch (e) {
        print('Error parsing destination location: $e');
        print('Destination Lat: ${widget.ride.destinationLatitude}, Lng: ${widget.ride.destinationLongitude}');
      }
    } else {
      print('Destination coordinates missing, attempting geocoding from address...');
      // Try to geocode from address
      if (widget.ride.destination != null && widget.ride.destination!.isNotEmpty) {
        await _geocodeAddress(widget.ride.destination!, isPickup: false);
      }
    }

    // Set passenger locations
    if (widget.ride.passengers != null) {
      for (var passenger in widget.ride.passengers!) {
        if (passenger.pickupLatitude != null &&
            passenger.pickupLongitude != null &&
            passenger.pickupLatitude!.isNotEmpty &&
            passenger.pickupLongitude!.isNotEmpty) {
          try {
            double lat = double.parse(passenger.pickupLatitude!);
            double lng = double.parse(passenger.pickupLongitude!);
            _passengerLocations.add(LatLng(lat, lng));
          } catch (e) {
            print('Error parsing passenger location: $e');
          }
        }
      }
    }

    _updateMarkers();
  }

  // Geocode address to get coordinates
  Future<void> _geocodeAddress(String address, {required bool isPickup}) async {
    try {
      print('Attempting to geocode address: $address');
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        if (isPickup) {
          _pickupLocation = LatLng(lat, lng);
          print('Pickup location geocoded successfully: $lat, $lng');
        } else {
          _destinationLocation = LatLng(lat, lng);
          print('Destination location geocoded successfully: $lat, $lng');
        }

        setState(() {
          _updateMarkers();
        });
      } else {
        print('No coordinates found for address: $address');
      }
    } catch (e) {
      print('Error geocoding address "$address": $e');
    }
  }

  // Get current driver location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMarkers();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Get current passengers list from controller or widget
  List<ScheduledRidePassenger> _getCurrentPassengers() {
    try {
      final controller = Get.find<ScheduledRideController>();

      // First, try to get the updated ride from controller's currentScheduledRide
      if (controller.currentScheduledRide != null &&
          controller.currentScheduledRide!.id == widget.ride.id) {
        print('Using currentScheduledRide passengers: ${controller.currentScheduledRide!.passengers?.length ?? 0}');
        final passengers = controller.currentScheduledRide!.passengers ?? [];
        for (var p in passengers) {
          print('  Passenger ${p.user?.firstname}: status=${p.status}, lat=${p.pickupLatitude}, lng=${p.pickupLongitude}');
        }
        return passengers;
      }

      // Second, try to find the ride in scheduledRides list
      final updatedRide = controller.scheduledRides.firstWhereOrNull(
        (ride) => ride.id == widget.ride.id
      );
      if (updatedRide != null && updatedRide.passengers != null) {
        print('Using scheduledRides passengers: ${updatedRide.passengers!.length}');
        for (var p in updatedRide.passengers!) {
          print('  Passenger ${p.user?.firstname}: status=${p.status}, lat=${p.pickupLatitude}, lng=${p.pickupLongitude}');
        }
        return updatedRide.passengers!;
      }

      // Fallback to widget.ride.passengers
      print('Using widget.ride.passengers: ${widget.ride.passengers?.length ?? 0}');
      final passengers = widget.ride.passengers ?? [];
      for (var p in passengers) {
        print('  Passenger ${p.user?.firstname}: status=${p.status}, lat=${p.pickupLatitude}, lng=${p.pickupLongitude}');
      }
      return passengers;
    } catch (e) {
      print('Error getting current passengers: $e');
      return widget.ride.passengers ?? [];
    }
  }

  // Update map markers
  void _updateMarkers() {
    _markers.clear();

    // Driver location marker (show if we have driver location)
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Pickup location marker
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Pickup Location',
            snippet: 'Tap to open in Google Maps',
          ),
          onTap: () => _openGoogleMapsToLocation(_pickupLocation!),
        ),
      );
    }

    // Destination marker
    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Destination',
            snippet: 'Tap to open in Google Maps',
          ),
          onTap: () => _openGoogleMapsToLocation(_destinationLocation!),
        ),
      );
    }

    // Passenger pickup markers (show for approved passengers)
    // Get current passengers from controller to ensure we have the latest data
    final currentPassengers = _getCurrentPassengers();
    if (currentPassengers.isNotEmpty) {
      for (int i = 0; i < currentPassengers.length; i++) {
        var passenger = currentPassengers[i];
        // Only show markers for approved passengers (status = '1')
        if (passenger.status == '1' &&
            passenger.pickupLatitude != null &&
            passenger.pickupLongitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('passenger_$i'),
              position: LatLng(
                double.parse(passenger.pickupLatitude!),
                double.parse(passenger.pickupLongitude!),
              ),
              icon: _passengerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              infoWindow: InfoWindow(
                title: '${passenger.user?.firstname ?? 'Passenger'} ${passenger.user?.lastname ?? ''}',
                snippet: 'Tap for pickup options',
              ),
              onTap: () => _onPassengerMarkerTapped(passenger),
            ),
          );
        }
      }
    }

    // Draw polylines
    _drawPolylines();

    setState(() {});
  }

  // Draw polylines between locations with proper road navigation
  Future<void> _drawPolylines() async {
    _polylines.clear();

    // Get current passengers from controller to ensure we have the latest data
    final currentPassengers = _getCurrentPassengers();

    // If ride is started (status = '1' - active)
    if (_isRideStarted(widget.ride.status ?? '')) {
      // Ride is active - show routes to joined passengers and final destination

      // Draw routes to each approved/joined passenger's pickup location
      if (_driverLocation != null && currentPassengers.isNotEmpty) {
        for (int i = 0; i < currentPassengers.length; i++) {
          var passenger = currentPassengers[i];

          // Only show routes to approved passengers (status = '1') who haven't been picked up yet
          // pickupStatus: null or '0' = not picked up, '1' = picked up, '2' = dropped off
          if (passenger.status == '1' && // Approved passenger
              (passenger.pickupStatus == null || passenger.pickupStatus == '0') && // Not picked up yet
              passenger.pickupLatitude != null &&
              passenger.pickupLongitude != null) {

            LatLng passengerPickupLocation = LatLng(
              double.parse(passenger.pickupLatitude!),
              double.parse(passenger.pickupLongitude!),
            );

            // Fetch route from driver to passenger pickup
            List<LatLng> routePoints = await _getPolylinePoints(_driverLocation!, passengerPickupLocation);

            if (routePoints.isNotEmpty) {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('driver_to_passenger_$i'),
                  points: routePoints,
                  color: MyColor.getPrimaryColor(), // Use primary color for passenger pickup routes
                  width: 6,
                  patterns: [], // Solid line
                  geodesic: true,
                ),
              );
            }
          }
        }
      }

      // Driver to final destination route
      if (_driverLocation != null && _destinationLocation != null) {
        // Fetch actual route points from Google Directions API
        List<LatLng> routePoints = await _getPolylinePoints(_driverLocation!, _destinationLocation!);

        if (routePoints.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('driver_to_destination'),
              points: routePoints,
              color: Colors.green,
              width: 6,
              patterns: [], // Solid line
              geodesic: true,
            ),
          );
        }
      }
    } else {
      // Before ride starts (status = '0' - pending)
      // Show driver to pickup and pickup to destination

      // Driver to pickup (if driver location available)
      if (_driverLocation != null && _pickupLocation != null) {
        List<LatLng> routePoints = await _getPolylinePoints(_driverLocation!, _pickupLocation!);

        if (routePoints.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('driver_to_pickup'),
              points: routePoints,
              color: Colors.blue,
              width: 6,
              patterns: [], // Solid line
              geodesic: true,
            ),
          );
        }
      }

      // Pickup to destination route (always show to preview the ride route)
      if (_pickupLocation != null && _destinationLocation != null) {
        List<LatLng> routePoints = await _getPolylinePoints(_pickupLocation!, _destinationLocation!);

        if (routePoints.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('pickup_to_destination'),
              points: routePoints,
              color: Colors.orange,
              width: 6,
              patterns: [], // Solid line
              geodesic: true,
            ),
          );
        }
      }

      // Also show routes to joined passengers even before ride starts
      if (_driverLocation != null && currentPassengers.isNotEmpty) {
        for (int i = 0; i < currentPassengers.length; i++) {
          var passenger = currentPassengers[i];

          // Show routes to approved passengers (status = '1')
          if (passenger.status == '1' &&
              passenger.pickupLatitude != null &&
              passenger.pickupLongitude != null) {

            LatLng passengerPickupLocation = LatLng(
              double.parse(passenger.pickupLatitude!),
              double.parse(passenger.pickupLongitude!),
            );

            // Fetch route from driver to passenger pickup
            List<LatLng> routePoints = await _getPolylinePoints(_driverLocation!, passengerPickupLocation);

            if (routePoints.isNotEmpty) {
              _polylines.add(
                Polyline(
                  polylineId: PolylineId('driver_to_passenger_$i'),
                  points: routePoints,
                  color: MyColor.getPrimaryColor(), // Use primary color for passenger pickup routes
                  width: 6,
                  patterns: [], // Solid line
                  geodesic: true,
                ),
              );
            }
          }
        }
      }
    }

    setState(() {});
  }

  // Get polyline points from Google Directions API
  Future<List<LatLng>> _getPolylinePoints(LatLng origin, LatLng destination) async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
        googleApiKey: Environment.mapKey,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print('Polyline error: ${result.errorMessage}');
        // Fallback to straight line if API fails
        polylineCoordinates = [origin, destination];
      }
    } catch (e) {
      print('Error getting polyline points: $e');
      // Fallback to straight line if error occurs
      polylineCoordinates = [origin, destination];
    }

    return polylineCoordinates;
  }

  // Suggest nearest passenger based on driver location
  void _suggestNearestPassenger() {
    final currentPassengers = _getCurrentPassengers();
    if (_driverLocation == null || currentPassengers.isEmpty) return;

    ScheduledRidePassenger? nearestPassenger;
    double? nearestDistance;

    for (var passenger in currentPassengers) {
      if (passenger.pickupLatitude != null &&
          passenger.pickupLongitude != null &&
          passenger.status == '0') { // Only suggest pending passengers
        
        double distance = _calculateDistance(
          _driverLocation!,
          LatLng(
            double.parse(passenger.pickupLatitude!),
            double.parse(passenger.pickupLongitude!),
          ),
        );
        
        if (nearestDistance == null || distance < nearestDistance) {
          nearestDistance = distance;
          nearestPassenger = passenger;
        }
      }
    }
    
    if (nearestPassenger != null) {
      // Show suggestion after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        _showNearestPassengerSuggestion(nearestPassenger!, nearestDistance!);
      });
    }
  }

  // Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  // Show nearest passenger suggestion
  void _showNearestPassengerSuggestion(ScheduledRidePassenger passenger, double distance) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: MyColor.primaryColor,
              size: 24,
            ),
            spaceSide(Dimensions.space8),
            Text(
              'Suggested Pickup',
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
              'Nearest passenger is ${(distance / 1000).toStringAsFixed(1)} km away',
              style: regularDefault.copyWith(
                color: MyColor.colorBlack.withOpacity(0.6),
              ),
            ),
            spaceDown(Dimensions.space12),
              Container(
              padding: const EdgeInsets.all(Dimensions.space12),
                decoration: BoxDecoration(
                color: MyColor.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                    style: boldDefault.copyWith(
                      color: MyColor.colorBlack,
                    ),
                  ),
                  spaceDown(Dimensions.space4),
                  Text(
                    passenger.pickupLocation ?? 'Location not specified',
                    style: regularSmall.copyWith(
                      color: MyColor.colorBlack.withOpacity(0.6),
                    ),
                  ),
                  spaceDown(Dimensions.space4),
                  Text(
                    '${passenger.seatsBooked} seat(s) • \$${passenger.totalFare}',
                    style: regularSmall.copyWith(
                      color: MyColor.primaryColor,
                      fontWeight: FontWeight.w600,
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
              'Cancel',
              style: regularDefault.copyWith(
                color: MyColor.colorBlack.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showPassengerPickupBottomSheet(passenger);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.primaryColor,
              shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Text(
              'Start Pickup',
              style: boldDefault.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle passenger marker tap
  void _onPassengerMarkerTapped(ScheduledRidePassenger passenger) {
    _showPassengerPickupBottomSheet(passenger);
  }

  // Navigate to PassengerMapScreen
  void _navigateToScheduledRideNavigation(ScheduledRidePassenger passenger) {
    Get.back(); // Close the bottom sheet first
    Get.toNamed(
      RouteHelper.passengerMapScreen,
      arguments: {
        'passenger': passenger,
        'rideId': widget.ride.id ?? '',
      },
    );
  }

  // Open Google Maps with directions to passenger
  Future<void> _openGoogleMapsForPassenger(ScheduledRidePassenger passenger) async {
    Get.back(); // Close the bottom sheet first
    
    if (passenger.pickupLatitude == null || passenger.pickupLongitude == null) {
      Get.snackbar(
        'Error',
        'Passenger pickup location not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final String destinationLat = passenger.pickupLatitude!;
    final String destinationLng = passenger.pickupLongitude!;
    
    // Get current driver location if available
    String originParam = '';
    if (_driverLocation != null) {
      originParam = '&origin=${_driverLocation!.latitude},${_driverLocation!.longitude}';
    }
    
    // Create Google Maps URL with directions
    final String googleMapsUrl = 
        'https://www.google.com/maps/dir/?api=1$originParam&destination=$destinationLat,$destinationLng&travelmode=driving';
    
    try {
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to Apple Maps on iOS
        final String appleMapsUrl = 
            'http://maps.apple.com/?daddr=$destinationLat,$destinationLng&dirflg=d';
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


  // Show passenger pickup bottom sheet
  void _showPassengerPickupBottomSheet(ScheduledRidePassenger passenger) {
    showPassengerBottomSheet(
      passenger: passenger,
      isOnboard: passenger.status == "1",
      onStartPickup: () => _startPassengerPickup(passenger),
      onReachedPickup: () => _markPassengerReached(passenger),
      onCancelPickup: () => _showCancelPickupConfirmation(passenger),
      onSeeOnMap: () => _navigateToScheduledRideNavigation(passenger),
      onOpenGoogleMaps: () => _openGoogleMapsForPassenger(passenger),
    );
    
    // Old implementation - keeping for reference
    /*Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(Dimensions.space20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            spaceDown(Dimensions.space20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    '${passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P'}',
                    style: regularDefault.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: Dimensions.fontLarge,
                    ),
                      ),
              ),
              spaceSide(Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                        style: boldDefault.copyWith(
                          color: MyColor.colorBlack,
                          fontSize: Dimensions.fontLarge,
                        ),
                      ),
                      spaceDown(Dimensions.space4),
                      Text(
                        '${passenger.seatsBooked ?? '0'} seat(s) • \$${passenger.totalFare ?? '0'}',
                        style: regularDefault.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (passenger.user?.mobile != null)
                        Text(
                          'Mobile: ${passenger.user!.mobile}',
                          style: regularSmall.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space20),
            if (passenger.pickupLocation != null && passenger.pickupLocation!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                      children: [
                    Icon(Icons.location_on, color: Colors.green, size: 20),
                    spaceSide(Dimensions.space8),
                        Expanded(
                          child: Text(
                        passenger.pickupLocation!,
                        style: regularDefault.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            spaceDown(Dimensions.space20),
            
            // Action buttons
            Row(
              children: [
                // Start Pickup Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                        Get.back();
                        _startPassengerPickup(passenger);
                      },
                      icon: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                      label: Text(
                        'Start Pickup',
                        style: regularDefault.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                spaceSide(Dimensions.space10),
                
                // Reached Pickup Button (only show if driver is near)
                if (_isDriverNearPassenger(passenger))
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Get.back();
                          _markPassengerReached(passenger);
                        },
                        icon: const Icon(Icons.location_on, color: Colors.white, size: 20),
                        label: Text(
                          'Reached',
                          style: regularDefault.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            spaceDown(Dimensions.space12),
            
            // Cancel Pickup Button
            Container(
              width: double.infinity,
              height: 45,
                              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Get.back();
                  _showCancelPickupConfirmation(passenger);
                },
                icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                label: Text(
                  'Cancel Pickup',
                  style: regularDefault.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );*/
  }

  // Start passenger pickup
  void _startPassengerPickup(ScheduledRidePassenger passenger) {
    final controller = Get.find<ScheduledRideController>();
    controller.startPassengerPickup(widget.ride.id!, passenger.id!);
    
    // Send rider status update via Pusher
    _sendRiderStatusUpdate(passenger, 'on_way');
    
    // Open Google Maps navigation
    _openGoogleMapsNavigation(passenger);
  }

  // Open Google Maps navigation to any location
  void _openGoogleMapsToLocation(LatLng location) async {
    final String destinationLat = location.latitude.toString();
    final String destinationLng = location.longitude.toString();
    
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

  // Open Google Maps navigation to passenger location
  void _openGoogleMapsNavigation(ScheduledRidePassenger passenger) async {
    if (passenger.pickupLatitude == null || passenger.pickupLongitude == null) {
      Get.snackbar(
        'Error',
        'Passenger pickup location not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final String destinationLat = passenger.pickupLatitude!;
    final String destinationLng = passenger.pickupLongitude!;
    
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

  // Mark passenger as reached pickup location
  void _markPassengerReached(ScheduledRidePassenger passenger) {
    final controller = Get.find<ScheduledRideController>();
    controller.markPassengerReached(widget.ride.id!, passenger.id!);
    
    // Send rider status update via Pusher
    _sendRiderStatusUpdate(passenger, 'reached');
  }

  // Show cancel pickup confirmation dialog
  void _showCancelPickupConfirmation(ScheduledRidePassenger passenger) {
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
                    '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                    style: boldDefault.copyWith(
                      color: MyColor.colorBlack,
                    ),
                  ),
                  spaceDown(Dimensions.space4),
                  Text(
                    passenger.pickupLocation ?? 'Location not specified',
                                        style: regularSmall.copyWith(
                      color: MyColor.colorBlack.withOpacity(0.6),
                    ),
                  ),
                  spaceDown(Dimensions.space4),
                  Text(
                    '${passenger.seatsBooked} seat(s) • \$${passenger.totalFare}',
                    style: regularSmall.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
              ),
            ),
            spaceDown(Dimensions.space12),
            Text(
              'This action will remove the passenger from the ride permanently.',
              style: regularSmall.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w500,
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
              _cancelPassengerPickup(passenger);
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
  void _cancelPassengerPickup(ScheduledRidePassenger passenger) {
    final controller = Get.find<ScheduledRideController>();
    controller.cancelPassengerPickup(widget.ride.id!, passenger.id!);
    
    // Send rider status update via Pusher
    _sendRiderStatusUpdate(passenger, 'cancelled');
  }

  // Send rider status update via Pusher
  void _sendRiderStatusUpdate(ScheduledRidePassenger passenger, String status) {
    try {
      final statusData = {
        'ride_id': widget.ride.id,
        'passenger_id': passenger.id,
        'driver_id': _driverId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'event_type': 'rider_status_update',
        'driver_name': 'Driver Name', // You can get this from user data
        'driver_phone': 'Driver Phone', // You can get this from user data
        'vehicle_info': 'Vehicle Info', // You can get this from vehicle data
      };

      // If pusher controller is initialized, use it to send status update
      if (_pusherController != null && _pusherController!.channel != null) {
        _pusherController!.channel!.trigger(
          PusherEvent(
            channelName: 'private-scheduled-ride-${widget.ride.id}',
            eventName: 'client-rider_status_update',
            data: jsonEncode(statusData),
          ),
        );
        print('Sent rider status update: $status for passenger ${passenger.id}');
      } else {
        print('Pusher not initialized, cannot send rider status update');
      }
    } catch (e) {
      print('Error sending rider status update: $e');
      // Error sending rider status update - fail silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Ride Details',
        isShowBackBtn: true,
        bgColor: MyColor.primaryColor,
        elevation: 0,
      ),
      body: GetBuilder<ScheduledRideController>(
        builder: (controller) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Map View
                  Expanded(
                    flex: 1,
                    child: _buildMapView(),
                  ),
                  
                  // Bottom Details Panel
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColor.colorWhite,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Dimensions.space15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Drag handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: Dimensions.space15),
                            decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            
                            // Check if ride is started or not
                            if (_isRideStarted(widget.ride.status ?? '')) ...[
                              // RIDE IS STARTED - Show real-time tracking UI
                              // Passenger Stats
                              _buildPassengerStatsCard(controller),
                              spaceDown(Dimensions.space15),

                              // Quick Actions
                              _buildQuickActionsCard(controller),
                              spaceDown(Dimensions.space15),

                              // Ride Information
                              _buildRideInfoCard(controller),
                              spaceDown(Dimensions.space15),

                              // Location Information
                              _buildLocationInfoCard(),
                              spaceDown(Dimensions.space15),

                              // Action Buttons for Active Rides (Cancel/Complete)
                              _buildActionButtons(controller),
                              spaceDown(Dimensions.space20),
                            ] else ...[
                              // RIDE IS NOT STARTED - Show original management UI
                              // Ride Information
                              _buildRideInfoCard(controller),
                              spaceDown(Dimensions.space15),
                              
                              // Location Information
                              _buildLocationInfoCard(),
                              spaceDown(Dimensions.space15),
                              
                              // Action Buttons (Start Ride, Edit Ride, Cancel Ride)
                              _buildActionButtons(controller),
                              spaceDown(Dimensions.space20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Check if ride is started (status = '1' or 'active')
  bool _isRideStarted(String status) {
    return status == '1' || status.toLowerCase() == 'active';
  }

  // Build map view
  Widget _buildMapView() {
    // Determine initial location priority: driver location > pickup location > destination > default (Lahore, Pakistan)
    LatLng initialLocation;

    if (_driverLocation != null) {
      initialLocation = _driverLocation!;
      print('Map using driver location: $_driverLocation');
    } else if (_pickupLocation != null) {
      initialLocation = _pickupLocation!;
      print('Map using pickup location: $_pickupLocation');
    } else if (_destinationLocation != null) {
      initialLocation = _destinationLocation!;
      print('Map using destination location: $_destinationLocation');
    } else {
      // Default to Lahore, Pakistan instead of San Francisco
      initialLocation = const LatLng(31.5204, 74.3587);
      print('Map using default location (Lahore, Pakistan): $initialLocation');
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 14.0,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        // Map controller initialized
        print('Google Map created with location: $initialLocation');
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  // Build passenger stats card
  Widget _buildPassengerStatsCard(ScheduledRideController controller) {
    final passengerCounts = controller.getPassengerCountsByStatus(widget.ride);
    
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.08),
            Colors.blue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passenger Status',
                      style: boldDefault.copyWith(
                        color: Colors.blue,
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      'Real-time passenger tracking',
                      style: regularSmall.copyWith(
                        color: Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedStatItem(
                  'Total',
                  '${passengerCounts['total']}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              spaceSide(Dimensions.space10),
              Expanded(
                child: _buildEnhancedStatItem(
                  'Picked Up',
                  '${passengerCounts['picked_up']}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              spaceSide(Dimensions.space10),
              Expanded(
                child: _buildEnhancedStatItem(
                  'Remaining',
                  '${passengerCounts['remaining']}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build quick actions card
  Widget _buildQuickActionsCard(ScheduledRideController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[600]!, Colors.grey[700]!],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: boldDefault.copyWith(
                        color: MyColor.colorBlack,
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      'Access important features quickly',
                      style: regularSmall.copyWith(
                        color: Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedQuickActionButton(
                  'Passenger Requests',
                  Icons.people,
                  Colors.blue,
                  () => Get.to(() => PassengerRequestsScreen(ride: widget.ride)),
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: _buildEnhancedQuickActionButton(
                  'Payment Summary',
                  Icons.payment,
                  Colors.purple,
                  () => Get.to(() => PaymentSummaryScreen(ride: widget.ride)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Build enhanced stat item
  Widget _buildEnhancedStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.space6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          spaceDown(Dimensions.space8),
          Text(
            value,
            style: boldDefault.copyWith(
              color: color,
              fontSize: Dimensions.fontLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          spaceDown(Dimensions.space2),
          Text(
            label,
            style: regularSmall.copyWith(
              color: Colors.grey[600],
              fontSize: Dimensions.fontSmall,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  // Build enhanced quick action button
  Widget _buildEnhancedQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.space8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            spaceDown(Dimensions.space10),
            Text(
              label,
              style: regularDefault.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: Dimensions.fontSmall,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRideInfoCard(ScheduledRideController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyColor.colorWhite,
            MyColor.colorWhite.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MyColor.primaryColor, MyColor.primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Information',
                      style: boldLarge.copyWith(
                        color: MyColor.getRideTitleColor(),
                        fontWeight: FontWeight.w700,
                        fontSize: Dimensions.fontOverLarge,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      'Scheduled ride details and status',
                      style: regularSmall.copyWith(
                        color: Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                      ),
                    ),
                  ],
                ),
              ),
              // Show active indicator when navigated from dashboard
              if (widget.isFromDashboard)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space12,
                    vertical: Dimensions.space6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      spaceSide(Dimensions.space6),
                      Text(
                        'Active Ride',
                        style: regularSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          spaceDown(Dimensions.space20),
          
          // Service information card
          if (widget.ride.service != null)
            Container(
              padding: const EdgeInsets.all(Dimensions.space15),
              margin: const EdgeInsets.only(bottom: Dimensions.space15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MyColor.primaryColor.withOpacity(0.1),
                    MyColor.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                border: Border.all(
                  color: MyColor.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space8),
                    decoration: BoxDecoration(
                      color: MyColor.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: Icon(
                      Icons.local_taxi,
                      color: MyColor.primaryColor,
                      size: 20,
                    ),
                  ),
                  spaceSide(Dimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Type',
                          style: regularSmall.copyWith(
                            color: Colors.grey[600],
                            fontSize: Dimensions.fontSmall,
                          ),
                        ),
                        spaceDown(Dimensions.space2),
                        Text(
                          widget.ride.service!.name ?? 'Standard Ride',
                          style: boldDefault.copyWith(
                            color: MyColor.primaryColor,
                            fontSize: Dimensions.fontDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Enhanced ride details grid
          Row(
            children: [
              Expanded(
                child: _buildEnhancedInfoItem(
                  Icons.schedule,
                  'Date & Time',
                  controller.formatDateTime(widget.ride.scheduledDateTime),
                  Colors.blue,
                ),
              ),
              spaceSide(Dimensions.space10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => PassengerRequestsScreen(
                      ride: widget.ride,
                    ));
                  },
                  child: _buildEnhancedInfoItemWithBadge(
                    Icons.people,
                    'Passengers',
                    widget.ride.numberOfPassengers ?? '0',
                    Colors.purple,
                    badgeCount: controller.getPendingPassengersCount(widget.ride.id!),
                  ),
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedInfoItem(
                  Icons.straighten,
                  'Distance',
                  '${widget.ride.distance ?? '0'} km',
                  Colors.green,
                ),
              ),
              spaceSide(Dimensions.space10),
              Expanded(
                child: _buildEnhancedInfoItem(
                  Icons.access_time,
                  'Duration',
                  '${widget.ride.duration ?? '0'} min',
                  Colors.orange,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildEnhancedInfoItem(
                  Icons.attach_money,
                  'Estimated Fare',
                  '\$${widget.ride.estimatedFare ?? '0'}',
                  Colors.green,
                  isFare: true,
                ),
              ),
              if (widget.ride.availableSeats != null) ...[
                spaceSide(Dimensions.space10),
                Expanded(
                  child: _buildEnhancedInfoItem(
                    Icons.event_seat,
                    'Available Seats',
                    '${widget.ride.availableSeats}',
                    Colors.indigo,
                  ),
                ),
              ],
            ],
          ),
          if (widget.ride.note != null && widget.ride.note!.isNotEmpty) ...[
            spaceDown(Dimensions.space15),
            _buildNoteCard(widget.ride.note!),
          ],
        ],
      ),
    );
  }



  // Build location information card
  Widget _buildLocationInfoCard() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.08),
            Colors.green.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Details',
                      style: boldDefault.copyWith(
                        color: Colors.green,
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      'Pickup and destination information',
                      style: regularSmall.copyWith(
                        color: Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),
          
          // Pickup Location
          Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            margin: const EdgeInsets.only(bottom: Dimensions.space12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.space8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: Colors.green,
                    size: 18,
                  ),
                ),
                spaceSide(Dimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Location',
                        style: regularSmall.copyWith(
                          color: Colors.grey[600],
                          fontSize: Dimensions.fontSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      spaceDown(Dimensions.space4),
                      Text(
                        widget.ride.pickupLocation ?? 'Location not specified',
                        style: regularDefault.copyWith(
                          color: Colors.green[700],
                          fontSize: Dimensions.fontDefault,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Destination Location
          Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.space8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Icon(
                    Icons.place,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
                spaceSide(Dimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Destination',
                        style: regularSmall.copyWith(
                          color: Colors.grey[600],
                          fontSize: Dimensions.fontSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      spaceDown(Dimensions.space4),
                      Text(
                        widget.ride.destination ?? 'Destination not specified',
                        style: regularDefault.copyWith(
                          color: Colors.red[700],
                          fontSize: Dimensions.fontDefault,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ScheduledRideController controller) {
    // Helper to check if ride has expired (scheduled time has passed)
    bool isExpired = false;
    if (widget.ride.scheduledDateTime != null) {
      try {
        final scheduledTime = DateTime.parse(widget.ride.scheduledDateTime!);
        isExpired = DateTime.now().isAfter(scheduledTime);
      } catch (e) {
        print('Error parsing scheduled time: $e');
      }
    }

    // Debug logging
    print('=== ACTION BUTTONS DEBUG ===');
    print('Ride Status: ${widget.ride.status}');
    print('Is Expired: $isExpired');
    print('Can Cancel: ${controller.canCancelRide(widget.ride.status ?? '')}');
    print('Can Start: ${controller.canStartRide(widget.ride.status ?? '', widget.ride.scheduledDateTime)}');
    print('Can Complete: ${controller.canCompleteRide(widget.ride.status ?? '')}');
    print('Is From Dashboard: ${widget.isFromDashboard}');
    print('========================');

    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.indigo.shade600],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Actions',
                      style: boldLarge.copyWith(
                        color: MyColor.getRideTitleColor(),
                        fontWeight: FontWeight.w700,
                        fontSize: Dimensions.fontOverLarge,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      isExpired && controller.canCancelRide(widget.ride.status ?? '')
                        ? 'This ride has expired. Please cancel or delete it.'
                        : 'Manage your scheduled ride',
                      style: regularSmall.copyWith(
                        color: isExpired ? Colors.orange[700] : Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                        fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),

          // Start Ride Button - Hide if navigated from dashboard (ride is already active)
          if (controller.canStartRide(widget.ride.status ?? '', widget.ride.scheduledDateTime) && !widget.isFromDashboard)
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: Dimensions.space12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: TextButton.icon(
                onPressed: controller.isStarting ? null : () {
                  _showStartDialog(controller, widget.ride.id!);
                },
                icon: controller.isStarting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.play_arrow, color: Colors.white, size: 20),
                label: Text(
                  controller.isStarting ? 'Starting...' : 'Start Ride',
                  style: regularDefault.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Edit Ride Button - Only show for non-expired pending rides
          if (controller.canCancelRide(widget.ride.status ?? '') && !isExpired)
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: Dimensions.space12),
              decoration: BoxDecoration(
                border: Border.all(color: MyColor.primaryColor),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Get.to(() => CreateScheduledRideScreen(scheduledRide: widget.ride));
                },
                icon: Icon(Icons.edit, color: MyColor.primaryColor, size: 20),
                label: Text(
                  'Edit Ride',
                  style: regularDefault.copyWith(
                    color: MyColor.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Cancel Ride Button - Always show for pending rides (including expired ones)
          // Force show for pending status regardless of other conditions
          if (widget.ride.status == '0' || widget.ride.status?.toLowerCase() == 'pending' || controller.canCancelRide(widget.ride.status ?? ''))
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: Dimensions.space12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: TextButton.icon(
                onPressed: controller.isCancelling ? null : () {
                  _showCancelDialog(controller, widget.ride.id!);
                },
                icon: controller.isCancelling
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.cancel, color: Colors.white, size: 20),
                label: Text(
                  controller.isCancelling ? 'Cancelling...' : 'Cancel Ride',
                  style: regularDefault.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Delete Ride Button - Show for expired pending rides as an alternative to cancel
          if (controller.canCancelRide(widget.ride.status ?? '') && isExpired)
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: Dimensions.space12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade700, width: 2),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                color: Colors.red.shade50,
              ),
              child: TextButton.icon(
                onPressed: controller.isDeleting ? null : () {
                  _showDeleteDialog(controller, widget.ride.id!);
                },
                icon: controller.isDeleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.red.shade700,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
                label: Text(
                  controller.isDeleting ? 'Deleting...' : 'Delete Ride',
                  style: regularDefault.copyWith(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Complete Ride Button
          if (controller.canCompleteRide(widget.ride.status ?? ''))
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: Dimensions.space12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: TextButton.icon(
                onPressed: controller.isCompleting ? null : () {
                  _showCompleteDialog(controller, widget.ride.id!);
                },
                icon: controller.isCompleting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.check_circle, color: Colors.white, size: 20),
                label: Text(
                  controller.isCompleting ? 'Completing...' : 'Complete Ride',
                  style: regularDefault.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          // Payment Summary Button
          
          // Payment Summary Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            ),
            child: TextButton.icon(
              onPressed: () {
                Get.to(() => PaymentSummaryScreen(ride: widget.ride));
              },
              icon: Icon(Icons.payment, color: Colors.white, size: 20),
              label: Text(
                'Payment Summary',
                style: regularDefault.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEnhancedInfoItem(IconData icon, String label, String value, Color color, {bool isFare = false}) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.space8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          spaceDown(Dimensions.space10),
          Text(
            label,
            style: regularSmall.copyWith(
              color: Colors.grey[600],
              fontSize: Dimensions.fontSmall,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          spaceDown(Dimensions.space4),
          Text(
            value,
            style: boldDefault.copyWith(
              color: isFare ? color : MyColor.colorBlack,
              fontSize: Dimensions.fontDefault,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoItemWithBadge(IconData icon, String label, String value, Color color, {int badgeCount = 0}) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          spaceDown(Dimensions.space10),
          Text(
            label,
            style: regularSmall.copyWith(
              color: Colors.grey[600],
              fontSize: Dimensions.fontSmall,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          spaceDown(Dimensions.space4),
          Text(
            value,
            style: boldDefault.copyWith(
              color: MyColor.colorBlack,
              fontSize: Dimensions.fontDefault,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String note) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.space8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            child: Icon(
              Icons.note,
              color: Colors.orange,
              size: 20,
            ),
          ),
          spaceSide(Dimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Note',
                  style: regularSmall.copyWith(
                    color: Colors.grey[600],
                    fontSize: Dimensions.fontSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                spaceDown(Dimensions.space4),
                Text(
                  note,
                  style: regularDefault.copyWith(
                    color: Colors.orange[700],
                    fontSize: Dimensions.fontDefault,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showCancelDialog(ScheduledRideController controller, String rideId) {
    final TextEditingController reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Cancel Scheduled Ride'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this scheduled ride? This action cannot be undone.'),
            spaceDown(Dimensions.space15),
            Text(
              'Reason for cancellation (optional):',
              style: regularDefault.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            spaceDown(Dimensions.space8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g., Driver unavailable, Vehicle issues...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space12,
                  vertical: Dimensions.space8,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No, Keep It',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isCancelling ? null : () {
              final reason = reasonController.text.trim().isNotEmpty 
                  ? reasonController.text.trim() 
                  : 'Cancelled by driver';
              Get.back(); // Close dialog first
              controller.cancelScheduledRide(rideId, reason, onSuccess: () {
                Get.back(); // Pop back to listings after successful cancel
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Yes, Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ScheduledRideController controller, String rideId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Delete Scheduled Ride'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This scheduled ride has expired and was never started. Do you want to permanently delete it?'),
            spaceDown(Dimensions.space12),
            Container(
              padding: const EdgeInsets.all(Dimensions.space10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  spaceSide(Dimensions.space8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: regularSmall.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
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
              'Cancel',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isDeleting ? null : () {
              Get.back(); // Close dialog first
              controller.deleteScheduledRide(rideId);
              // After delete, navigate back to list
              Future.delayed(const Duration(milliseconds: 500), () {
                if (Get.isDialogOpen == false) {
                  Get.back();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showStartDialog(ScheduledRideController controller, String rideId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.green, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Start Scheduled Ride'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you ready to start this scheduled ride? This will mark the ride as active and notify passengers.'),
            spaceDown(Dimensions.space15),
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  spaceSide(Dimensions.space8),
                  Expanded(
                    child: Text(
                      'Make sure you\'re at the pickup location before starting.',
                      style: regularDefault.copyWith(
                        color: Colors.blue[700],
                        fontSize: Dimensions.fontSmall,
                      ),
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
              'Not Ready',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isStarting ? null : () {
              Get.back(); // Close dialog first
              controller.startScheduledRide(rideId, onSuccess: () {
                // Initialize location broadcasting when ride starts
                _initializeLocationBroadcasting();
                print('Scheduled ride started - location broadcasting initialized');

                // For now, just go back since navigation requires a specific passenger
                // In a real scenario, you'd select the first passenger or prompt
                Get.back();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isStarting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Start Ride',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(ScheduledRideController controller, String rideId) {
    final TextEditingController noteController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Complete Ride'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mark this scheduled ride as completed?'),
            spaceDown(Dimensions.space15),
            Text(
              'Completion Note (Optional):',
              style: regularDefault.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            spaceDown(Dimensions.space8),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: 'e.g., All passengers dropped off successfully',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space12,
                  vertical: Dimensions.space8,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Not Yet',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isCompleting ? null : () {
              final note = noteController.text.trim().isNotEmpty 
                  ? noteController.text.trim() 
                  : null;
              Get.back(); // Close dialog first
              controller.completeScheduledRide(rideId, note, onSuccess: () {
                Get.back(); // Pop back to listings after successful completion
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isCompleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Complete',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
