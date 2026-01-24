import 'dart:convert';

import 'package:get/get.dart';
import 'package:ezdriver/core/helper/string_format_helper.dart';
import 'package:ezdriver/core/utils/my_strings.dart';

import 'package:ezdriver/data/model/global/response_model/response_model.dart';
import 'package:ezdriver/data/model/global/ride/ride_model.dart';
import 'package:ezdriver/data/model/ride/cancel_ride_response_model.dart';
import 'package:ezdriver/data/repo/ride/ride_repo.dart';
import 'package:ezdriver/presentation/components/snack_bar/show_custom_snackbar.dart';

class CancelRideController extends GetxController {
  RideRepo repo;
  CancelRideController({required this.repo});

  bool isLoading = true;

  String imagePath = "";
  String defaultCurrency = "";
  String defaultCurrencySymbol = "";
  String username = "";
  int page = 0;
  bool isInterCity = false;

  Future<void> initialData(bool isICity) async {
    page = 0;
    defaultCurrency = repo.apiClient.getCurrencyOrUsername();
    defaultCurrencySymbol =
        repo.apiClient.getCurrencyOrUsername(isSymbol: true);
    username = repo.apiClient.getCurrencyOrUsername(isCurrency: false);
    cancelRideList = [];
    isInterCity = isICity;
    update();

    await getCanceledRideList();
  }

  List<RideModel> cancelRideList = [];
  String? nextPageUrl;
  Future<void> getCanceledRideList() async {
    page = page + 1;
    if (page == 1) {
      cancelRideList.clear();
      isLoading = true;
      update();
    }

    try {
      ResponseModel responseModel =
          await repo.canceledRide(page.toString(), isICity: isInterCity);
      if (responseModel.statusCode == 200) {
        CancelRideListResponseModel model =
            CancelRideListResponseModel.fromJson(
                jsonDecode(responseModel.responseJson));
        if (model.status == MyStrings.success) {
          printX(model.status);
          nextPageUrl = model.data?.cancelRides?.nextPageUrl;
          cancelRideList.addAll(model.data?.cancelRides?.data ?? []);
          update();
        } else {
          CustomSnackBar.error(
              errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }
    isLoading = false;
    update();
  }

  bool hasNext() {
    return nextPageUrl != null &&
            nextPageUrl!.isNotEmpty &&
            nextPageUrl != 'null'
        ? true
        : false;
  }
}
