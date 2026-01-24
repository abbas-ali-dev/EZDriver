import 'package:ezdriver/core/utils/method.dart';
import 'package:ezdriver/core/utils/url_container.dart';
import 'package:ezdriver/data/model/global/response_model/response_model.dart';
import 'package:ezdriver/data/services/api_service.dart';

class ScheduledRideRepo {
  ApiClient apiClient;
  ScheduledRideRepo({required this.apiClient});

  // Get all scheduled rides for the driver
  Future<ResponseModel> getScheduledRides({String page = '1', String status = ''}) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides";
    if (status.isNotEmpty) {
      url += "?status=$status";
    }
    if (page != '1') {
      url += status.isNotEmpty ? "&page=$page" : "?page=$page";
    }
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Get a specific scheduled ride by ID
  Future<ResponseModel> getScheduledRideById(String id) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$id";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Create a new scheduled ride
  Future<ResponseModel> createScheduledRide(Map<String, String> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Update a scheduled ride
  Future<ResponseModel> updateScheduledRide(String id, Map<String, String> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$id";
    ResponseModel responseModel =
        await apiClient.request(url, Method.updateMethod, params, passHeader: true);
    return responseModel;
  }

  // Delete a scheduled ride
  Future<ResponseModel> deleteScheduledRide(String id) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$id";
    ResponseModel responseModel =
        await apiClient.request(url, Method.deleteMethod, null, passHeader: true);
    return responseModel;
  }

  // Cancel a scheduled ride
  Future<ResponseModel> cancelScheduledRide(String id, String reason) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$id/cancel";
    Map<String, String> params = {'cancel_reason': reason};
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Get driver's vehicles for selection
  Future<ResponseModel> getDriverVehicles() async {
    String url = "${UrlContainer.baseUrl}driver/vehicles";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Get available services for the driver
  Future<ResponseModel> getAvailableServices() async {
    String url = "${UrlContainer.baseUrl}driver/services";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Calculate estimated fare for scheduled ride
  Future<ResponseModel> calculateEstimatedFare(Map<String, String> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/calculate-fare";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Get pending passenger requests for a scheduled ride
  Future<ResponseModel> getPendingPassengers(String scheduledRideId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$scheduledRideId/passengers";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Approve a passenger for a scheduled ride
  Future<ResponseModel> approvePassenger(String scheduledRideId, String passengerId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$scheduledRideId/approve-passenger/$passengerId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, null, passHeader: true);
    return responseModel;
  }

  // Reject a passenger for a scheduled ride
  Future<ResponseModel> rejectPassenger(String scheduledRideId, String passengerId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$scheduledRideId/reject-passenger/$passengerId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, null, passHeader: true);
    return responseModel;
  }

  // Complete a scheduled ride
  Future<ResponseModel> completeScheduledRide(String rideId, Map<String, dynamic> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$rideId/complete";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Receive cash payment from passenger
  Future<ResponseModel> receiveCashPayment(String rideId, String passengerId, Map<String, dynamic> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$rideId/receive-cash-payment/$passengerId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Get payment summary for a scheduled ride
  Future<ResponseModel> getPaymentSummary(String rideId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$rideId/payment-summary";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }

  // Start a scheduled ride
  Future<ResponseModel> startScheduledRide(String rideId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$rideId/start";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, null, passHeader: true);
    return responseModel;
  }

  // Start passenger pickup
  Future<ResponseModel> startPassengerPickup(String rideId, String passengerId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/pickup";
    Map<String, String> params = {
      'ride_id': rideId,
      'passenger_id': passengerId,
    };
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Cancel passenger pickup
  Future<ResponseModel> cancelPassengerPickup(String rideId, String passengerId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/cancel-pickup";
    Map<String, String> params = {
      'ride_id': rideId,
      'passenger_id': passengerId,
    };
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Mark passenger as reached pickup location
  Future<ResponseModel> markPassengerReached(String rideId, String passengerId) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/reached-pickup";
    Map<String, String> params = {
      'ride_id': rideId,
      'passenger_id': passengerId,
    };
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }

  // Update passenger pickup status
  Future<ResponseModel> updatePassengerPickupStatus(String rideId, String passengerId, Map<String, String> params) async {
    String url = "${UrlContainer.baseUrl}driver/scheduled-rides/$rideId/update-pickup-status/$passengerId";
    ResponseModel responseModel =
        await apiClient.request(url, Method.postMethod, params, passHeader: true);
    return responseModel;
  }
} 