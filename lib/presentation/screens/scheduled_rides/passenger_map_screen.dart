import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/core/utils/my_icons.dart';
import 'package:ezdriver/core/utils/helper.dart';
import 'package:ezdriver/core/utils/marker_helper.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/environment.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/buttons/rounded_button.dart';
import 'package:ezdriver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ezdriver/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class PassengerMapScreen extends StatefulWidget {
  final ScheduledRidePassenger passenger;
  final String rideId;

  const PassengerMapScreen({
    super.key,
    required this.passenger,
    required this.rideId,
  });

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  final ScheduledRideController controller = Get.find();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  bool _isLoading = true;
  bool _hasReachedLocation = false;
  double _distanceToPassenger = 0;

  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _passengerIcon;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _loadCustomMarkers();
    await _getCurrentLocation();
    _startLocationTracking();
    _setupMarkers();
    _drawRoute();
  }

  Future<void> _loadCustomMarkers() async {
    // Load custom marker icons from assets
    try {
      // Driver car icon from assets
      final Uint8List? carIconBytes = await Helper.getBytesFromAsset(
        MyIcons.carMarkerIcon,
        120, // Size for car marker
      );
      if (carIconBytes != null) {
        _driverIcon = BitmapDescriptor.fromBytes(carIconBytes);
      }

      // Try to load passenger person icon from assets, fallback to programmatic creation
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
      print('Error loading custom markers: $e');
      // Fallback to default markers if assets fail to load
      _driverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      _passengerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar('Location Permission', 'Please enable location permission');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'Failed to get current location');
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        _updateDriverMarker(position);
        _checkDistanceToPassenger(position);
      });

      // Update camera to follow driver
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      // Redraw route periodically
      _drawRoute();
    });
  }

  void _updateDriverMarker(Position position) {
    final driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: LatLng(position.latitude, position.longitude),
      icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: const InfoWindow(title: 'Your Location'),
      rotation: position.heading,
      anchor: const Offset(0.5, 0.5), // Center the marker on the position
      zIndex: 2, // Keep driver marker on top
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');
      _markers.add(driverMarker);
    });
  }

  void _checkDistanceToPassenger(Position currentPosition) {
    final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
    final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

    _distanceToPassenger = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      passengerLat,
      passengerLng,
    );

    // Consider reached if within 50 meters
    if (_distanceToPassenger <= 50 && !_hasReachedLocation) {
      // Automatically mark as reached and notify passenger
      _autoMarkAsReached();
    }
  }

  void _setupMarkers() {
    final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
    final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

    // Add passenger marker
    final passengerMarker = Marker(
      markerId: const MarkerId('passenger'),
      position: LatLng(passengerLat, passengerLng),
      icon: _passengerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: '${widget.passenger.user?.firstname ?? ''} ${widget.passenger.user?.lastname ?? ''}',
        snippet: widget.passenger.pickupLocation ?? '',
      ),
      anchor: const Offset(0.5, 1.0), // Position at the bottom of the marker
      zIndex: 1, // Keep passenger marker below driver marker
    );

    setState(() {
      _markers.add(passengerMarker);
    });

    // Add driver marker if position is available
    if (_currentPosition != null) {
      _updateDriverMarker(_currentPosition!);
    }
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null) return;

    final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
    final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: Environment.mapKey,
      request: PolylineRequest(
        origin: PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(passengerLat, passengerLng),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];

      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      Polyline polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: MyColor.getPrimaryColor(), // Use primary color for the route
        width: 6,
        points: polylineCoordinates,
        patterns: [], // Solid line (no dashes)
        geodesic: true, // Draw smooth curved lines
      );

      setState(() {
        _polylines.clear();
        _polylines.add(polyline);
      });
    }
  }

  void _showArrivalNotification() {
    Get.dialog(
      AlertDialog(
        title: const Text('Arrival Confirmation'),
        content: const Text('You have reached the passenger pickup location. Would you like to notify the passenger?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _notifyPassenger();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.getPrimaryColor(),
            ),
            child: const Text('Notify Passenger'),
          ),
        ],
      ),
    );
  }

  void _autoMarkAsReached() {
    // Automatically mark as reached when driver is within 50 meters
    controller.markPassengerReached(
      widget.rideId,
      widget.passenger.id ?? '',
      onSuccess: () {
        // Update state to show reached status
        setState(() {
          _hasReachedLocation = true;
        });

        // Show auto-notification
        Get.snackbar(
          'Arrived at Pickup',
          'You are within 50 meters of the pickup location. The passenger has been notified.',
          backgroundColor: MyColor.greenSuccessColor.withOpacity(0.9),
          colorText: MyColor.colorWhite,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: _callPassenger,
            child: const Text(
              'CALL',
              style: TextStyle(color: MyColor.colorWhite),
            ),
          ),
        );
      },
    );
  }

  void _markAsReachedAndNotify() {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.space20),
            child: CustomLoader(),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Call the markPassengerReached API
    controller.markPassengerReached(
      widget.rideId,
      widget.passenger.id ?? '',
      onSuccess: () {
        // Close loading dialog
        Get.back();

        // Update state to show reached status
        setState(() {
          _hasReachedLocation = true;
        });

        // Show success notification
        CustomSnackBar.success(
          successList: ['You have marked your arrival. The passenger has been notified.'],
        );
      },
    );
  }

  void _notifyPassenger() {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Dimensions.space20),
            child: CustomLoader(),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Call the new markPassengerReached API
    controller.markPassengerReached(
      widget.rideId,
      widget.passenger.id ?? '',
      onSuccess: () {
        // Close loading dialog
        Get.back();

        // Show success dialog with option to call passenger
        Get.dialog(
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: MyColor.greenSuccessColor),
                SizedBox(width: Dimensions.space10),
                Text('Notification Sent'),
              ],
            ),
            content: const Text(
              'The passenger has been notified of your arrival. Would you like to call them now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  _callPassenger();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.getPrimaryColor(),
                ),
                child: const Text('Call Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _callPassenger() async {
    final phoneNumber = widget.passenger.user?.mobile ?? '';
    if (phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Passenger phone number not available');
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      Get.snackbar('Error', 'Could not make phone call');
    }
  }

  LatLngBounds _getMapBounds() {
    if (_currentPosition == null) {
      // Return passenger location bounds if driver location not available
      final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
      final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

      return LatLngBounds(
        southwest: LatLng(passengerLat - 0.01, passengerLng - 0.01),
        northeast: LatLng(passengerLat + 0.01, passengerLng + 0.01),
      );
    }

    final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
    final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

    double minLat = _currentPosition!.latitude < passengerLat
        ? _currentPosition!.latitude
        : passengerLat;
    double maxLat = _currentPosition!.latitude > passengerLat
        ? _currentPosition!.latitude
        : passengerLat;
    double minLng = _currentPosition!.longitude < passengerLng
        ? _currentPosition!.longitude
        : passengerLng;
    double maxLng = _currentPosition!.longitude > passengerLng
        ? _currentPosition!.longitude
        : passengerLng;

    return LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );
  }

  String _formatDistance() {
    if (_distanceToPassenger < 1000) {
      return '${_distanceToPassenger.toStringAsFixed(0)} meters';
    } else {
      return '${(_distanceToPassenger / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passengerLat = double.tryParse(widget.passenger.pickupLatitude ?? '0') ?? 0;
    final passengerLng = double.tryParse(widget.passenger.pickupLongitude ?? '0') ?? 0;

    return Scaffold(
      appBar: CustomAppBar(
        title: '${widget.passenger.user?.firstname ?? ''} ${widget.passenger.user?.lastname ?? ''}',
        isShowBackBtn: true,
      ),
      body: _isLoading
          ? const Center(child: CustomLoader())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(passengerLat, passengerLng),
                    zoom: 15.0, // Higher zoom for better detail
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    // Fit bounds to show both markers
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngBounds(_getMapBounds(), 100),
                      );
                    });
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false, // We're using custom marker for driver
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: true,
                ),

                // Distance and status card
                Positioned(
                  top: Dimensions.space10,
                  left: Dimensions.space10,
                  right: Dimensions.space10,
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.space15),
                    decoration: BoxDecoration(
                      color: MyColor.getCardBgColor(),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: MyColor.getPrimaryColor(),
                              size: 20,
                            ),
                            const SizedBox(width: Dimensions.space5),
                            Expanded(
                              child: Text(
                                widget.passenger.pickupLocation ?? 'Pickup Location',
                                style: regularDefault.copyWith(
                                  fontSize: Dimensions.fontSmall,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.space10),
                        Row(
                          children: [
                            Icon(
                              Icons.navigation,
                              color: MyColor.secondaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: Dimensions.space5),
                            Text(
                              'Distance: ${_formatDistance()}',
                              style: semiBoldDefault.copyWith(
                                color: MyColor.primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        if (_hasReachedLocation) ...[
                          const SizedBox(height: Dimensions.space10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.space10,
                              vertical: Dimensions.space5,
                            ),
                            decoration: BoxDecoration(
                              color: MyColor.greenSuccessColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: MyColor.greenSuccessColor,
                                  size: 16,
                                ),
                                const SizedBox(width: Dimensions.space5),
                                Text(
                                  'Arrived at location',
                                  style: regularDefault.copyWith(
                                    color: MyColor.greenSuccessColor,
                                    fontSize: Dimensions.fontSmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Positioned(
                  bottom: Dimensions.space20,
                  left: Dimensions.space20,
                  right: Dimensions.space20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RoundedButton(
                        text: _hasReachedLocation
                            ? 'Notify Arrival'
                            : 'Call Passenger',
                        press: () {
                          if (_hasReachedLocation) {
                            _notifyPassenger();
                          } else {
                            _callPassenger();
                          }
                        },
                        color: MyColor.getPrimaryColor(),
                        textColor: MyColor.colorWhite,
                        cornerRadius: Dimensions.mediumRadius,
                        isOutlined: false,
                        horizontalPadding: Dimensions.space15,
                        verticalPadding: Dimensions.space15,
                      ),
                      const SizedBox(height: Dimensions.space10),
                      if (!_hasReachedLocation)
                        RoundedButton(
                          text: 'Mark as Reached',
                          press: () {
                            // Directly call the API to mark as reached
                            _markAsReachedAndNotify();
                          },
                          color: MyColor.cardBgColor,
                          textColor: MyColor.primaryTextColor,
                          cornerRadius: Dimensions.mediumRadius,
                          isOutlined: true,
                          borderColor: MyColor.getPrimaryColor(),
                          horizontalPadding: Dimensions.space15,
                          verticalPadding: Dimensions.space15,
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}