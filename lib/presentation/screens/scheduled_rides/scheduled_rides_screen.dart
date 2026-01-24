import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/data/services/notification_handler_service.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:ezdriver/presentation/components/text/header_text.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/create_scheduled_ride_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/passenger_requests_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/payment_summary_screen.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/scheduled_ride_detail_screen.dart';

class ScheduledRidesScreen extends StatefulWidget {
  const ScheduledRidesScreen({super.key});

  @override
  State<ScheduledRidesScreen> createState() => _ScheduledRidesScreenState();
}

class _ScheduledRidesScreenState extends State<ScheduledRidesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ensure controller is instantiated
    Get.find<ScheduledRideController>();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    // Add observer to detect when app comes back to foreground
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize notification handler
    _initializeNotificationHandler();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time the screen appears
    _refreshData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshData();
    }
  }

  void _refreshData() {
    if (!_hasInitialized) {
      _hasInitialized = true;
      return; // Skip first call to avoid double loading
    }
    
    // Refresh data when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<ScheduledRideController>();
      controller.refreshData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Scheduled Rides',
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
                  // Enhanced Filter tabs
                  _buildEnhancedFilterTabs(controller),

                  // Current ride in progress card (only show if status is '1' - active)
                  if (controller.currentScheduledRide != null &&
                      controller.currentScheduledRide!.status == '1')
                    _buildCurrentRideCard(controller),
                  
                  // Scheduled rides list
                  Expanded(
                    child: controller.isLoading && controller.scheduledRides.isEmpty
                        ? const Center(child: CustomLoader())
                        : controller.scheduledRides.isEmpty
                            ? _buildEnhancedEmptyState()
                            : _buildEnhancedScheduledRidesList(controller),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildCurrentRideCard(ScheduledRideController controller) {
    final ride = controller.currentScheduledRide!;
    final passengerCounts = controller.getPassengerCountsByStatus(ride);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(Dimensions.space15, 0, Dimensions.space15, Dimensions.space15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Get.to(() => ScheduledRideDetailScreen(ride: ride));
          // Refresh data when returning from detail screen
          final controller = Get.find<ScheduledRideController>();
          controller.refreshData();
        },
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space12),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              spaceSide(Dimensions.space12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ride #${ride.id} - Active',
                            style: boldDefault.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontDefault,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space8,
                            vertical: Dimensions.space4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              spaceSide(Dimensions.space4),
                              Text(
                                'Live',
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
                    spaceDown(Dimensions.space4),
                    Text(
                      '${ride.pickupLocation ?? 'Pickup'} → ${ride.destination ?? 'Destination'}',
                      style: regularSmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    spaceDown(Dimensions.space4),
                    Row(
                      children: [
                        Text(
                          '${passengerCounts['picked_up']}/${passengerCounts['total']} passengers',
                          style: regularSmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        spaceSide(Dimensions.space8),
                        Text(
                          ride.estimatedFare ?? '0',
                          style: regularSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyColor.primaryColor, MyColor.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
        boxShadow: [
          BoxShadow(
            color: MyColor.primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreateScheduledRideScreen())?.then((_) {
            // Refresh data when returning from create screen
            final controller = Get.find<ScheduledRideController>();
            controller.refreshData();
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEnhancedFilterTabs(ScheduledRideController controller) {
    return Container(
      margin: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildEnhancedFilterTab(controller, 'All', 'all', Icons.list_alt),
              _buildEnhancedFilterTab(controller, 'Pending', 'pending', Icons.schedule),
              _buildEnhancedFilterTab(controller, 'Active', 'active', Icons.play_circle_outline),
              _buildEnhancedFilterTab(controller, 'Completed', 'completed', Icons.check_circle_outline),
              _buildEnhancedFilterTab(controller, 'Cancelled', 'cancelled', Icons.cancel_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFilterTab(ScheduledRideController controller, String title, String status, IconData icon) {
    bool isSelected = controller.selectedStatus == status;
    return GestureDetector(
      onTap: () => controller.filterByStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: Dimensions.space8),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.space12, horizontal: Dimensions.space15),
        decoration: BoxDecoration(
          color: isSelected ? MyColor.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            spaceDown(Dimensions.space4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: regularSmall.copyWith(
                color: isSelected ? Colors.white : MyColor.colorBlack,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.space30),
            decoration: BoxDecoration(
              color: MyColor.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_outlined,
              size: 80,
              color: MyColor.primaryColor.withOpacity(0.7),
            ),
          ),
          spaceDown(Dimensions.space25),
          HeaderText(
            text: 'No Scheduled Rides',
            textStyle: boldLarge.copyWith(
              color: MyColor.colorBlack,
              fontSize: Dimensions.fontOverLarge,
            ),
          ),
          spaceDown(Dimensions.space15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.space30),
            child: Text(
              'You haven\'t scheduled any rides yet.\nTap the + button to create your first scheduled ride and start earning.',
              textAlign: TextAlign.center,
              style: regularDefault.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          spaceDown(Dimensions.space30),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space20,
              vertical: Dimensions.space10,
            ),
            decoration: BoxDecoration(
              color: MyColor.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              border: Border.all(
                color: MyColor.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: MyColor.primaryColor,
                  size: 20,
                ),
                spaceSide(Dimensions.space8),
                Text(
                  'Scheduled rides help you plan ahead',
                  style: regularDefault.copyWith(
                    color: MyColor.primaryColor,
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

  Widget _buildEnhancedScheduledRidesList(ScheduledRideController controller) {
    return RefreshIndicator(
      onRefresh: () => controller.loadScheduledRides(refresh: true),
      color: MyColor.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.space15),
        itemCount: controller.scheduledRides.length + (controller.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.scheduledRides.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(Dimensions.space15),
                child: CustomLoader(isPagination: true),
              ),
            );
          }
          
          ScheduledRideModel scheduledRide = controller.scheduledRides[index];
          return _buildEnhancedScheduledRideCard(controller, scheduledRide, index);
        },
      ),
    );
  }

  Widget _buildEnhancedScheduledRideCard(ScheduledRideController controller, ScheduledRideModel scheduledRide, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
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
        onTap: () async {
          await Get.to(() => ScheduledRideDetailScreen(ride: scheduledRide));
          // Refresh data when returning from detail screen
          final controller = Get.find<ScheduledRideController>();
          controller.refreshData();
        },
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header with status
              Row(
                children: [
                  // Service icon with gradient
                  Container(
                    width: 60,
                    height: 60,
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
                    child: scheduledRide.service?.image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            child: Image.network(
                              scheduledRide.service!.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.directions_car,
                                  color: MyColor.primaryColor,
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.directions_car,
                            color: MyColor.primaryColor,
                            size: 30,
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
                                'Ride #${scheduledRide.id}',
                                style: boldDefault.copyWith(
                                  color: MyColor.colorBlack,
                                  fontSize: Dimensions.fontLarge,
                                ),
                              ),
                            ),
                            // Passenger Requests Button
                            if (scheduledRide.status == 'pending' || scheduledRide.status == 'active')
                              GestureDetector(
                                onTap: () {
                                  Get.to(() => PassengerRequestsScreen(ride: scheduledRide));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.space10,
                                    vertical: Dimensions.space6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people, color: Colors.blue, size: 16),
                                      spaceSide(Dimensions.space4),
                                      Text(
                                        'Requests',
                                        style: regularDefault.copyWith(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: Dimensions.fontSmall,
                                        ),
                                      ),
                                      if (controller.hasPendingPassengers(scheduledRide.id!)) ...[
                                        spaceSide(Dimensions.space4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Dimensions.space4,
                                            vertical: Dimensions.space1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                                          ),
                                          child: Text(
                                            '${controller.getPendingPassengersCount(scheduledRide.id!)}',
                                            style: regularSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        spaceDown(Dimensions.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space12,
                            vertical: Dimensions.space6,
                          ),
                          decoration: BoxDecoration(
                            color: controller.getStatusColor(scheduledRide.status ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                            border: Border.all(
                              color: controller.getStatusColor(scheduledRide.status ?? '').withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: controller.getStatusColor(scheduledRide.status ?? ''),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              spaceSide(Dimensions.space6),
                              Text(
                                controller.getStatusText(scheduledRide.status ?? ''),
                                style: regularSmall.copyWith(
                                  color: controller.getStatusColor(scheduledRide.status ?? ''),
                                  fontWeight: FontWeight.w600,
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
              
              spaceDown(Dimensions.space20),
              
              // Enhanced Location details
              _buildEnhancedLocationRow(
                Icons.location_on,
                'Pickup',
                scheduledRide.pickupLocation ?? 'Not specified',
                Colors.green,
              ),
              spaceDown(Dimensions.space12),
              _buildEnhancedLocationRow(
                Icons.location_on_outlined,
                'Destination',
                scheduledRide.destination ?? 'Not specified',
                Colors.red,
              ),
              
              spaceDown(Dimensions.space20),
              
              // Enhanced Ride details grid
              Container(
                padding: const EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedDetailItem(
                            Icons.schedule,
                            'Date & Time',
                            _formatDateTime(scheduledRide.scheduledDateTime),
                          ),
                        ),
                        Expanded(
                          child: _buildEnhancedDetailItem(
                            Icons.people,
                            'Passengers',
                            scheduledRide.numberOfPassengers ?? '0',
                          ),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedDetailItem(
                            Icons.straighten,
                            'Distance',
                            '${scheduledRide.distance ?? '0'} km',
                          ),
                        ),
                        Expanded(
                          child: _buildEnhancedDetailItem(
                            Icons.attach_money,
                            'Estimated Fare',
                            '\$${scheduledRide.estimatedFare ?? '0'}',
                            isFare: true,
                          ),
                        ),
                      ],
                    ),
                    // Add available seats information
                    if (scheduledRide.availableSeats != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Dimensions.space15),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildEnhancedDetailItem(
                                Icons.event_seat,
                                'Available Seats',
                                '${scheduledRide.availableSeats}',
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Passenger information section
              if (scheduledRide.passengers != null && scheduledRide.passengers!.isNotEmpty)
                _buildPassengersSection(controller, scheduledRide),
              
              // Enhanced Action buttons
              if (scheduledRide.status == 'pending' || scheduledRide.status == 'active')
                spaceDown(Dimensions.space20),
              
              if (scheduledRide.status == 'pending' || scheduledRide.status == 'active')
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(color: MyColor.primaryColor),
                              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            ),
                            child: TextButton.icon(
                              onPressed: () {
                                Get.to(() => CreateScheduledRideScreen(scheduledRide: scheduledRide))?.then((_) {
                                  // Refresh data when returning from edit screen
                                  final controller = Get.find<ScheduledRideController>();
                                  controller.refreshData();
                                });
                              },
                              icon: Icon(Icons.edit, color: MyColor.primaryColor, size: 20),
                              label: Text(
                                'Edit',
                                style: regularDefault.copyWith(
                                  color: MyColor.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        spaceSide(Dimensions.space12),
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: scheduledRide.status == 'pending' 
                                    ? [Colors.red, Colors.red.shade600]
                                    : [Colors.green, Colors.green.shade600],
                              ),
                              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            ),
                            child: TextButton.icon(
                              onPressed: controller.isCancelling ? null : () {
                                if (scheduledRide.status == 'pending') {
                                  _showCancelDialog(controller, scheduledRide.id!);
                                } else {
                                  _showCompleteDialog(controller, scheduledRide.id!);
                                }
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
                                  : Icon(
                                      scheduledRide.status == 'pending' ? Icons.cancel : Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              label: Text(
                                controller.isCancelling 
                                    ? 'Cancelling...'
                                    : scheduledRide.status == 'pending' ? 'Cancel' : 'Complete',
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
                    // Payment Summary Button
                    Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.purple.shade600],
                        ),
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          Get.to(() => PaymentSummaryScreen(ride: scheduledRide));
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengersSection(ScheduledRideController controller, ScheduledRideModel scheduledRide) {
    return Container(
      margin: const EdgeInsets.only(top: Dimensions.space20),
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.blue, size: 20),
              spaceSide(Dimensions.space8),
              Text(
                'Passengers (${scheduledRide.passengers!.length})',
                style: regularDefault.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space12),
          ...scheduledRide.passengers!.map((passenger) => _buildPassengerItem(controller, scheduledRide, passenger)),
        ],
      ),
    );
  }

  Widget _buildPassengerItem(ScheduledRideController controller, ScheduledRideModel scheduledRide, ScheduledRidePassenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space8),
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.withOpacity(0.1),
                child: Text(
                  passenger.user?.firstname?.substring(0, 1).toUpperCase() ?? 'P',
                  style: regularDefault.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              spaceSide(Dimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${passenger.user?.firstname ?? ''} ${passenger.user?.lastname ?? ''}',
                      style: regularDefault.copyWith(
                        color: MyColor.colorBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    spaceDown(Dimensions.space4),
                    Text(
                      '${passenger.seatsBooked ?? '0'} seat(s) • \$${passenger.totalFare ?? '0'}',
                      style: regularSmall.copyWith(
                        color: Colors.grey[600],
                      ),
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
                  color: controller.getPassengerStatusColor(passenger.status ?? '0').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                  border: Border.all(
                    color: controller.getPassengerStatusColor(passenger.status ?? '0').withOpacity(0.3),
                  ),
                ),
                child: Text(
                  controller.getPassengerStatusText(passenger.status ?? '0'),
                  style: regularSmall.copyWith(
                    color: controller.getPassengerStatusColor(passenger.status ?? '0'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Action buttons for pending passengers
          if (passenger.status == '0') ...[
            spaceDown(Dimensions.space8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade600],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: TextButton.icon(
                      onPressed: controller.isApproving ? null : () {
                        controller.approvePassenger(scheduledRide.id!, passenger.id!);
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
                        style: regularSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                spaceSide(Dimensions.space8),
                Expanded(
                  child: Container(
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: TextButton.icon(
                      onPressed: controller.isRejecting ? null : () {
                        controller.rejectPassenger(scheduledRide.id!, passenger.id!);
                      },
                      icon: controller.isRejecting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.close, color: Colors.white, size: 16),
                      label: Text(
                        controller.isRejecting ? 'Rejecting...' : 'Reject',
                        style: regularSmall.copyWith(
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
        ],
      ),
    );
  }

  Widget _buildEnhancedLocationRow(IconData icon, String label, String address, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.space6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          spaceSide(Dimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: regularSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                spaceDown(Dimensions.space4),
                Text(
                  address,
                  style: regularDefault.copyWith(
                    color: MyColor.colorBlack,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailItem(IconData icon, String label, String value, {bool isFare = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Dimensions.space6),
          decoration: BoxDecoration(
            color: isFare ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
          ),
          child: Icon(
            icon,
            color: isFare ? Colors.green : Colors.grey[600],
            size: 16,
          ),
        ),
        spaceSide(Dimensions.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: regularSmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: regularDefault.copyWith(
                  color: isFare ? Colors.green : MyColor.colorBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
              Get.back();
              controller.cancelScheduledRide(rideId, reason);
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
              Get.back();
              controller.completeScheduledRide(rideId, note);
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

  // Initialize notification handler
  void _initializeNotificationHandler() {
    // This would typically be called when you receive a notification
    // For example, in your Firebase messaging handler or push notification service
    // Example usage:
    // NotificationHandlerService().handleScheduledRideNotification(notificationPayload);
  }

  // Method to handle incoming notifications
  void handleNotification(Map<String, dynamic> payload) {
    NotificationHandlerService().handleScheduledRideNotification(payload);
  }

  // Method to refresh data when notification is received
  void refreshDataOnNotification() {
    final controller = Get.find<ScheduledRideController>();
    controller.loadScheduledRides(refresh: true);
  }
}
