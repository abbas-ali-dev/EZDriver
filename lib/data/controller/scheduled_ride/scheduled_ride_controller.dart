import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ezdriver/core/helper/string_format_helper.dart';
import 'package:ezdriver/core/utils/my_strings.dart';
import 'package:ezdriver/data/model/global/response_model/response_model.dart';
import 'package:ezdriver/data/model/scheduled_ride/scheduled_ride_model.dart';
import 'package:ezdriver/data/model/location/selected_location_info.dart';
import 'package:ezdriver/data/model/global/ride/app_service_model.dart';
import 'package:ezdriver/data/repo/scheduled_ride/scheduled_ride_repo.dart';
import 'package:ezdriver/presentation/components/snack_bar/show_custom_snackbar.dart';

class ScheduledRideController extends GetxController {
  ScheduledRideRepo repo;
  ScheduledRideController({required this.repo});

  // Loading states
  bool isLoading = false;
  bool isCreating = false;
  bool isUpdating = false;
  bool isDeleting = false;
  bool isCancelling = false;
  bool isLoadingPassengers = false;
  bool isApproving = false;
  bool isRejecting = false;
  bool isCompleting = false;
  bool isReceivingPayment = false;
  bool isLoadingPaymentSummary = false;
  bool isStarting = false;


  // Data lists
  List<ScheduledRideModel> scheduledRides = [];
  List<AppService> availableServices = [];
  List<DriverVehicle> driverVehicles = [];
  List<ScheduledRidePassenger> pendingPassengers = [];
  ScheduledRideModel? currentScheduledRide;

  // Pagination
  String? nextPageUrl;
  int currentPage = 1;
  bool hasNextPage = false;
  int totalItems = 0;
  int itemsPerPage = 10;

  // Form controllers
  TextEditingController noteController = TextEditingController();
  TextEditingController passengerController = TextEditingController();
  TextEditingController pickupLocationController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  // Selected values
  DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  AppService selectedService = AppService(id: '-1');
  DriverVehicle? selectedVehicle;
  SelectedLocationInfo? pickupLocation;
  SelectedLocationInfo? destinationLocation;
  String selectedStatus = 'all'; // 'all', 'pending', 'active', 'completed', 'cancelled'

  // Estimated fare
  double estimatedFare = 0.0;
  double distance = 0.0;
  double duration = 0.0;

  // Debounce timer for fare calculation
  Timer? _fareCalculationTimer;
  bool _isCalculatingFare = false;

  // Getter for total pages
  int get totalPages => (totalItems / itemsPerPage).ceil();
  
  // Check if we can load more data
  bool get canLoadMore => hasNextPage && !isLoading;
  
  // Load next page
  Future<void> loadNextPage() async {
    if (canLoadMore) {
      await loadScheduledRides();
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await loadScheduledRides(refresh: true);
  }
  


  @override
  void onInit() {
    super.onInit();
    loadScheduledRides();
    loadAvailableServices();
    loadDriverVehicles();
  }

  // Load scheduled rides
  Future<void> loadScheduledRides({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      scheduledRides.clear();
    }

    isLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.getScheduledRides(
        page: currentPage.toString(),
        status: selectedStatus == 'all' ? '' : getApiStatus(selectedStatus),
      );

      if (responseModel.statusCode == 200) {
        ScheduledRideListResponseModel model = ScheduledRideListResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          if (refresh) {
            scheduledRides.clear();
            currentPage = 1;
          }

          // Add rides from API response
          List<ScheduledRideModel> rides = model.data?.scheduledRides ?? [];

          // Apply client-side filtering to ensure correct status filtering
          // This is a safety measure in case backend filtering is not working correctly
          if (selectedStatus != 'all' && selectedStatus.isNotEmpty) {
            String targetStatus = getApiStatus(selectedStatus);
            rides = rides.where((ride) => ride.status == targetStatus).toList();
          }

          scheduledRides.addAll(rides);

          // Set current scheduled ride from API
          currentScheduledRide = model.data?.currentScheduledRide;
          
          nextPageUrl = model.data?.nextPageUrl;
          hasNextPage = nextPageUrl != null && nextPageUrl!.isNotEmpty;
          
          // Update pagination info
          if (model.data?.currentPage != null) {
            currentPage = int.tryParse(model.data!.currentPage!) ?? currentPage;
          }
          if (model.data?.total != null) {
            totalItems = int.tryParse(model.data!.total!) ?? 0;
          }
          if (model.data?.perPage != null) {
            itemsPerPage = int.tryParse(model.data!.perPage!) ?? 10;
          }
          
          currentPage++;
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isLoading = false;
    update();
  }

  // Load available services
  Future<void> loadAvailableServices() async {
    try {
      ResponseModel responseModel = await repo.getAvailableServices();
      if (responseModel.statusCode == 200) {
        // Parse services response
        var jsonData = jsonDecode(responseModel.responseJson);
        if (jsonData['status'] == MyStrings.success) {
          availableServices.clear();
          List<dynamic> services = jsonData['data']['services'] ?? [];
          for (var service in services) {
            availableServices.add(AppService.fromJson(service));
          }
        }
      }
    } catch (e) {
      printX(e);
    }
    update();
  }

  // Load driver vehicles
  Future<void> loadDriverVehicles() async {
    try {
      ResponseModel responseModel = await repo.getDriverVehicles();
      if (responseModel.statusCode == 200) {
        // Parse vehicles response
        var jsonData = jsonDecode(responseModel.responseJson);
        if (jsonData['status'] == MyStrings.success) {
          driverVehicles.clear();
          List<dynamic> vehicles = jsonData['data']['vehicles'] ?? [];
          for (var vehicle in vehicles) {
            driverVehicles.add(DriverVehicle.fromJson(vehicle));
          }
        }
      }
    } catch (e) {
      printX(e);
    }
    update();
  }

  // Load specific scheduled ride by ID (gets all passengers with coordinates)
  Future<void> loadScheduledRideById(String scheduledRideId) async {
    try {
      ResponseModel responseModel = await repo.getScheduledRideById(scheduledRideId);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);
        if (jsonData['status'] == MyStrings.success) {
          print('=== API RESPONSE STRUCTURE ===');
          print('Has data.ride: ${jsonData['data']?['ride'] != null}');
          print('Has data.data: ${jsonData['data']?['data'] != null}');

          // Handle both possible response structures
          Map<String, dynamic>? rideData;
          if (jsonData['data']?['ride'] != null) {
            rideData = jsonData['data']['ride'];
          } else if (jsonData['data']?['data'] != null) {
            rideData = jsonData['data']['data'];
          }

          if (rideData != null) {
            print('=== PARSING RIDE DATA ===');
            print('Raw passengers: ${rideData['passengers']}');

            ScheduledRideModel updatedRide = ScheduledRideModel.fromJson(rideData);
            currentScheduledRide = updatedRide;

            // Also update the ride in scheduledRides list
            int index = scheduledRides.indexWhere((ride) => ride.id == scheduledRideId);
            if (index != -1) {
              scheduledRides[index] = updatedRide;
            }

            print('=== REFRESHED RIDE DATA ===');
            print('Ride ID: ${updatedRide.id}');
            print('Total passengers: ${updatedRide.passengers?.length ?? 0}');
            if (updatedRide.passengers != null) {
              for (var p in updatedRide.passengers!) {
                print('  Passenger: ${p.user?.firstname}, status=${p.status}, lat=${p.pickupLatitude}, lng=${p.pickupLongitude}');
              }
            }
            print('========================');
          } else {
            print('ERROR: Could not find ride data in response');
          }
        }
      }
    } catch (e) {
      printX('Error loading scheduled ride by ID: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    update();
  }

  // Load pending passengers for a scheduled ride
  Future<void> loadPendingPassengers(String scheduledRideId) async {
    isLoadingPassengers = true;
    update();

    try {
      ResponseModel responseModel = await repo.getPendingPassengers(scheduledRideId);
      if (responseModel.statusCode == 200) {
        PendingPassengersResponseModel model = PendingPassengersResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          pendingPassengers = model.data?.passengers ?? [];
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isLoadingPassengers = false;
    update();
  }

  // Get pending passengers count for a specific ride
  int getPendingPassengersCount(String rideId) {
    return pendingPassengers.where((passenger) =>
        passenger.status == '0' && passenger.rideId == rideId).length;
  }

  // Get all pending passengers count
  int getTotalPendingPassengersCount() {
    return pendingPassengers.where((passenger) => passenger.status == '0').length;
  }

  // Check if a ride has pending passengers
  bool hasPendingPassengers(String rideId) {
    return getPendingPassengersCount(rideId) > 0;
  }

  // Check if a ride can be cancelled
  bool canCancelRide(String status) {
    // Can only cancel pending rides
    return status == '0' || status == 'pending';
  }

  // Check if a ride can be completed
  bool canCompleteRide(String status) {
    // Can complete active rides
    return status == '1' || status == 'active';
  }

  // Check if a ride can be started
  // Allow starting any pending ride at any time (before or after scheduled time)
  bool canStartRide(String status, String? scheduledDateTime) {
    print('=== canStartRide DEBUG ===');
    print('Status: $status');
    print('Scheduled DateTime: $scheduledDateTime');

    // Can start pending rides - allow at any time
    if (status != '0' && status != 'pending') {
      print('Cannot start: Status is not pending (status: $status)');
      return false;
    }

    print('Can start: Status is pending, allowing driver to start ride at any time');
    return true;

    // OLD LOGIC - Commented out as per user request to allow starting at any time
    /*
    if (scheduledDateTime == null) {
      print('Cannot start: Scheduled date time is null');
      return false;
    }

    try {
      final scheduledTime = DateTime.parse(scheduledDateTime);
      final now = DateTime.now();
      // Allow starting 15 minutes before scheduled time
      final startTime = scheduledTime.subtract(const Duration(minutes: 15));

      print('Scheduled Time: $scheduledTime');
      print('Current Time: $now');
      print('Start Time (15 min before): $startTime');
      print('Can start (now.isAfter(startTime)): ${now.isAfter(startTime)}');

      return now.isAfter(startTime);
    } catch (e) {
      print('Cannot start: Error parsing date - $e');
      return false;
    }
    */
  }

  // Format date time for display
  String formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Not specified';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  // Approve a passenger for a scheduled ride
  Future<void> approvePassenger(String scheduledRideId, String passengerId) async {
    isApproving = true;
    update();

    try {
      ResponseModel responseModel = await repo.approvePassenger(scheduledRideId, passengerId);
      if (responseModel.statusCode == 200) {
        PassengerActionResponseModel model = PassengerActionResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Passenger approved successfully']);
          // Reload passengers list and refresh ride data with all passengers
          await Future.wait([
            loadPendingPassengers(scheduledRideId),
            loadScheduledRideById(scheduledRideId), // Get full ride data with passenger coordinates
          ]);
          // Refresh main scheduled rides list to get updated data
          loadScheduledRides(refresh: true);
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isApproving = false;
    update();
  }

  // Reject a passenger for a scheduled ride
  Future<void> rejectPassenger(String scheduledRideId, String passengerId) async {
    isRejecting = true;
    update();

    try {
      ResponseModel responseModel = await repo.rejectPassenger(scheduledRideId, passengerId);
      if (responseModel.statusCode == 200) {
        PassengerActionResponseModel model = PassengerActionResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Passenger rejected successfully']);
          // Reload passengers list and refresh ride data
          await Future.wait([
            loadPendingPassengers(scheduledRideId),
            loadScheduledRideById(scheduledRideId), // Get full ride data
          ]);
          // Refresh main scheduled rides list to get updated data
          loadScheduledRides(refresh: true);
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isRejecting = false;
    update();
  }

  // Calculate estimated fare with debouncing
  Future<void> calculateEstimatedFare() async {
    // Cancel any pending calculation
    _fareCalculationTimer?.cancel();

    // Schedule new calculation after 500ms delay
    _fareCalculationTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performFareCalculation();
    });
  }

  // Internal method that performs the actual API call
  Future<void> _performFareCalculation() async {
    if (pickupLocation == null || destinationLocation == null || selectedService.id == '-1') {
      print('=== FARE CALCULATION SKIPPED ===');
      print('Pickup: ${pickupLocation != null}');
      print('Destination: ${destinationLocation != null}');
      print('Service ID: ${selectedService.id}');
      return;
    }

    // Prevent duplicate calls if already calculating
    if (_isCalculatingFare) {
      print('Fare calculation already in progress, skipping...');
      return;
    }

    _isCalculatingFare = true;

    try {
      Map<String, String> params = {
        'pickup_latitude': pickupLocation!.latitude.toString(),
        'pickup_longitude': pickupLocation!.longitude.toString(),
        'destination_latitude': destinationLocation!.latitude.toString(),
        'destination_longitude': destinationLocation!.longitude.toString(),
        'service_id': selectedService.id!,
        'number_of_passengers': passengerController.text.isEmpty ? '1' : passengerController.text,
        'scheduled_date_time': selectedDateTime.toIso8601String(),
      };

      print('=== FARE CALCULATION REQUEST ===');
      print('Params: $params');

      ResponseModel responseModel = await repo.calculateEstimatedFare(params);

      print('=== FARE CALCULATION RESPONSE ===');
      print('Status Code: ${responseModel.statusCode}');

      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);
        if (jsonData['status'] == MyStrings.success) {
          // Backend returns numeric values (not strings), handle both types
          var fareValue = jsonData['data']['estimated_fare'];
          var distanceValue = jsonData['data']['distance'];
          var durationValue = jsonData['data']['duration'];

          // Convert to double, handling both numeric and string types
          estimatedFare = fareValue is num ? fareValue.toDouble() : double.tryParse(fareValue?.toString() ?? '0') ?? 0.0;
          distance = distanceValue is num ? distanceValue.toDouble() : double.tryParse(distanceValue?.toString() ?? '0') ?? 0.0;
          duration = durationValue is num ? durationValue.toDouble() : double.tryParse(durationValue?.toString() ?? '0') ?? 0.0;

          print('=== PARSED FARE DATA ===');
          print('Estimated Fare: \$${estimatedFare.toStringAsFixed(2)}');
          print('Distance: ${distance.toStringAsFixed(2)} km');
          print('Duration: ${duration.toStringAsFixed(0)} min');
        } else {
          print('ERROR: API returned non-success status: ${jsonData['status']}');
          print('Message: ${jsonData['message']}');
        }
      } else {
        print('ERROR: API call failed with status code: ${responseModel.statusCode}');
        print('Message: ${responseModel.message}');
      }
    } catch (e) {
      printX('ERROR in calculateEstimatedFare: $e');
    } finally {
      _isCalculatingFare = false;
    }
    update();
  }

  // Create scheduled ride
  Future<void> createScheduledRide() async {
    if (!validateForm()) return;

    isCreating = true;
    update();

    try {
      Map<String, String> params = {
        'service_id': selectedService.id!,
        'vehicle_id': selectedVehicle?.id ?? '',
        'pickup_location': pickupLocation!.getFullAddress(showFull: true),
        'pickup_latitude': pickupLocation!.latitude.toString(),
        'pickup_longitude': pickupLocation!.longitude.toString(),
        'destination': destinationLocation!.getFullAddress(showFull: true),
        'destination_latitude': destinationLocation!.latitude.toString(),
        'destination_longitude': destinationLocation!.longitude.toString(),
        'scheduled_date_time': selectedDateTime.toIso8601String(),
        'number_of_passengers': passengerController.text,
        'note': noteController.text,
        'estimated_fare': estimatedFare.toString(),
        'distance': distance.toString(),
        'duration': duration.toString(),
      };

      ResponseModel responseModel = await repo.createScheduledRide(params);
      if (responseModel.statusCode == 200) {
        ScheduledRideResponseModel model = ScheduledRideResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Scheduled ride created successfully']);
          clearForm();
          loadScheduledRides(refresh: true);
          Get.back(); // Close the create screen
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isCreating = false;
    update();
  }

  // Update scheduled ride
  Future<void> updateScheduledRide(String id) async {
    if (!validateForm()) return;

    isUpdating = true;
    update();

    try {
      Map<String, String> params = {
        'service_id': selectedService.id!,
        'vehicle_id': selectedVehicle?.id ?? '',
        'pickup_location': pickupLocation!.getFullAddress(showFull: true),
        'pickup_latitude': pickupLocation!.latitude.toString(),
        'pickup_longitude': pickupLocation!.longitude.toString(),
        'destination': destinationLocation!.getFullAddress(showFull: true),
        'destination_latitude': destinationLocation!.latitude.toString(),
        'destination_longitude': destinationLocation!.longitude.toString(),
        'scheduled_date_time': selectedDateTime.toIso8601String(),
        'number_of_passengers': passengerController.text,
        'note': noteController.text,
        'estimated_fare': estimatedFare.toString(),
        'distance': distance.toString(),
        'duration': duration.toString(),
      };

      ResponseModel responseModel = await repo.updateScheduledRide(id, params);
      if (responseModel.statusCode == 200) {
        ScheduledRideResponseModel model = ScheduledRideResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));

        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Scheduled ride updated successfully']);
          loadScheduledRides(refresh: true);
          Get.back();
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isUpdating = false;
    update();
  }

  // Delete scheduled ride
  Future<void> deleteScheduledRide(String id) async {
    isDeleting = true;
    update();

    try {
      ResponseModel responseModel = await repo.deleteScheduledRide(id);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);
        if (jsonData['status'] == MyStrings.success) {
          CustomSnackBar.success(successList: ['Scheduled ride deleted successfully']);
          loadScheduledRides(refresh: true);
        } else {
          CustomSnackBar.error(
              errorList: jsonData['message'] ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isDeleting = false;
    update();
  }

  // Cancel scheduled ride
  Future<void> cancelScheduledRide(String id, String reason, {VoidCallback? onSuccess}) async {
    isCancelling = true;
    update();

    try {
      ResponseModel responseModel = await repo.cancelScheduledRide(id, reason);
      if (responseModel.statusCode == 200) {
        CancelScheduledRideResponseModel model = CancelScheduledRideResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));
        
        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Scheduled ride cancelled successfully']);
          loadScheduledRides(refresh: true);
          
          // Pop back to listings if callback provided
          if (onSuccess != null) {
            onSuccess();
          }
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isCancelling = false;
    update();
  }

  // Complete scheduled ride
  Future<void> completeScheduledRide(String rideId, String? completionNote, {VoidCallback? onSuccess}) async {
    isCompleting = true;
    update();

    try {
      Map<String, dynamic> params = {};
      if (completionNote != null && completionNote.isNotEmpty) {
        params['completion_note'] = completionNote;
      }

      ResponseModel responseModel = await repo.completeScheduledRide(rideId, params);
      if (responseModel.statusCode == 200) {
        CompleteRideResponseModel model = CompleteRideResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));
        
        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Scheduled ride completed successfully']);
          loadScheduledRides(refresh: true);
          
          // Pop back to listings if callback provided
          if (onSuccess != null) {
            onSuccess();
          }
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isCompleting = false;
    update();
  }

  // Start scheduled ride
  Future<void> startScheduledRide(String rideId, {VoidCallback? onSuccess}) async {
    isStarting = true;
    update();

    try {
      ResponseModel responseModel = await repo.startScheduledRide(rideId);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);

        if (jsonData['status'] == MyStrings.success) {
          // Convert message to List<String>
          List<String> messages = [];
          if (jsonData['message'] != null) {
            if (jsonData['message'] is List) {
              messages = (jsonData['message'] as List).map((e) => e.toString()).toList();
            } else {
              messages = [jsonData['message'].toString()];
            }
          } else {
            messages = ['Scheduled ride started successfully'];
          }

          CustomSnackBar.success(successList: messages);
          loadScheduledRides(refresh: true);

          // Pop back to listings if callback provided
          if (onSuccess != null) {
            onSuccess();
          }
        } else {
          // Convert error message to List<String>
          List<String> errorMessages = [];
          if (jsonData['message'] != null) {
            if (jsonData['message'] is List) {
              errorMessages = (jsonData['message'] as List).map((e) => e.toString()).toList();
            } else {
              errorMessages = [jsonData['message'].toString()];
            }
          } else {
            errorMessages = [MyStrings.somethingWentWrong];
          }

          CustomSnackBar.error(errorList: errorMessages);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [e.toString()]);
    }

    isStarting = false;
    update();
  }

  // Receive cash payment from passenger
  Future<void> receiveCashPayment(String rideId, String passengerId, double amount, String? note) async {
    isReceivingPayment = true;
    update();

    try {
      Map<String, dynamic> params = {
        'amount_received': amount,
      };
      
      if (note != null && note.isNotEmpty) {
        params['payment_note'] = note;
      }

      ResponseModel responseModel = await repo.receiveCashPayment(rideId, passengerId, params);
      if (responseModel.statusCode == 200) {
        ReceiveCashPaymentResponseModel model = ReceiveCashPaymentResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));
        
        if (model.status == MyStrings.success) {
          CustomSnackBar.success(successList: model.message ?? ['Cash payment received successfully']);
          loadPendingPassengers(rideId);
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isReceivingPayment = false;
    update();
  }

  // Update passenger pickup status
  Future<void> updatePassengerPickupStatus(String rideId, String passengerId, String status) async {
    try {
      Map<String, String> params = {
        'pickup_status': status, // 'on_way', 'reached', 'cancelled'
      };

      ResponseModel responseModel = await repo.updatePassengerPickupStatus(rideId, passengerId, params);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);

        if (jsonData['status'] == MyStrings.success) {
          String message = 'Passenger notified';
          if (status == 'reached') {
            message = 'Passenger has been notified of your arrival';
          } else if (status == 'on_way') {
            message = 'Passenger notified that you are on the way';
          }
          CustomSnackBar.success(successList: [message]);

          // Reload passengers to update status
          loadPendingPassengers(rideId);
        } else {
          CustomSnackBar.error(
              errorList: jsonData['message'] ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }
    update();
  }

  // Mark passenger as reached - Notify the rider app user that driver has arrived
  Future<void> markPassengerReached(String rideId, String passengerId, {VoidCallback? onSuccess}) async {
    try {
      printX('📍 Marking passenger as reached - Ride: $rideId, Passenger: $passengerId');

      ResponseModel responseModel = await repo.markPassengerReached(rideId, passengerId);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);

        if (jsonData['status'] == MyStrings.success) {
          printX('✅ Successfully marked passenger as reached');

          // Show success message
          String message = jsonData['message'] is List
              ? (jsonData['message'] as List).join(', ')
              : jsonData['message'] ?? 'Passenger has been notified of your arrival';

          CustomSnackBar.success(successList: [message]);

          // The backend should send a Pusher notification to the rider
          printX('📡 Backend should send Pusher notification to rider');
          printX('📡 Expected Pusher event: driver_arrived on channel: private-scheduled-ride-$rideId');

          // Reload passengers to update status
          loadPendingPassengers(rideId);

          // Call success callback if provided
          if (onSuccess != null) {
            onSuccess();
          }
        } else {
          printX('❌ Failed to mark passenger as reached: ${jsonData['message']}');
          CustomSnackBar.error(
              errorList: jsonData['message'] ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        printX('❌ API Error: ${responseModel.statusCode} - ${responseModel.message}');
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX('❌ Exception in markPassengerReached: $e');
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }
    update();
  }

  // Get payment summary for a scheduled ride
  Future<PaymentSummary?> getPaymentSummary(String rideId) async {
    isLoadingPaymentSummary = true;
    update();

    try {
      ResponseModel responseModel = await repo.getPaymentSummary(rideId);
      if (responseModel.statusCode == 200) {
        PaymentSummaryResponseModel model = PaymentSummaryResponseModel.fromJson(
            jsonDecode(responseModel.responseJson));
        
        if (model.status == MyStrings.success) {
          return model.data?.paymentSummary;
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }

    isLoadingPaymentSummary = false;
    update();
    return null;
  }

  // Form validation
  bool validateForm() {
    if (pickupLocation == null) {
      CustomSnackBar.error(errorList: ['Please select pickup location']);
      return false;
    }
    if (destinationLocation == null) {
      CustomSnackBar.error(errorList: ['Please select destination']);
      return false;
    }
    if (selectedService.id == null || selectedService.id == '-1') {
      CustomSnackBar.error(errorList: ['Please select a service']);
      return false;
    }
    if (selectedVehicle == null) {
      CustomSnackBar.error(errorList: ['Please select a vehicle']);
      return false;
    }
    if (passengerController.text.isEmpty) {
      CustomSnackBar.error(errorList: ['Please enter number of passengers']);
      return false;
    }
    if (selectedDateTime.isBefore(DateTime.now())) {
      CustomSnackBar.error(errorList: ['Scheduled time cannot be in the past']);
      return false;
    }
    return true;
  }

  // Clear form
  void clearForm() {
    noteController.clear();
    passengerController.clear();
    pickupLocationController.clear();
    destinationController.clear();
    selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    selectedService = AppService(id: '-1');
    selectedVehicle = null;
    pickupLocation = null;
    destinationLocation = null;
    estimatedFare = 0.0;
    distance = 0.0;
    duration = 0.0;
    update();
  }

  // Load form data for editing
  void loadFormData(ScheduledRideModel scheduledRide) {
    noteController.text = scheduledRide.note ?? '';
    passengerController.text = scheduledRide.numberOfPassengers ?? '';
    pickupLocationController.text = scheduledRide.pickupLocation ?? '';
    destinationController.text = scheduledRide.destination ?? '';
    
    if (scheduledRide.scheduledDateTime != null) {
      selectedDateTime = DateTime.parse(scheduledRide.scheduledDateTime!);
    }
    
    selectedService = scheduledRide.service ?? AppService(id: '-1');
    estimatedFare = double.tryParse(scheduledRide.estimatedFare ?? '0') ?? 0.0;
    distance = double.tryParse(scheduledRide.distance ?? '0') ?? 0.0;
    duration = double.tryParse(scheduledRide.duration ?? '0') ?? 0.0;
    
    update();
  }

  // Set pickup location
  void setPickupLocation(SelectedLocationInfo location) {
    pickupLocation = location;
    pickupLocationController.text = location.getFullAddress(showFull: true);
    if (destinationLocation != null && selectedService.id != '-1') {
      calculateEstimatedFare();
    }
    update();
  }

  // Set destination location
  void setDestinationLocation(SelectedLocationInfo location) {
    destinationLocation = location;
    destinationController.text = location.getFullAddress(showFull: true);
    if (pickupLocation != null && selectedService.id != '-1') {
      calculateEstimatedFare();
    }
    update();
  }

  // Select service
  void selectService(AppService service) {
    selectedService = service;
    if (pickupLocation != null && destinationLocation != null) {
      calculateEstimatedFare();
    }
    update();
  }

  // Select vehicle
  void selectVehicle(DriverVehicle vehicle) {
    selectedVehicle = vehicle;
    update();
  }

  // Select date time
  void selectDateTime(DateTime dateTime) {
    selectedDateTime = dateTime;
    if (pickupLocation != null && destinationLocation != null && selectedService.id != '-1') {
      calculateEstimatedFare();
    }
    update();
  }

  // Filter by status
  void filterByStatus(String status) {
    selectedStatus = status;
    loadScheduledRides(refresh: true);
  }
  
  // Convert display status to API status
  String getApiStatus(String displayStatus) {
    switch (displayStatus) {
      case 'pending':
        return '0';
      case 'active':
        return '1';
      case 'completed':
        return '2';
      case 'cancelled':
        return '3';
      default:
        return '';
    }
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.green;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status text
  String getStatusText(String status) {
    switch (status) {
      case '0':
        return 'Pending';
      case '1':
        return 'Active';
      case '2':
        return 'Completed';
      case '3':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Get passenger status color
  Color getPassengerStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.green;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get passenger status text
  String getPassengerStatusText(String status) {
    switch (status) {
      case '0':
        return 'Pending';
      case '1':
        return 'Approved';
      case '2':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  // Get passenger pickup status
  String getPassengerPickupStatus(String status) {
    switch (status) {
      case '0':
        return 'Not Picked Up';
      case '1':
        return 'Picked Up';
      case '2':
        return 'Dropped Off';
      default:
        return 'Unknown';
    }
  }

  // Get passenger pickup status color
  Color getPassengerPickupStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.blue;
      case '2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get passengers count by status
  Map<String, int> getPassengerCountsByStatus(ScheduledRideModel ride) {
    if (ride.passengers == null) return {'total': 0, 'picked_up': 0, 'remaining': 0};
    
    int total = ride.passengers!.length;
    int pickedUp = ride.passengers!.where((p) => p.status == '1').length;
    int remaining = total - pickedUp;
    
    return {'total': total, 'picked_up': pickedUp, 'remaining': remaining};
  }

  // Get selected passenger count
  int getSelectedPassengerCount() {
    return int.tryParse(passengerController.text) ?? 1;
  }

  // Get available passenger options
  List<int> getAvailablePassengerOptions() {
    return [1, 2, 3, 4, 5, 6, 7, 8];
  }

  // Set passenger count
  void setPassengerCount(int count) {
    passengerController.text = count.toString();
    update();
  }

  // Start passenger pickup
  Future<void> startPassengerPickup(String rideId, String passengerId) async {
    try {
      ResponseModel responseModel = await repo.startPassengerPickup(rideId, passengerId);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);
        
        if (jsonData['status'] == MyStrings.success) {
          CustomSnackBar.success(successList: jsonData['message'] ?? ['Pickup started successfully']);
          // Reload passengers list
          loadPendingPassengers(rideId);
        } else {
          CustomSnackBar.error(
              errorList: jsonData['message'] ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }
  }

  // Cancel passenger pickup
  Future<void> cancelPassengerPickup(String rideId, String passengerId) async {
    try {
      ResponseModel responseModel = await repo.cancelPassengerPickup(rideId, passengerId);
      if (responseModel.statusCode == 200) {
        var jsonData = jsonDecode(responseModel.responseJson);
        
        if (jsonData['status'] == MyStrings.success) {
          CustomSnackBar.success(successList: jsonData['message'] ?? ['Pickup cancelled successfully']);
          // Remove passenger from the ride's passenger list
          _removePassengerFromRide(rideId, passengerId);
          // Reload passengers list
          loadPendingPassengers(rideId);
        } else {
          CustomSnackBar.error(
              errorList: jsonData['message'] ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
    }
  }

  // Helper method to remove passenger from ride
  void _removePassengerFromRide(String rideId, String passengerId) {
    // Remove from current scheduled ride
    if (currentScheduledRide != null && currentScheduledRide!.id == rideId) {
      currentScheduledRide!.passengers?.removeWhere((passenger) => passenger.id == passengerId);
    }
    
    // Remove from scheduled rides list
    for (var ride in scheduledRides) {
      if (ride.id == rideId) {
        ride.passengers?.removeWhere((passenger) => passenger.id == passengerId);
        break;
      }
    }
    
    // Remove from pending passengers
    pendingPassengers.removeWhere((passenger) => passenger.id == passengerId);

    update();
  }

  @override
  void onClose() {
    // Cancel any pending fare calculation timers
    _fareCalculationTimer?.cancel();
    super.onClose();
  }

}
