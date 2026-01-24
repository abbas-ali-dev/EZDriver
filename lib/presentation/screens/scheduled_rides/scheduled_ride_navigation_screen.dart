import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_navigation_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ScheduledRideNavigationScreen extends StatefulWidget {
  final ScheduledRideModel ride;
  final ScheduledRidePassenger passenger;

  const ScheduledRideNavigationScreen({
    super.key,
    required this.ride,
    required this.passenger,
  });

  @override
  State<ScheduledRideNavigationScreen> createState() => _ScheduledRideNavigationScreenState();
}

class _ScheduledRideNavigationScreenState extends State<ScheduledRideNavigationScreen>
    with TickerProviderStateMixin {
  late ScheduledRideNavigationController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  
  @override
  void initState() {
    super.initState();
    
    // Initialize controller
    controller = Get.put(ScheduledRideNavigationController());
    
    // Initialize with ride and passenger data
    controller.initializeNavigation(widget.ride, widget.passenger);
    
    // Setup animations
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Navigation'),
          backgroundColor: MyColor.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          actions: [
            // Google Maps Button
            Container(
              margin: const EdgeInsets.only(right: Dimensions.space15),
              child: IconButton(
                onPressed: () => controller.openGoogleMaps(),
                icon: Container(
                  padding: const EdgeInsets.all(Dimensions.space8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: GetBuilder<ScheduledRideNavigationController>(
        builder: (controller) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Map View
                  Expanded(
                    flex: 2,
                    child: _buildMapView(),
                  ),
                  
                  // Bottom Navigation Panel
                  Expanded(
                    flex: 1,
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
                        padding: const EdgeInsets.all(Dimensions.space20),
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
                            
                            // Passenger Information
                            _buildPassengerInfoCard(),
                            spaceDown(Dimensions.space15),
                            
                            // Distance and Time Information
                            _buildDistanceTimeCard(),
                            spaceDown(Dimensions.space15),
                            
                            // Action Buttons
                            _buildActionButtons(),
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

  Widget _buildMapView() {
    return GetBuilder<ScheduledRideNavigationController>(
      builder: (controller) {
        if (controller.driverLocation == null || controller.passengerLocation == null) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: controller.driverLocation!,
            zoom: 15.0,
          ),
          markers: controller.markers,
          polylines: controller.polylines,
          onMapCreated: (GoogleMapController mapController) {
            controller.setMapController(mapController);
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
          trafficEnabled: false,
        );
      },
    );
  }

  Widget _buildPassengerInfoCard() {
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
                  Icons.person,
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
                      'Passenger Details',
                      style: boldDefault.copyWith(
                        color: Colors.blue,
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    spaceDown(Dimensions.space2),
                    Text(
                      'Navigation to pickup location',
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
          spaceDown(Dimensions.space15),
          
          // Passenger Info
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  widget.passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
                  style: boldDefault.copyWith(
                    color: Colors.blue,
                    fontSize: Dimensions.fontLarge,
                  ),
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.passenger.user?.firstname ?? ''} ${widget.passenger.user?.lastname ?? ''}',
                      style: boldDefault.copyWith(
                        color: MyColor.colorBlack,
                        fontSize: Dimensions.fontDefault,
                      ),
                    ),
                    spaceDown(Dimensions.space4),
                    Text(
                      '${widget.passenger.seatsBooked ?? '0'} seat(s) • \$${widget.passenger.totalFare ?? '0'}',
                      style: regularDefault.copyWith(
                        color: Colors.grey[600],
                        fontSize: Dimensions.fontSmall,
                      ),
                    ),
                    if (widget.passenger.user?.mobile != null) ...[
                      spaceDown(Dimensions.space2),
                      Text(
                        'Mobile: ${widget.passenger.user!.mobile}',
                        style: regularSmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Pickup Location
          if (widget.passenger.pickupLocation != null && widget.passenger.pickupLocation!.isNotEmpty) ...[
            spaceDown(Dimensions.space15),
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 18),
                  spaceSide(Dimensions.space8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Location',
                          style: regularSmall.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        spaceDown(Dimensions.space2),
                        Text(
                          widget.passenger.pickupLocation!,
                          style: regularDefault.copyWith(
                            color: Colors.green[700],
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
        ],
      ),
    );
  }

  Widget _buildDistanceTimeCard() {
    return GetBuilder<ScheduledRideNavigationController>(
      builder: (controller) {
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
                      Icons.navigation,
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
                          'Navigation Info',
                          style: boldDefault.copyWith(
                            color: Colors.green,
                            fontSize: Dimensions.fontLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        spaceDown(Dimensions.space2),
                        Text(
                          'Real-time distance and time',
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
              spaceDown(Dimensions.space15),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.straighten,
                      'Distance',
                      controller.formattedDistance,
                      Colors.green,
                    ),
                  ),
                  spaceSide(Dimensions.space15),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'ETA',
                      controller.formattedDuration,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
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
            child: Icon(icon, color: color, size: 18),
          ),
          spaceDown(Dimensions.space8),
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
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return GetBuilder<ScheduledRideNavigationController>(
      builder: (controller) {
        return Column(
          children: [
            // Primary Action Buttons Row
            Row(
              children: [
                // Start Pickup / Reached Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: controller.isDriverNearPassenger 
                            ? [Colors.blue, Colors.blue.shade600]
                            : [Colors.green, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                    ),
                    child: TextButton.icon(
                      onPressed: controller.isDriverNearPassenger
                          ? () => controller.markPassengerReached()
                          : () => controller.startPassengerPickup(),
                      icon: Icon(
                        controller.isDriverNearPassenger 
                            ? Icons.location_on 
                            : Icons.directions_car,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        controller.isDriverNearPassenger ? 'Reached' : 'Start Pickup',
                        style: regularDefault.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                spaceSide(Dimensions.space12),
                
                // Cancel Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: TextButton.icon(
                      onPressed: () => controller.showCancelPickupConfirmation(),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                      label: Text(
                        'Cancel',
                        style: regularDefault.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
