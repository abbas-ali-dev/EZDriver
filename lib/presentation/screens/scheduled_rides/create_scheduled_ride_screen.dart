import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ezdriver/core/utils/dimensions.dart';
import 'package:ezdriver/core/utils/my_color.dart';
import 'package:ezdriver/core/utils/style.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/model/location/selected_location_info.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ezdriver/presentation/components/divider/custom_spacer.dart';
import 'package:ezdriver/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ezdriver/presentation/components/text/header_text.dart';
import 'package:ezdriver/presentation/components/text-form-field/custom_text_field.dart';
import 'package:ezdriver/presentation/screens/scheduled_rides/map_selection_screen.dart';

class CreateScheduledRideScreen extends StatefulWidget {
  final ScheduledRideModel? scheduledRide;
  const CreateScheduledRideScreen({super.key, this.scheduledRide});

  bool get isEditing => scheduledRide != null;

  @override
  State<CreateScheduledRideScreen> createState() => _CreateScheduledRideScreenState();
}

class _CreateScheduledRideScreenState extends State<CreateScheduledRideScreen>
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

    // Load form data if editing
    if (widget.isEditing && widget.scheduledRide != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Get.find<ScheduledRideController>();
        controller.loadFormData(widget.scheduledRide!);
      });
    }
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
        title: widget.isEditing ? 'Edit Scheduled Ride' : 'Create Scheduled Ride',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.space15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Service Selection
                    _buildEnhancedServiceSelection(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Vehicle Selection
                    _buildEnhancedVehicleSelection(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Location Selection
                    _buildEnhancedLocationSelection(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Date & Time Selection
                    _buildEnhancedDateTimeSelection(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Passenger Count
                    _buildEnhancedPassengerCount(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Notes
                    _buildEnhancedNotes(controller),
                    spaceDown(Dimensions.space25),
                    
                    // Estimated Fare
                    if (controller.estimatedFare > 0)
                      _buildEnhancedEstimatedFare(controller),
                    
                    spaceDown(Dimensions.space30),
                    
                    // Submit Button
                    _buildEnhancedSubmitButton(controller),
                    spaceDown(Dimensions.space20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(ScheduledRideController controller) {
    int completedSteps = 0;
    if (controller.selectedService.id != '-1') completedSteps++;
    if (controller.selectedVehicle != null) completedSteps++;
    if (controller.pickupLocation != null) completedSteps++;
    if (controller.destinationLocation != null) completedSteps++;
    if (controller.selectedDateTime != DateTime.now().add(const Duration(hours: 1))) completedSteps++;
    if (controller.passengerController.text.isNotEmpty) completedSteps++;

    double progress = completedSteps / 6.0;

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Setup Progress',
                style: boldDefault.copyWith(
                  color: MyColor.colorBlack,
                  fontSize: Dimensions.fontMedium,
                ),
              ),
              Text(
                '$completedSteps/6',
                style: regularDefault.copyWith(
                  color: MyColor.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(MyColor.primaryColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedServiceSelection(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Select Service Type',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'Choose the type of service you want to offer',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: controller.availableServices.length,
            itemBuilder: (context, index) {
              var service = controller.availableServices[index];
              bool isSelected = controller.selectedService.id == service.id;
              
              return GestureDetector(
                onTap: () => controller.selectService(service),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 120,
                  margin: const EdgeInsets.only(right: Dimensions.space12),
                  decoration: BoxDecoration(
                    color: MyColor.colorWhite,
                    borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                    border: Border.all(
                      color: isSelected ? MyColor.primaryColor : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: MyColor.primaryColor.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? MyColor.primaryColor.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        ),
                        child: service.image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                                child: Image.network(
                                  service.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.directions_car,
                                      color: isSelected ? MyColor.primaryColor : Colors.grey[400],
                                      size: 30,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.directions_car,
                                color: isSelected ? MyColor.primaryColor : Colors.grey[400],
                                size: 30,
                              ),
                      ),
                      spaceDown(Dimensions.space8),
                      Text(
                        service.name ?? 'Unknown',
                        style: regularDefault.copyWith(
                          color: isSelected ? MyColor.primaryColor : MyColor.colorBlack,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: Dimensions.space4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space8,
                            vertical: Dimensions.space2,
                          ),
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusHuge),
                          ),
                          child: Text(
                            'Selected',
                            style: regularSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedVehicleSelection(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Select Your Vehicle',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'Choose the vehicle you\'ll use for this ride',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        Container(
          decoration: BoxDecoration(
            color: MyColor.colorWhite,
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DriverVehicle>(
              value: controller.selectedVehicle,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, color: Colors.grey[400]),
                    spaceSide(Dimensions.space10),
                    Text(
                      'Select your vehicle',
                      style: regularDefault.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              items: controller.driverVehicles.map<DropdownMenuItem<DriverVehicle>>((vehicle) {
                return DropdownMenuItem<DriverVehicle>(
                  value: vehicle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Dimensions.space6),
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: MyColor.primaryColor,
                            size: 20,
                          ),
                        ),
                        spaceSide(Dimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vehicle.model ?? 'Unknown Model',
                                style: regularDefault.copyWith(
                                  color: MyColor.colorBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${vehicle.year ?? ''} • ${vehicle.color ?? ''}',
                                style: regularSmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (DriverVehicle? value) {
                if (value != null) {
                  controller.selectVehicle(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLocationSelection(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Set Pickup & Destination',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'Select pickup and destination locations from the map',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        
        // Pickup Location
        _buildLocationField(
          scheduledRideController: controller,
          textController: controller.pickupLocationController,
          label: 'Pickup Location',
          hint: 'Select pickup location',
          icon: Icons.location_on,
          color: Colors.green,
          onTap: () => _showLocationPicker(context, controller, isPickup: true),
        ),
        
        spaceDown(Dimensions.space15),
        
        // Destination Location
        _buildLocationField(
          scheduledRideController: controller,
          textController: controller.destinationController,
          label: 'Destination',
          hint: 'Select destination',
          icon: Icons.location_on_outlined,
          color: Colors.red,
          onTap: () => _showLocationPicker(context, controller, isPickup: false),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required ScheduledRideController scheduledRideController,
    required TextEditingController textController,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                ),
                child: Icon(icon, color: color, size: 20),
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
                    spaceDown(Dimensions.space2),
                    Text(
                      textController.text.isEmpty ? hint : textController.text,
                      style: regularDefault.copyWith(
                        color: textController.text.isEmpty ? Colors.grey[500] : MyColor.colorBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.map,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, ScheduledRideController controller, {required bool isPickup}) {
    // Show a bottom sheet with map selection options
    Get.bottomSheet(
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
            HeaderText(
              text: 'Select ${isPickup ? 'Pickup' : 'Destination'} Location',
              textStyle: boldLarge.copyWith(
                color: MyColor.colorBlack,
                fontSize: Dimensions.fontOverLarge,
              ),
            ),
            spaceDown(Dimensions.space20),
            
            // Current Location Option
            _buildLocationOption(
              icon: Icons.my_location,
              title: 'Use Current Location',
              subtitle: 'Automatically detect your current location',
              onTap: () async {
                Get.back();
                await _setCurrentLocation(controller, isPickup);
              },
            ),
            
            spaceDown(Dimensions.space12),
            
            // Map Selection Option
            _buildLocationOption(
              icon: Icons.map,
              title: 'Select on Map',
              subtitle: 'Pick location directly from the map',
              onTap: () {
                Get.back();
                _showMapSelection(controller, isPickup);
              },
            ),
            
            spaceDown(Dimensions.space20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.space8),
              decoration: BoxDecoration(
                color: MyColor.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
              ),
              child: Icon(icon, color: MyColor.primaryColor, size: 20),
            ),
            spaceSide(Dimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: regularDefault.copyWith(
                      color: MyColor.colorBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  spaceDown(Dimensions.space2),
                  Text(
                    subtitle,
                    style: regularSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCurrentLocation(ScheduledRideController controller, bool isPickup) async {
    try {
      // Show loading indicator
      Get.snackbar(
        'Getting Location',
        'Fetching your current location...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        CustomSnackBar.error(errorList: ['Location services are disabled. Please enable location services.']);
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomSnackBar.error(errorList: ['Location permission denied. Please grant location permission.']);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        CustomSnackBar.error(errorList: ['Location permission permanently denied. Please enable in app settings.']);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        
        // Create location info from real GPS data
        var currentLocation = SelectedLocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
          placeName: 'Current Location',
          address: placemark.street ?? placemark.subThoroughfare ?? '',
          city: placemark.locality ?? placemark.administrativeArea ?? '',
          country: placemark.country ?? '',
          fullAddress: '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}'.replaceAll(RegExp(r',\s*,+'), ',').replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
        );
        
        // Set the location in controller
        if (isPickup) {
          controller.setPickupLocation(currentLocation);
        } else {
          controller.setDestinationLocation(currentLocation);
        }

        // Show success message
        Get.snackbar(
          'Location Set',
          'Current location set as ${isPickup ? 'pickup' : 'destination'}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        CustomSnackBar.error(errorList: ['Unable to get address for current location.']);
      }
    } catch (e) {
      print('Error getting current location: $e');
      CustomSnackBar.error(errorList: ['Failed to get current location. Please try again.']);
    }
  }



  void _showMapSelection(ScheduledRideController controller, bool isPickup) {
    Get.to(() => MapSelectionScreen(
      isPickup: isPickup,
      onLocationSelected: (SelectedLocationInfo location) {
        if (isPickup) {
          controller.setPickupLocation(location);
        } else {
          controller.setDestinationLocation(location);
        }
      },
    ));
  }

  Widget _buildEnhancedDateTimeSelection(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Schedule Date & Time',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'Choose when you want to start this ride',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: controller.selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: MyColor.primaryColor,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (pickedDate != null) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(controller.selectedDateTime),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: MyColor.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedTime != null) {
                DateTime selectedDateTime = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                controller.selectDateTime(selectedDateTime);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: MyColor.colorWhite,
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.space8),
                  decoration: BoxDecoration(
                    color: MyColor.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Icon(Icons.schedule, color: MyColor.primaryColor, size: 20),
                ),
                spaceSide(Dimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Time',
                        style: regularSmall.copyWith(
                          color: MyColor.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      spaceDown(Dimensions.space2),
                      Text(
                        _formatDateTime(controller.selectedDateTime),
                        style: regularDefault.copyWith(
                          color: MyColor.colorBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPassengerCount(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Number of Passengers',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'How many passengers can you accommodate?',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          ),
          child: DropdownButtonFormField<int>(
            value: controller.getSelectedPassengerCount(),
            decoration: InputDecoration(
              labelText: 'Number of Passengers',
              hintText: 'Select number of passengers',
              prefixIcon: Icon(Icons.people, color: MyColor.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space15,
                vertical: Dimensions.space12,
              ),
            ),
            items: controller.getAvailablePassengerOptions().map((int count) {
              return DropdownMenuItem<int>(
                value: count,
                child: Text(
                  '$count ${count == 1 ? 'Passenger' : 'Passengers'}',
                  style: regularDefault.copyWith(
                    color: MyColor.colorBlack,
                  ),
                ),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                controller.setPassengerCount(newValue);
                if (controller.pickupLocation != null && 
                    controller.destinationLocation != null && 
                    controller.selectedService.id != '-1') {
                  controller.calculateEstimatedFare();
                }
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Please select number of passengers';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedNotes(ScheduledRideController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(
          text: 'Additional Notes',
          textStyle: boldLarge.copyWith(
            color: MyColor.getRideTitleColor(),
            fontWeight: FontWeight.w600,
            fontSize: Dimensions.fontOverLarge,
          ),
        ),
        spaceDown(Dimensions.space5),
        Text(
          'Add any special instructions or notes (optional)',
          style: regularDefault.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space15),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.space15,
            vertical: Dimensions.space12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          ),
          child: CustomTextField(
            controller: controller.noteController,
            labelText: 'Notes',
            hintText: 'Add any additional notes (optional)',
            maxLines: 3,
            onChanged: (value) {},
            prefixIcon: Icon(Icons.note, color: MyColor.primaryColor),
            isborderNone: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedEstimatedFare(ScheduledRideController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space20),
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
        border: Border.all(color: MyColor.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: MyColor.primaryColor,
                size: 24,
              ),
              spaceSide(Dimensions.space8),
              HeaderText(
                text: 'Estimated Fare',
                textStyle: boldDefault.copyWith(
                  color: MyColor.primaryColor,
                  fontSize: Dimensions.fontLarge,
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildFareItem('Distance', '${controller.distance.toStringAsFixed(1)} km'),
              ),
              Expanded(
                child: _buildFareItem('Duration', '${controller.duration.toStringAsFixed(0)} min'),
              ),
              Expanded(
                child: _buildFareItem('Fare', '\$${controller.estimatedFare.toStringAsFixed(2)}', isFare: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareItem(String label, String value, {bool isFare = false}) {
    return Column(
      children: [
        Text(
          label,
          style: regularSmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        spaceDown(Dimensions.space4),
        Text(
          value,
          style: boldDefault.copyWith(
            color: isFare ? Colors.green : MyColor.colorBlack,
            fontSize: isFare ? Dimensions.fontLarge : Dimensions.fontMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSubmitButton(ScheduledRideController controller) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyColor.primaryColor, MyColor.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (widget.isEditing && widget.scheduledRide != null) {
            controller.updateScheduledRide(widget.scheduledRide!.id!);
          } else {
            controller.createScheduledRide();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          ),
        ),
        child: widget.isEditing 
            ? (controller.isUpdating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Update Scheduled Ride',
                    style: boldDefault.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontMedium,
                    ),
                  ))
            : (controller.isCreating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Create Scheduled Ride',
                    style: boldDefault.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontMedium,
                    ),
                  )),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 