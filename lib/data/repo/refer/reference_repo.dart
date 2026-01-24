import 'package:ezdriver/core/utils/method.dart';
import 'package:ezdriver/core/utils/url_container.dart';
import 'package:ezdriver/data/model/global/response_model/response_model.dart';
import 'package:ezdriver/data/services/api_service.dart';

class ReferenceRepo {
  ApiClient apiClient;
  ReferenceRepo({required this.apiClient});

  Future<ResponseModel> getReferData() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.referenceEndPoint}";
    ResponseModel responseModel =
        await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return responseModel;
  }
}
