import 'package:ezdriver/data/model/global/ride/app_service_model.dart';
import 'package:ezdriver/data/model/global/user/global_driver_model.dart';
import 'package:ezdriver/data/model/location/selected_location_info.dart';

// Passenger model for scheduled rides
class ScheduledRidePassenger {
  String? id;
  String? rideId;
  String? userId;
  String? seatsBooked;
  String? totalFare;
  String? farePerSeat;
  String? note;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  String? distance;
  String? fare;
  String? status; // 0: pending, 1: approved, 2: completed
  String? pickupStatus; // null: not started, "on_way": driver on way, "reached": driver reached, "cancelled": cancelled by driver
  String? paymentStatus; // 0: pending, 1: paid, 2: failed
  String? paymentMethod; // cash, stripe, etc.
  String? driverApproved;
  String? joinedAt;
  String? completedAt;
  String? createdAt;
  String? updatedAt;
  ScheduledRidePassengerUser? user;

  ScheduledRidePassenger({
    this.id,
    this.rideId,
    this.userId,
    this.seatsBooked,
    this.totalFare,
    this.farePerSeat,
    this.note,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distance,
    this.fare,
    this.status,
    this.pickupStatus,
    this.paymentStatus,
    this.paymentMethod,
    this.driverApproved,
    this.joinedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory ScheduledRidePassenger.fromJson(Map<String, dynamic> json) => ScheduledRidePassenger(
        id: json["id"]?.toString(),
        rideId: json["ride_id"]?.toString(),
        userId: json["user_id"]?.toString(),
        seatsBooked: json["seats_booked"]?.toString(),
        totalFare: json["total_fare"]?.toString(),
        farePerSeat: json["fare_per_seat"]?.toString(),
        note: json["note"]?.toString(),
        pickupLocation: json["pickup_location"]?.toString(),
        pickupLatitude: json["pickup_latitude"]?.toString(),
        pickupLongitude: json["pickup_longitude"]?.toString(),
        destination: json["destination"]?.toString(),
        destinationLatitude: json["destination_latitude"]?.toString(),
        destinationLongitude: json["destination_longitude"]?.toString(),
        distance: json["distance"]?.toString(),
        fare: json["fare"]?.toString(),
        status: json["status"]?.toString(),
        pickupStatus: json["pickup_status"]?.toString(),
        paymentStatus: json["payment_status"]?.toString(),
        paymentMethod: json["payment_method"]?.toString(),
        driverApproved: json["driver_approved"]?.toString(),
        joinedAt: json["joined_at"]?.toString(),
        completedAt: json["completed_at"]?.toString(),
        createdAt: json["created_at"]?.toString(),
        updatedAt: json["updated_at"]?.toString(),
        user: json["user"] == null ? null : ScheduledRidePassengerUser.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "ride_id": rideId,
        "user_id": userId,
        "seats_booked": seatsBooked,
        "total_fare": totalFare,
        "fare_per_seat": farePerSeat,
        "note": note,
        "pickup_location": pickupLocation,
        "pickup_latitude": pickupLatitude,
        "pickup_longitude": pickupLongitude,
        "destination": destination,
        "destination_latitude": destinationLatitude,
        "destination_longitude": destinationLongitude,
        "distance": distance,
        "fare": fare,
        "status": status,
        "pickup_status": pickupStatus,
        "payment_status": paymentStatus,
        "payment_method": paymentMethod,
        "driver_approved": driverApproved,
        "joined_at": joinedAt,
        "completed_at": completedAt,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "user": user?.toJson(),
      };
}

// Passenger user model
class ScheduledRidePassengerUser {
  String? id;
  String? firstname;
  String? lastname;
  String? mobile;
  String? rating;

  ScheduledRidePassengerUser({
    this.id,
    this.firstname,
    this.lastname,
    this.mobile,
    this.rating,
  });

  factory ScheduledRidePassengerUser.fromJson(Map<String, dynamic> json) => ScheduledRidePassengerUser(
        id: json["id"]?.toString(),
        firstname: json["firstname"]?.toString(),
        lastname: json["lastname"]?.toString(),
        mobile: json["mobile"]?.toString(),
        rating: json["rating"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "firstname": firstname,
        "lastname": lastname,
        "mobile": mobile,
        "rating": rating,
      };
}

// Vehicle brand model
class VehicleBrand {
  String? id;
  String? name;

  VehicleBrand({
    this.id,
    this.name,
  });

  factory VehicleBrand.fromJson(Map<String, dynamic> json) => VehicleBrand(
        id: json["id"]?.toString(),
        name: json["name"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

// Driver vehicle model
class DriverVehicle {
  String? id;
  String? model;
  String? year;
  String? color;
  String? licensePlate;
  String? capacity;
  VehicleBrand? brand;

  DriverVehicle({
    this.id,
    this.model,
    this.year,
    this.color,
    this.licensePlate,
    this.capacity,
    this.brand,
  });

  factory DriverVehicle.fromJson(Map<String, dynamic> json) => DriverVehicle(
        id: json["id"]?.toString(),
        model: json["model"]?.toString(),
        year: json["year"]?.toString(),
        color: json["color"]?.toString(),
        licensePlate: json["license_plate"]?.toString(),
        capacity: json["capacity"]?.toString(),
        brand: json["brand"] == null ? null : VehicleBrand.fromJson(json["brand"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "model": model,
        "year": year,
        "color": color,
        "license_plate": licensePlate,
        "capacity": capacity,
        "brand": brand?.toJson(),
      };
}

class ScheduledRideModel {
  String? id;
  String? driverId;
  String? serviceId;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  String? scheduledDateTime;
  String? numberOfPassengers;
  String? note;
  String? status; // '0': pending, '1': active, '2': completed, '3': cancelled
  String? statusText; // Human-readable status text
  String? createdAt;
  String? updatedAt;
  String? distance;
  String? duration;
  String? estimatedFare;
  String? availableSeats;
  String? isIntercity;
  String? vehicleId;
  String? brandId;
  String? cancelReason;

  // Related models
  AppService? service;
  GlobalDriverInfo? driver;
  SelectedLocationInfo? pickupLocationInfo;
  SelectedLocationInfo? destinationLocationInfo;
  List<ScheduledRidePassenger>? passengers;

  ScheduledRideModel({
    this.id,
    this.driverId,
    this.serviceId,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.scheduledDateTime,
    this.numberOfPassengers,
    this.note,
    this.status,
    this.statusText,
    this.createdAt,
    this.updatedAt,
    this.distance,
    this.duration,
    this.estimatedFare,
    this.availableSeats,
    this.isIntercity,
    this.vehicleId,
    this.brandId,
    this.cancelReason,
    this.service,
    this.driver,
    this.pickupLocationInfo,
    this.destinationLocationInfo,
    this.passengers,
  });

  factory ScheduledRideModel.fromJson(Map<String, dynamic> json) => ScheduledRideModel(
        id: json["id"]?.toString(),
        driverId: json["driver_id"]?.toString(),
        serviceId: json["service_id"]?.toString(),
        pickupLocation: json["pickup_location"]?.toString(),
        pickupLatitude: json["pickup_latitude"]?.toString(),
        pickupLongitude: json["pickup_longitude"]?.toString(),
        destination: json["destination"]?.toString(),
        destinationLatitude: json["destination_latitude"]?.toString(),
        destinationLongitude: json["destination_longitude"]?.toString(),
        scheduledDateTime: json["scheduled_date_time"]?.toString(),
        numberOfPassengers: json["number_of_passengers"]?.toString(),
        note: json["note"]?.toString(),
        status: json["status"]?.toString(),
        statusText: json["status_text"]?.toString(),
        createdAt: json["created_at"]?.toString(),
        updatedAt: json["updated_at"]?.toString(),
        distance: json["distance"]?.toString(),
        duration: json["duration"]?.toString(),
        estimatedFare: json["estimated_fare"]?.toString(),
        availableSeats: json["available_seats"]?.toString(),
        isIntercity: json["is_intercity"]?.toString(),
        vehicleId: json["vehicle_id"]?.toString(),
        brandId: json["brand_id"]?.toString(),
        cancelReason: json["cancel_reason"]?.toString(),
        service: json["service"] == null ? null : AppService.fromJson(json["service"]),
        driver: json["driver"] == null ? null : GlobalDriverInfo.fromJson(json["driver"]),
        passengers: json["passengers"] == null
            ? []
            : List<ScheduledRidePassenger>.from(
                json["passengers"]!.map((x) => ScheduledRidePassenger.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "driver_id": driverId,
        "service_id": serviceId,
        "pickup_location": pickupLocation,
        "pickup_latitude": pickupLatitude,
        "pickup_longitude": pickupLongitude,
        "destination": destination,
        "destination_latitude": destinationLatitude,
        "destination_longitude": destinationLongitude,
        "scheduled_date_time": scheduledDateTime,
        "number_of_passengers": numberOfPassengers,
        "note": note,
        "status": status,
        "status_text": statusText,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "distance": distance,
        "duration": duration,
        "estimated_fare": estimatedFare,
        "available_seats": availableSeats,
        "is_intercity": isIntercity,
        "vehicle_id": vehicleId,
        "brand_id": brandId,
        "cancel_reason": cancelReason,
        "service": service?.toJson(),
        "driver": driver?.toJson(),
        "passengers": passengers?.map((x) => x.toJson()).toList(),
      };

  ScheduledRideModel copyWith({
    String? id,
    String? driverId,
    String? serviceId,
    String? pickupLocation,
    String? pickupLatitude,
    String? pickupLongitude,
    String? destination,
    String? destinationLatitude,
    String? destinationLongitude,
    String? scheduledDateTime,
    String? numberOfPassengers,
    String? note,
    String? status,
    String? statusText,
    String? createdAt,
    String? updatedAt,
    String? distance,
    String? duration,
    String? estimatedFare,
    String? availableSeats,
    String? isIntercity,
    String? vehicleId,
    String? brandId,
    String? cancelReason,
    AppService? service,
    GlobalDriverInfo? driver,
    SelectedLocationInfo? pickupLocationInfo,
    SelectedLocationInfo? destinationLocationInfo,
    List<ScheduledRidePassenger>? passengers,
  }) {
    return ScheduledRideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      serviceId: serviceId ?? this.serviceId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      destination: destination ?? this.destination,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      numberOfPassengers: numberOfPassengers ?? this.numberOfPassengers,
      note: note ?? this.note,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      availableSeats: availableSeats ?? this.availableSeats,
      isIntercity: isIntercity ?? this.isIntercity,
      vehicleId: vehicleId ?? this.vehicleId,
      brandId: brandId ?? this.brandId,
      cancelReason: cancelReason ?? this.cancelReason,
      service: service ?? this.service,
      driver: driver ?? this.driver,
      pickupLocationInfo: pickupLocationInfo ?? this.pickupLocationInfo,
      destinationLocationInfo: destinationLocationInfo ?? this.destinationLocationInfo,
      passengers: passengers ?? this.passengers,
    );
  }
}

// Response model for scheduled rides list
class ScheduledRideListResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  ScheduledRideListData? data;

  ScheduledRideListResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory ScheduledRideListResponseModel.fromJson(Map<String, dynamic> json) =>
      ScheduledRideListResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : ScheduledRideListData.fromJson(json["data"]),
      );
}

class ScheduledRideListData {
  List<ScheduledRideModel>? scheduledRides;
  ScheduledRideModel? currentScheduledRide;
  String? nextPageUrl;
  String? currentPage;
  String? totalPages;
  String? total;
  String? perPage;
  String? from;
  String? to;
  String? lastPage;
  String? firstPageUrl;
  String? lastPageUrl;
  String? path;
  String? prevPageUrl;
  List<dynamic>? links;

  ScheduledRideListData({
    this.scheduledRides,
    this.currentScheduledRide,
    this.nextPageUrl,
    this.currentPage,
    this.totalPages,
    this.total,
    this.perPage,
    this.from,
    this.to,
    this.lastPage,
    this.firstPageUrl,
    this.lastPageUrl,
    this.path,
    this.prevPageUrl,
    this.links,
  });

  factory ScheduledRideListData.fromJson(Map<String, dynamic> json) {
    // Handle the nested structure where scheduled_rides contains pagination data
    if (json["scheduled_rides"] != null && json["scheduled_rides"] is Map<String, dynamic>) {
      var scheduledRidesData = json["scheduled_rides"];
      return ScheduledRideListData(
        scheduledRides: scheduledRidesData["data"] == null
            ? []
            : List<ScheduledRideModel>.from(
                scheduledRidesData["data"]!.map((x) => ScheduledRideModel.fromJson(x as Map<String, dynamic>))),
        currentScheduledRide: json["current_scheduled_ride"] == null
            ? null
            : ScheduledRideModel.fromJson(json["current_scheduled_ride"] as Map<String, dynamic>),
        nextPageUrl: scheduledRidesData["next_page_url"],
        currentPage: scheduledRidesData["current_page"]?.toString(),
        totalPages: scheduledRidesData["last_page"]?.toString(),
        total: scheduledRidesData["total"]?.toString(),
        perPage: scheduledRidesData["per_page"]?.toString(),
        from: scheduledRidesData["from"]?.toString(),
        to: scheduledRidesData["to"]?.toString(),
        lastPage: scheduledRidesData["last_page"]?.toString(),
        firstPageUrl: scheduledRidesData["first_page_url"],
        lastPageUrl: scheduledRidesData["last_page_url"],
        path: scheduledRidesData["path"],
        prevPageUrl: scheduledRidesData["prev_page_url"],
        links: scheduledRidesData["links"],
      );
    }
    
    // Fallback for direct structure
    return ScheduledRideListData(
      scheduledRides: json["scheduled_rides"] == null
          ? []
          : List<ScheduledRideModel>.from(
              json["scheduled_rides"]!.map((x) => ScheduledRideModel.fromJson(x as Map<String, dynamic>))),
      currentScheduledRide: json["current_scheduled_ride"] == null
          ? null
          : ScheduledRideModel.fromJson(json["current_scheduled_ride"] as Map<String, dynamic>),
      nextPageUrl: json["next_page_url"],
      currentPage: json["current_page"]?.toString(),
      totalPages: json["total_pages"]?.toString(),
    );
  }
}

// Response model for single scheduled ride
class ScheduledRideResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  ScheduledRideModel? data;

  ScheduledRideResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory ScheduledRideResponseModel.fromJson(Map<String, dynamic> json) =>
      ScheduledRideResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : ScheduledRideModel.fromJson(json["data"]),
      );
}

// Response model for pending passengers
class PendingPassengersResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  PendingPassengersData? data;

  PendingPassengersResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory PendingPassengersResponseModel.fromJson(Map<String, dynamic> json) =>
      PendingPassengersResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : PendingPassengersData.fromJson(json["data"]),
      );
}

class PendingPassengersData {
  ScheduledRideModel? ride;
  List<ScheduledRidePassenger>? passengers;

  PendingPassengersData({
    this.ride,
    this.passengers,
  });

  factory PendingPassengersData.fromJson(Map<String, dynamic> json) =>
      PendingPassengersData(
        ride: json["ride"] == null ? null : ScheduledRideModel.fromJson(json["ride"]),
        passengers: json["passengers"] == null
            ? []
            : List<ScheduledRidePassenger>.from(
                json["passengers"]!.map((x) => ScheduledRidePassenger.fromJson(x))),
      );
}

// Response model for approve/reject passenger
class PassengerActionResponseModel {
  String? remark;
  String? status;
  List<String>? message;

  PassengerActionResponseModel({
    this.remark,
    this.status,
    this.message,
  });

  factory PassengerActionResponseModel.fromJson(Map<String, dynamic> json) =>
      PassengerActionResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
      );
}

// Response model for cancel scheduled ride
class CancelScheduledRideResponseModel {
  String? remark;
  String? status;
  List<String>? message;

  CancelScheduledRideResponseModel({
    this.remark,
    this.status,
    this.message,
  });

  factory CancelScheduledRideResponseModel.fromJson(Map<String, dynamic> json) =>
      CancelScheduledRideResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
      );
}

// Response model for complete scheduled ride
class CompleteRideResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  CompleteRideData? data;

  CompleteRideResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory CompleteRideResponseModel.fromJson(Map<String, dynamic> json) =>
      CompleteRideResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : CompleteRideData.fromJson(json["data"]),
      );
}

class CompleteRideData {
  ScheduledRideModel? ride;

  CompleteRideData({
    this.ride,
  });

  factory CompleteRideData.fromJson(Map<String, dynamic> json) =>
      CompleteRideData(
        ride: json["ride"] == null ? null : ScheduledRideModel.fromJson(json["ride"]),
      );
}

// Response model for receive cash payment
class ReceiveCashPaymentResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  ReceiveCashPaymentData? data;

  ReceiveCashPaymentResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory ReceiveCashPaymentResponseModel.fromJson(Map<String, dynamic> json) =>
      ReceiveCashPaymentResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : ReceiveCashPaymentData.fromJson(json["data"]),
      );
}

class ReceiveCashPaymentData {
  ScheduledRidePassenger? passenger;
  String? amountReceived;

  ReceiveCashPaymentData({
    this.passenger,
    this.amountReceived,
  });

  factory ReceiveCashPaymentData.fromJson(Map<String, dynamic> json) =>
      ReceiveCashPaymentData(
        passenger: json["passenger"] == null ? null : ScheduledRidePassenger.fromJson(json["passenger"]),
        amountReceived: json["amount_received"]?.toString(),
      );
}

// Response model for payment summary
class PaymentSummaryResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  PaymentSummaryData? data;

  PaymentSummaryResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory PaymentSummaryResponseModel.fromJson(Map<String, dynamic> json) =>
      PaymentSummaryResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null
            ? []
            : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : PaymentSummaryData.fromJson(json["data"]),
      );
}

class PaymentSummaryData {
  ScheduledRideModel? ride;
  PaymentSummary? paymentSummary;

  PaymentSummaryData({
    this.ride,
    this.paymentSummary,
  });

  factory PaymentSummaryData.fromJson(Map<String, dynamic> json) =>
      PaymentSummaryData(
        ride: json["ride"] == null ? null : ScheduledRideModel.fromJson(json["ride"]),
        paymentSummary: json["payment_summary"] == null ? null : PaymentSummary.fromJson(json["payment_summary"]),
      );
}

class PaymentSummary {
  String? totalPassengers;
  String? confirmedPassengers;
  String? completedPassengers;
  String? paidPassengers;
  String? totalEarnings;
  String? cashEarnings;
  String? stripeEarnings;
  String? pendingPayments;
  List<ScheduledRidePassenger>? passengers;

  PaymentSummary({
    this.totalPassengers,
    this.confirmedPassengers,
    this.completedPassengers,
    this.paidPassengers,
    this.totalEarnings,
    this.cashEarnings,
    this.stripeEarnings,
    this.pendingPayments,
    this.passengers,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) =>
      PaymentSummary(
        totalPassengers: json["total_passengers"]?.toString(),
        confirmedPassengers: json["confirmed_passengers"]?.toString(),
        completedPassengers: json["completed_passengers"]?.toString(),
        paidPassengers: json["paid_passengers"]?.toString(),
        totalEarnings: json["total_earnings"]?.toString(),
        cashEarnings: json["cash_earnings"]?.toString(),
        stripeEarnings: json["stripe_earnings"]?.toString(),
        pendingPayments: json["pending_payments"]?.toString(),
        passengers: json["passengers"] == null
            ? []
            : List<ScheduledRidePassenger>.from(
                json["passengers"]!.map((x) => ScheduledRidePassenger.fromJson(x))),
      );
} 