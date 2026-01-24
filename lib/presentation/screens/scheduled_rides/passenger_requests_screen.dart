import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ezdriver/core/route/route.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/bottom_sheets/passenger_bottom_sheet.dart';
import 'package:ezdriver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';

class PassengerRequestsScreen extends StatefulWidget {
  final ScheduledRideModel ride;
  
  const PassengerRequestsScreen({
    super.key, 
    required this.ride,
  });

  @override
  State<PassengerRequestsScreen> createState() => _PassengerRequestsScreenState();
}

class _PassengerRequestsScreenState extends State<PassengerRequestsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Ensure controller is instantiated
    Get.find<ScheduledRideController>();

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
    
    // Load pending passengers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<ScheduledRideController>();
      controller.loadPendingPassengers(widget.ride.id!);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Passengers',
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
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.loadPendingPassengers(widget.ride.id!);
                },
                color: MyColor.primaryColor,
                child: CustomScrollView(
                  slivers: [
                    // Ride Summary Header
                    SliverToBoxAdapter(
                      child: _buildRideSummaryHeader(controller),
                    ),
                    
                    // Passengers Content
                    if (controller.isLoadingPassengers)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(Dimensions.space50),
                            child: CustomLoader(),
                          ),
                        ),
                      )
                    else
                      _buildPassengersContent(controller),
                    
                    // Bottom padding
                    SliverToBoxAdapter(
                      child: SizedBox(height: Dimensions.space20),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Get count of onboard passengers (approved passengers)
  int _getOnboardPassengersCount() {
    if (widget.ride.passengers == null) return 0;
    return widget.ride.passengers!.where((passenger) => passenger.status == '1').length;
  }

  // Get list of onboard passengers
  List<ScheduledRidePassenger> _getOnboardPassengers() {
    if (widget.ride.passengers == null) return [];
    return widget.ride.passengers!.where((passenger) => passenger.status == '1').toList();
  }

  // Build passengers content with both onboard and pending sections
  Widget _buildPassengersContent(ScheduledRideController controller) {
    final onboardPassengers = _getOnboardPassengers();
    final pendingPassengers = controller.pendingPassengers;
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          int currentIndex = 0;
          
          // Onboard Passengers Section
          if (onboardPassengers.isNotEmpty) {
            if (index == currentIndex) {
              return _buildPassengerSectionHeader('Onboard Passengers', Colors.green, Icons.check_circle);
            }
            currentIndex++;
            
            if (index >= currentIndex && index < currentIndex + onboardPassengers.length) {
              final passengerIndex = index - currentIndex;
              return _buildOnboardPassengerCard(controller, onboardPassengers[passengerIndex]);
            }
            currentIndex += onboardPassengers.length;
            
            // Add spacing after onboard passengers
            if (index == currentIndex) {
              return const SizedBox(height: Dimensions.space20);
            }
            currentIndex++;
          }
          
          // Pending Passengers Section
          if (pendingPassengers.isNotEmpty) {
            if (index == currentIndex) {
              return _buildPassengerSectionHeader('Pending Requests', Colors.orange, Icons.schedule);
            }
            currentIndex++;
            
            if (index >= currentIndex && index < currentIndex + pendingPassengers.length) {
              final passengerIndex = index - currentIndex;
              return _buildPassengerRequestCard(controller, pendingPassengers[passengerIndex]);
            }
            currentIndex += pendingPassengers.length;
          }
          
          // Empty state if no passengers at all
          if (onboardPassengers.isEmpty && pendingPassengers.isEmpty) {
            if (index == currentIndex) {
              return _buildEmptyState();
            }
          }
          
          return null;
        },
        childCount: _getTotalPassengerItemsCount(controller),
      ),
    );
  }

  // Get total count of items to display
  int _getTotalPassengerItemsCount(ScheduledRideController controller) {
    final onboardPassengers = _getOnboardPassengers();
    final pendingPassengers = controller.pendingPassengers;
    
    int count = 0;
    
    // Onboard section
    if (onboardPassengers.isNotEmpty) {
      count += 1; // Section header
      count += onboardPassengers.length; // Passenger cards
      count += 1; // Spacing
    }
    
    // Pending section
    if (pendingPassengers.isNotEmpty) {
      count += 1; // Section header
      count += pendingPassengers.length; // Passenger cards
    }
    
    // Empty state
    if (onboardPassengers.isEmpty && pendingPassengers.isEmpty) {
      count += 1;
    }
    
    return count;
  }

  // Build section header for passenger types
  Widget _buildPassengerSectionHeader(String title, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.space15, Dimensions.space10, Dimensions.space15, Dimensions.space5),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space12,
        vertical: Dimensions.space8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          spaceSide(Dimensions.space8),
          Text(
            title,
            style: boldDefault.copyWith(
              color: color,
              fontSize: Dimensions.fontDefault,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideSummaryHeader(ScheduledRideController controller) {
    return Container(
      margin: const EdgeInsets.all(Dimensions.space15),
      padding: const EdgeInsets.all(Dimensions.space20),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MyColor.primaryColor.withOpacity(0.1),
                      MyColor.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: MyColor.primaryColor,
                  size: 25,
                ),
              ),
              spaceSide(Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride #${widget.ride.id}',
                      style: boldDefault.copyWith(
                        color: MyColor.colorBlack,
                        fontSize: Dimensions.fontLarge,
                      ),
                    ),
                    spaceDown(Dimensions.space4),
                    Text(
                      '${widget.ride.pickupLocation ?? 'Not specified'} → ${widget.ride.destination ?? 'Not specified'}',
                      style: regularDefault.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Onboard passengers count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space8,
                      vertical: Dimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_getOnboardPassengersCount()} Onboard',
                      style: regularSmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  spaceSide(Dimensions.space8),
                  // Pending passengers count
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space8,
                      vertical: Dimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${controller.pendingPassengers.length} Pending',
                      style: regularSmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildRideInfoItem(
                  Icons.schedule,
                  'Date & Time',
                  _formatDateTime(widget.ride.scheduledDateTime),
                ),
              ),
              Expanded(
                child: _buildRideInfoItem(
                  Icons.attach_money,
                  'Estimated Fare',
                  '\$${widget.ride.estimatedFare ?? '0'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerRequestCard(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.space15, vertical: Dimensions.space8),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Passenger Info Header
          Container(
            padding: const EdgeInsets.all(Dimensions.space20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.largeRadius),
                topRight: Radius.circular(Dimensions.largeRadius),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
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
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          spaceSide(Dimensions.space4),
                          Text(
                            passenger.user?.rating ?? 'N/A',
                            style: regularSmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          if (passenger.user?.mobile != null) ...[
                            spaceSide(Dimensions.space15),
                            Icon(Icons.phone, color: Colors.grey[600], size: 16),
                            spaceSide(Dimensions.space4),
                            Text(
                              passenger.user!.mobile!,
                              style: regularSmall.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space8,
                    vertical: Dimensions.space4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      spaceSide(Dimensions.space4),
                      Text(
                        'Pending',
                        style: regularSmall.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Passenger Details
          Padding(
            padding: const EdgeInsets.all(Dimensions.space20),
            child: Column(
              children: [
                // Booking Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.event_seat,
                        'Seats Booked',
                        passenger.seatsBooked ?? '0',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.attach_money,
                        'Total Fare',
                        '\$${passenger.totalFare ?? '0'}',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Pickup Location
                if (passenger.pickupLocation != null && passenger.pickupLocation!.isNotEmpty) ...[
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
                        Icon(Icons.location_on, color: Colors.green, size: 20),
                        spaceSide(Dimensions.space10),
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
                                passenger.pickupLocation!,
                                style: regularDefault.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (passenger.pickupLatitude != null && passenger.pickupLongitude != null)
                          GestureDetector(
                            onTap: () => _showLocationOnMap(
                              passenger.pickupLocation!,
                              double.tryParse(passenger.pickupLatitude!) ?? 0.0,
                              double.tryParse(passenger.pickupLongitude!) ?? 0.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(Dimensions.space8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                              ),
                              child: Icon(
                                Icons.map,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                
                // Passenger Note
                if (passenger.note != null && passenger.note!.isNotEmpty) ...[
                  spaceDown(Dimensions.space15),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange, size: 20),
                        spaceSide(Dimensions.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Passenger Note',
                                style: regularSmall.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              spaceDown(Dimensions.space2),
                              Text(
                                passenger.note!,
                                style: regularDefault.copyWith(
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action Buttons
                spaceDown(Dimensions.space20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        ),
                        child: TextButton.icon(
                          onPressed: controller.isRejecting ? null : () {
                            _showRejectConfirmationDialog(controller, passenger);
                          },
                          icon: controller.isRejecting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.close, color: Colors.red, size: 20),
                          label: Text(
                            controller.isRejecting ? 'Rejecting...' : 'Reject',
                            style: regularDefault.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    spaceSide(Dimensions.space15),
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
                          onPressed: controller.isApproving ? null : () {
                            _showApproveConfirmationDialog(controller, passenger);
                          },
                          icon: controller.isApproving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.check, color: Colors.white, size: 20),
                          label: Text(
                            controller.isApproving ? 'Approving...' : 'Approve',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build onboard passenger card (approved passengers)
  Widget _buildOnboardPassengerCard(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.space15, Dimensions.space5, Dimensions.space15, Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          showPassengerBottomSheet(
            passenger: passenger,
            isOnboard: passenger.status == "1",
            showStartPickupButton: false,
            showReachedButton: false,
            showCancelPickupButton: false,
            onSeeOnMap: () {
              Get.back(); // Close the bottom sheet first
              Get.toNamed(
                RouteHelper.passengerMapScreen,
                arguments: {
                  'passenger': passenger,
                  'rideId': widget.ride.id ?? '',
                },
              );
            },
            onOpenGoogleMaps: () async {
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
              
              // Create Google Maps URL with directions
              final String googleMapsUrl = 
                  'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving';
              
              try {
                if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                  await launchUrl(
                    Uri.parse(googleMapsUrl),
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
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Could not open maps application',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
          );
        },
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        child: Column(
        children: [
          // Passenger Info Header
          Container(
            padding: const EdgeInsets.all(Dimensions.space20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.largeRadius),
                topRight: Radius.circular(Dimensions.largeRadius),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  child: Text(
                    passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
                    style: regularDefault.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: Dimensions.fontOverLarge,
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
                          fontSize: Dimensions.fontOverLarge,
                        ),
                      ),
                      spaceDown(Dimensions.space4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          spaceSide(Dimensions.space4),
                          Text(
                            passenger.user?.rating ?? 'N/A',
                            style: regularDefault.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (passenger.user?.mobile != null) ...[
                            spaceSide(Dimensions.space15),
                            Icon(Icons.phone, color: Colors.grey[600], size: 18),
                            spaceSide(Dimensions.space4),
                            Text(
                              passenger.user!.mobile!,
                              style: regularDefault.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space12,
                    vertical: Dimensions.space6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      spaceSide(Dimensions.space6),
                      Text(
                        'Onboard',
                        style: regularDefault.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Passenger Details
          Padding(
            padding: const EdgeInsets.all(Dimensions.space20),
            child: Column(
              children: [
                // Booking Details
                Row(
                  children: [
                    Expanded(
                      child: _buildPassengerDetailItem(
                        Icons.event_seat,
                        'Seats Booked',
                        passenger.seatsBooked ?? '0',
                        Colors.blue,
                      ),
                    ),
                    spaceSide(Dimensions.space15),
                    Expanded(
                      child: _buildPassengerDetailItem(
                        Icons.attach_money,
                        'Total Fare',
                        '\$${passenger.totalFare ?? '0'}',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Pickup Location
                if (passenger.pickupLocation != null && passenger.pickupLocation!.isNotEmpty) ...[
                  spaceDown(Dimensions.space15),
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
                        spaceSide(Dimensions.space10),
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
                                passenger.pickupLocation!,
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
                
                // Passenger Note
                if (passenger.note != null && passenger.note!.isNotEmpty) ...[
                  spaceDown(Dimensions.space15),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange, size: 20),
                        spaceSide(Dimensions.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Passenger Note',
                                style: regularSmall.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              spaceDown(Dimensions.space2),
                              Text(
                                passenger.note!,
                                style: regularDefault.copyWith(
                                  color: Colors.orange[700],
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
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(Dimensions.space15),
      padding: const EdgeInsets.all(Dimensions.space50),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            spaceDown(Dimensions.space20),
            Text(
              'No Passengers',
              style: boldLarge.copyWith(
                color: Colors.grey[600],
                fontSize: Dimensions.fontOverLarge,
              ),
            ),
            spaceDown(Dimensions.space10),
            Text(
              'There are no passengers onboard or pending requests for this ride.',
              textAlign: TextAlign.center,
              style: regularDefault.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        spaceDown(Dimensions.space8),
        Text(
          label,
          style: regularSmall.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        spaceDown(Dimensions.space4),
        Text(
          value,
          style: regularDefault.copyWith(
            color: MyColor.colorBlack,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPassengerDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          spaceDown(Dimensions.space6),
          Text(
            label,
            style: regularSmall.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          spaceDown(Dimensions.space2),
          Text(
            value,
            style: regularDefault.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          spaceDown(Dimensions.space8),
          Text(
            label,
            style: regularSmall.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          spaceDown(Dimensions.space4),
          Text(
            value,
            style: regularDefault.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLocationOnMap(String location, double latitude, double longitude) {
    // TODO: Implement map view
    Get.snackbar(
      'Location',
      'Opening map for: $location',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showApproveConfirmationDialog(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Approve Passenger'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve ${passenger.user?.firstname ?? 'this passenger'} for your ride?',
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
            onPressed: controller.isApproving ? null : () {
              Get.back();
              controller.approvePassenger(widget.ride.id!, passenger.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isApproving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Approve',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmationDialog(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        title: Row(
          children: [
            Icon(Icons.close, color: Colors.red, size: 24),
            spaceSide(Dimensions.space8),
            const Text('Reject Passenger'),
          ],
        ),
        content: Text(
          'Are you sure you want to reject ${passenger.user?.firstname ?? 'this passenger'}? This action cannot be undone.',
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
            onPressed: controller.isRejecting ? null : () {
              Get.back();
              controller.rejectPassenger(widget.ride.id!, passenger.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
            ),
            child: controller.isRejecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Not specified';
    try {
      DateTime dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
