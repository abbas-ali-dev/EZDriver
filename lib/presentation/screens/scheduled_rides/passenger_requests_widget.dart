import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ezdriver/core/route/route.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/bottom_sheets/passenger_bottom_sheet.dart';
import 'package:ezdriver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';

class PassengerRequestsWidget extends StatelessWidget {
  final ScheduledRideController controller;
  final ScheduledRideModel ride;

  const PassengerRequestsWidget({
    super.key,
    required this.controller,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.people, color: Colors.blue, size: 24),
              spaceSide(Dimensions.space10),
              Text(
                'Passengers',
                style: boldLarge.copyWith(
                  color: MyColor.getRideTitleColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: Dimensions.fontOverLarge,
                ),
              ),
              const Spacer(),
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
          spaceDown(Dimensions.space20),
          
          // Refresh button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: TextButton.icon(
                    onPressed: controller.isLoadingPassengers ? null : () {
                      controller.loadPendingPassengers(ride.id!);
                    },
                    icon: controller.isLoadingPassengers
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.refresh, color: Colors.blue, size: 18),
                    label: Text(
                      controller.isLoadingPassengers ? 'Loading...' : 'Refresh Requests',
                      style: regularDefault.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),
          
          // Passengers content
          if (controller.isLoadingPassengers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.space30),
                child: CustomLoader(),
              ),
            )
          else
            _buildPassengersContent(controller),
        ],
      ),
    );
  }

  // Get count of onboard passengers (approved passengers)
  int _getOnboardPassengersCount() {
    if (ride.passengers == null) return 0;
    return ride.passengers!.where((passenger) => passenger.status == '1').length;
  }

  // Get list of onboard passengers
  List<ScheduledRidePassenger> _getOnboardPassengers() {
    if (ride.passengers == null) return [];
    return ride.passengers!.where((passenger) => passenger.status == '1').toList();
  }

  // Build passengers content with both onboard and pending sections
  Widget _buildPassengersContent(ScheduledRideController controller) {
    final onboardPassengers = _getOnboardPassengers();
    final pendingPassengers = controller.pendingPassengers;
    
    return Column(
      children: [
        // Onboard Passengers Section
        if (onboardPassengers.isNotEmpty) ...[
          _buildPassengerSectionHeader('Onboard Passengers', Colors.green, Icons.check_circle),
          spaceDown(Dimensions.space10),
          ...onboardPassengers.map((passenger) => 
            _buildOnboardPassengerCard(controller, passenger)
          ),
          spaceDown(Dimensions.space20),
        ],
        
        // Pending Passengers Section
        if (pendingPassengers.isNotEmpty) ...[
          _buildPassengerSectionHeader('Pending Requests', Colors.orange, Icons.schedule),
          spaceDown(Dimensions.space10),
          ...pendingPassengers.map((passenger) => 
            _buildPassengerRequestCard(controller, passenger)
          ),
        ],
        
        // Empty state if no passengers at all
        if (onboardPassengers.isEmpty && pendingPassengers.isEmpty)
          _buildEmptyPassengerRequests(),
      ],
    );
  }

  // Build section header for passenger types
  Widget _buildPassengerSectionHeader(String title, Color color, IconData icon) {
    return Container(
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

  Widget _buildEmptyPassengerRequests() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space30),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
          spaceDown(Dimensions.space15),
          Text(
            'No Passengers',
            style: boldLarge.copyWith(
              color: Colors.grey[600],
              fontSize: Dimensions.fontLarge,
            ),
          ),
          spaceDown(Dimensions.space8),
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
    );
  }

  Widget _buildPassengerRequestCard(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Passenger Info Header
          Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.mediumRadius),
                topRight: Radius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.withOpacity(0.2),
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
            padding: const EdgeInsets.all(Dimensions.space15),
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
                  spaceDown(Dimensions.space12),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space10),
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
                  spaceDown(Dimensions.space12),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange, size: 18),
                        spaceSide(Dimensions.space8),
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
                spaceDown(Dimensions.space15),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        ),
                        child: TextButton.icon(
                          onPressed: controller.isRejecting ? null : () {
                            _showRejectConfirmationDialog(controller, ride.id!, passenger.id!);
                          },
                          icon: controller.isRejecting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.close, color: Colors.red, size: 16),
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
                    spaceSide(Dimensions.space12),
                    Expanded(
                      child: Container(
                        height: 40,
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
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.check, color: Colors.white, size: 16),
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

  Widget _buildPassengerDetailItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space10),
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

  // Build onboard passenger card (approved passengers)
  Widget _buildOnboardPassengerCard(ScheduledRideController controller, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
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
                  'rideId': ride.id ?? '',
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
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        child: Column(
        children: [
          // Passenger Info Header
          Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.mediumRadius),
                topRight: Radius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green.withOpacity(0.2),
                  child: Text(
                    passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
                    style: regularDefault.copyWith(
                      color: Colors.green,
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      spaceSide(Dimensions.space4),
                      Text(
                        'Onboard',
                        style: regularSmall.copyWith(
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
            padding: const EdgeInsets.all(Dimensions.space15),
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
                  spaceDown(Dimensions.space12),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space10),
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
                  spaceDown(Dimensions.space12),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange, size: 18),
                        spaceSide(Dimensions.space8),
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
              controller.approvePassenger(ride.id!, passenger.id!);
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

  void _showRejectConfirmationDialog(ScheduledRideController controller, String rideId, String passengerId) {
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
        content: const Text('Are you sure you want to reject this passenger? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No, Keep',
              style: regularDefault.copyWith(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: controller.isRejecting ? null : () {
              Get.back();
              controller.rejectPassenger(rideId, passengerId);
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
                    'Yes, Reject',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
