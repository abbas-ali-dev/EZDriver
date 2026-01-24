class AppService {
  String? id;
  String? name;
  String? code;
  String? image;
  String? imageWithPath;
  String? cityMinFare;
  String? cityMaxFare;
  String? cityRecommendFare;
  String? cityFareCommission;
  String? intercityMinFare;
  String? intercityMaxFare;
  String? intercityRecommendFare;
  String? intercityFareCommission;
  String? status;
  String? createdAt;
  String? updatedAt;

  AppService({
    this.id,
    this.name,
    this.code,
    this.image,
    this.imageWithPath,
    this.cityMinFare,
    this.cityMaxFare,
    this.cityRecommendFare,
    this.cityFareCommission,
    this.intercityMinFare,
    this.intercityMaxFare,
    this.intercityRecommendFare,
    this.intercityFareCommission,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AppService.fromJson(Map<String, dynamic> json) => AppService(
        id: json["id"]?.toString(),
        name: json["name"],
        code: json["code"],
        image: json["image"],
        imageWithPath: json["image_with_path"],
        cityMinFare: json["city_min_fare"]?.toString(),
        cityMaxFare: json["city_max_fare"]?.toString(),
        cityRecommendFare: json["city_recommend_fare"]?.toString(),
        cityFareCommission: json["city_fare_commission"]?.toString(),
        intercityMinFare: json["intercity_min_fare"]?.toString(),
        intercityMaxFare: json["intercity_max_fare"]?.toString(),
        intercityRecommendFare: json["intercity_recommend_fare"]?.toString(),
        intercityFareCommission: json["intercity_fare_commission"]?.toString(),
        status: json["status"]?.toString(),
        createdAt: json["created_at"]?.toString(),
        updatedAt: json["updated_at"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "code": code,
        "image": image,
        "image_with_path": imageWithPath,
        "city_min_fare": cityMinFare,
        "city_max_fare": cityMaxFare,
        "city_recommend_fare": cityRecommendFare,
        "city_fare_commission": cityFareCommission,
        "intercity_min_fare": intercityMinFare,
        "intercity_max_fare": intercityMaxFare,
        "intercity_recommend_fare": intercityRecommendFare,
        "intercity_fare_commission": intercityFareCommission,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
