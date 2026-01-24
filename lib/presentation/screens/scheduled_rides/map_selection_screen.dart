import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/helper.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/my_icons.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/model/location/selected_location_info.dart';
import 'package:ezdriver/presentation/components/buttons/rounded_button.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:ezdriver/presentation/packages/google_auto_complete_search/google_places_flutter.dart';
import 'package:ezdriver/presentation/packages/google_auto_complete_search/model/prediction.dart';
import 'package:ezdriver/environment.dart';

class MapSelectionScreen extends StatefulWidget {
  final bool isPickup;
  final Function(SelectedLocationInfo) onLocationSelected;
  
  const MapSelectionScreen({
    super.key,
    required this.isPickup,
    required this.onLocationSelected,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? mapController;
  Uint8List? markerIcon;
  bool showMarker = true;
  bool isLoading = false;
  bool showSearchField = false;
  double selectedLatitude = 37.7749;
  double selectedLongitude = -122.4194;
  String selectedAddress = 'San Francisco, CA';
  String currentAddress = '';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _getCurrentLocation();
  }

  Future<void> _initializeMap() async {
    markerIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Service Disabled',
          'Please enable location services',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Location Permission Denied',
            'Please grant location permission',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Location Permission Required',
          'Please enable location permission in settings',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedLatitude = position.latitude;
        selectedLongitude = position.longitude;
        isLoading = false;
      });

      _getAddressFromCoordinates(position.latitude, position.longitude);
      _animateToLocation();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          currentAddress = '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}';
          selectedAddress = currentAddress;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _animateToLocation() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(selectedLatitude, selectedLongitude),
          zoom: Environment.mapDefaultZoom,
        ),
      ),
    );
  }

  void _onPlaceSelected(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      final lat = double.tryParse(prediction.lat!) ?? selectedLatitude;
      final lng = double.tryParse(prediction.lng!) ?? selectedLongitude;

      setState(() {
        selectedLatitude = lat;
        selectedLongitude = lng;
        selectedAddress = prediction.description ?? '';
        searchController.text = prediction.description ?? '';
        showSearchField = false;
      });

      _animateToLocation();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: MyColor.screenBgColor,
        body: Stack(
          children: [
            // Google Map
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GoogleMap(
                trafficEnabled: false,
                indoorViewEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // Disable native location button
                mapType: MapType.normal,
                minMaxZoomPreference: const MinMaxZoomPreference(0, 100),
                markers: <Marker>{
                  if (showMarker)
                    Marker(
                      markerId: const MarkerId("selected_location"),
                      position: LatLng(selectedLatitude, selectedLongitude),
                      infoWindow: const InfoWindow(title: "Selected Location"),
                      icon: markerIcon == null
                          ? BitmapDescriptor.defaultMarker
                          : BitmapDescriptor.bytes(markerIcon!),
                      onDragStart: (LatLng l) {},
                      onDrag: (LatLng l) {
                        setState(() {
                          selectedLatitude = l.latitude;
                          selectedLongitude = l.longitude;
                        });
                        _getAddressFromCoordinates(l.latitude, l.longitude);
                      },
                    ),
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(selectedLatitude, selectedLongitude),
                  zoom: Environment.mapDefaultZoom,
                  bearing: 20,
                  tilt: 0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                onCameraMoveStarted: () {
                  setState(() {
                    showMarker = false;
                  });
                },
                onCameraIdle: () {
                  setState(() {
                    showMarker = true;
                  });
                  _getAddressFromCoordinates(selectedLatitude, selectedLongitude);
                },
                onCameraMove: (CameraPosition position) {
                  setState(() {
                    selectedLatitude = position.target.latitude;
                    selectedLongitude = position.target.longitude;
                  });
                },
                onTap: (LatLng latLng) {
                  setState(() {
                    selectedLatitude = latLng.latitude;
                    selectedLongitude = latLng.longitude;
                  });
                  _getAddressFromCoordinates(latLng.latitude, latLng.longitude);
                },
              ),
            ),

            // Custom marker when camera is moving
            if (!showMarker)
              Positioned(
                bottom: 45,
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: markerIcon != null 
                      ? Image.memory(markerIcon!, width: 45)
                      : Icon(Icons.location_on, size: 45, color: MyColor.primaryColor),
                ),
              ),

            // Loading indicator
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: MyColor.primaryColor,
                ),
              ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: MyColor.colorBlack,
                ),
              ),
            ),

            // Search field or search button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 70,
              right: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48, // Fixed height to match back button
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: showSearchField
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: GooglePlacesAutoCompleteTextFormField(
                                textEditingController: searchController,
                                googleAPIKey: Environment.mapKey,
                                debounceTime: 400,
                                countries: const ['PK'], // Pakistan
                                isLatLngRequired: true,
                                inputDecoration: InputDecoration(
                                  hintText: widget.isPickup
                                      ? 'Search pickup location...'
                                      : 'Search destination...',
                                  border: InputBorder.none,
                                  hintStyle: regularDefault.copyWith(
                                    color: Colors.grey[400],
                                    fontSize: Dimensions.fontSmall,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  isDense: true,
                                ),
                                style: regularDefault.copyWith(
                                  fontSize: Dimensions.fontSmall,
                                ),
                                itmClick: (prediction) {
                                  searchController.text =
                                      prediction.description ?? '';
                                },
                                getPlaceDetailWithLatLng: (prediction) {
                                  _onPlaceSelected(prediction);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    showSearchField = false;
                                    searchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.close, size: 20),
                                color: MyColor.colorBlack,
                              ),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            showSearchField = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: MyColor.primaryColor,
                                size: 20,
                              ),
                              spaceSide(Dimensions.space8),
                              Text(
                                widget.isPickup
                                    ? 'Search pickup location...'
                                    : 'Search destination...',
                                style: regularDefault.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: Dimensions.fontSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Current location button
            Positioned(
              right: Dimensions.space15,
              bottom: 220, // Added more spacing from bottom
              child: FloatingActionButton(
                backgroundColor: MyColor.primaryColor,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.location_searching,
                  color: MyColor.colorWhite,
                  size: Dimensions.space30,
                ),
                onPressed: () async {
                  await _getCurrentLocation();
                },
              ),
            ),

            // Location details bottom sheet
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
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
                    // Drag indicator
                    Center(
                      child: Container(
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ),
                    spaceDown(Dimensions.space20),

                    // Location details
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: MyColor.primaryColor,
                          size: 20,
                        ),
                        spaceSide(Dimensions.space8),
                        Expanded(
                          child: Text(
                            'Selected Location',
                            style: boldDefault.copyWith(
                              color: MyColor.colorBlack,
                              fontSize: Dimensions.fontMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space10),
                    Text(
                      selectedAddress,
                      style: regularDefault.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    spaceDown(Dimensions.space5),
                    Text(
                      'Lat: ${selectedLatitude.toStringAsFixed(6)}, Lng: ${selectedLongitude.toStringAsFixed(6)}',
                      style: regularSmall.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    spaceDown(Dimensions.space20),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: RoundedButton(
                        text: 'Confirm Location',
                        press: () {
                          var selectedLocation = SelectedLocationInfo(
                            latitude: selectedLatitude,
                            longitude: selectedLongitude,
                            placeName: 'Selected Location',
                            address: selectedAddress,
                            city: 'San Francisco',
                            country: 'United States',
                            fullAddress: selectedAddress,
                          );

                          widget.onLocationSelected(selectedLocation);
                          Get.back();
                        },
                        color: MyColor.primaryColor,
                        textColor: Colors.white,
                      ),
                    ),
                    spaceDown(Dimensions.space10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 