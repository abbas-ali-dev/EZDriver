import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';

class PassengerBottomSheet extends StatelessWidget {
  final ScheduledRidePassenger passenger;
  final bool isOnboard;
  final VoidCallback? onStartPickup;
  final VoidCallback? onReachedPickup;
  final VoidCallback? onCancelPickup;
  final VoidCallback? onSeeOnMap;
  final VoidCallback? onOpenGoogleMaps;
  final bool showReachedButton;
  final bool showStartPickupButton;
  final bool showCancelPickupButton;
  final bool showSeeOnMapButton;

  const PassengerBottomSheet({
    super.key,
    required this.passenger,
    this.isOnboard = false,
    this.onStartPickup,
    this.onReachedPickup,
    this.onCancelPickup,
    this.onSeeOnMap,
    this.onOpenGoogleMaps,
    this.showReachedButton = false,
    this.showStartPickupButton = true,
    this.showCancelPickupButton = true,
    this.showSeeOnMapButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          
          // Passenger Info Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isOnboard 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                child: Text(
                  passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
                  style: regularDefault.copyWith(
                    color: isOnboard ? Colors.green : Colors.blue,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                            style: boldDefault.copyWith(
                              color: MyColor.colorBlack,
                              fontSize: Dimensions.fontLarge,
                            ),
                          ),
                        ),
                        if (isOnboard)
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
                    spaceDown(Dimensions.space4),
                    Text(
                      '${passenger.seatsBooked ?? '0'} seat(s) • \$${passenger.totalFare ?? '0'}',
                      style: regularDefault.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (passenger.user?.mobile != null) ...[
                      spaceDown(Dimensions.space2),
                      Text(
                        'Mobile: ${passenger.user!.mobile}',
                        style: regularSmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (passenger.user?.rating != null) ...[
                      spaceDown(Dimensions.space2),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          spaceSide(Dimensions.space4),
                          Text(
                            '${passenger.user!.rating}',
                            style: regularSmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space20),
          
          // Pickup Location
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
          
          spaceDown(Dimensions.space20),
          
          // Action buttons
          if (showStartPickupButton || showReachedButton || showCancelPickupButton || showSeeOnMapButton) ...[
            Row(
              children: [
                // Start Pickup Button
                if (showStartPickupButton)
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
                        onPressed: onStartPickup,
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
                
                if (showStartPickupButton && (showReachedButton || showSeeOnMapButton))
                  spaceSide(Dimensions.space10),
                
                // Reached Pickup Button
                if (showReachedButton)
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
                        onPressed: onReachedPickup,
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
                
                if (showReachedButton && showSeeOnMapButton)
                  spaceSide(Dimensions.space10),
                
                // See on Map Button
                if (showSeeOnMapButton)
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.purple.shade600],
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      ),
                      child: TextButton.icon(
                        onPressed: onSeeOnMap,
                        icon: const Icon(Icons.map, color: Colors.white, size: 20),
                        label: Text(
                          'See on Map',
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
            
            if (showCancelPickupButton) ...[
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
                  onPressed: onCancelPickup,
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
            
            // Open Google Maps Button
            spaceDown(Dimensions.space12),
            Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: TextButton.icon(
                onPressed: onOpenGoogleMaps,
                icon: const Icon(Icons.navigation, color: Colors.white, size: 20),
                label: Text(
                  'See on Google Maps',
                  style: regularDefault.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          
          // Close button for onboard passengers (read-only)
          if (isOnboard) ...[
            spaceDown(Dimensions.space12),
            Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                label: Text(
                  'Close',
                  style: regularDefault.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Utility function to show passenger bottom sheet
void showPassengerBottomSheet({
  required ScheduledRidePassenger passenger,
  bool isOnboard = false,
  VoidCallback? onStartPickup,
  VoidCallback? onReachedPickup,
  VoidCallback? onCancelPickup,
  VoidCallback? onSeeOnMap,
  VoidCallback? onOpenGoogleMaps,
  bool showReachedButton = false,
  bool showStartPickupButton = true,
  bool showCancelPickupButton = true,
  bool showSeeOnMapButton = true,
}) {
  // Determine button visibility based on pickupStatus
  bool shouldShowStartPickup = showStartPickupButton;
  bool shouldShowReached = showReachedButton;
  bool shouldShowCancel = showCancelPickupButton;
  
  if (!isOnboard) {
    // For pending/active passengers, use pickupStatus to determine button visibility
    if (passenger.pickupStatus == null) {
      // Not started - show start pickup button
      shouldShowStartPickup = true;
      shouldShowReached = false;
    } else if (passenger.pickupStatus == "on_way") {
      // Driver is on the way - show reached button
      shouldShowStartPickup = false;
      shouldShowReached = true;
    } else if (passenger.pickupStatus == "reached") {
      // Driver has reached - no action buttons needed
      shouldShowStartPickup = false;
      shouldShowReached = false;
    } else if (passenger.pickupStatus == "cancelled") {
      // Cancelled - no action buttons needed
      shouldShowStartPickup = false;
      shouldShowReached = false;
    }
    
    // Cancel button should always be available (except when cancelled)
    shouldShowCancel = passenger.pickupStatus != "cancelled";
  }
  
  Get.bottomSheet(
    PassengerBottomSheet(
      passenger: passenger,
      isOnboard: isOnboard,
      onStartPickup: onStartPickup,
      onReachedPickup: onReachedPickup,
      onCancelPickup: onCancelPickup,
      onSeeOnMap: onSeeOnMap,
      onOpenGoogleMaps: onOpenGoogleMaps,
      showReachedButton: shouldShowReached,
      showStartPickupButton: shouldShowStartPickup,
      showCancelPickupButton: shouldShowCancel,
      showSeeOnMapButton: showSeeOnMapButton,
    ),
    isScrollControlled: true,
  );
}
