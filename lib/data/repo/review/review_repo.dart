import 'package:ezdriver/core/utils/method.dart';
import 'package:ezdriver/core/utils/url_container.dart';
import 'package:ezdriver/data/model/global/response_model/response_model.dart';
import 'package:ezdriver/data/services/api_service.dart';

class ReviewRepo {
  ApiClient apiClient;
  ReviewRepo({required this.apiClient});

  Future<ResponseModel> getReviews() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.reviewHistoryEndPoint}";
    final response =
        await apiClient.request(url, Method.getMethod, {}, passHeader: true);
    return response;
  }

  Future<ResponseModel> getReviewByUserId(String userId) async {
    String url =
        "${UrlContainer.baseUrl}${UrlContainer.reviewByUserHistoryEndPoint}/$userId";
    final response =
        await apiClient.request(url, Method.getMethod, {}, passHeader: true);
    return response;
  }
}
