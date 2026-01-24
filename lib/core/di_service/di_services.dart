import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezdriver/data/controller/common/theme_controller.dart';
import 'package:ezdriver/data/controller/localization/localization_controller.dart';
import 'package:ezdriver/data/controller/splash/splash_controller.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_controller.dart';
import 'package:ezdriver/data/controller/scheduled_ride/scheduled_ride_navigation_controller.dart';
import 'package:ezdriver/data/repo/auth/general_setting_repo.dart';
import 'package:ezdriver/data/repo/splash/splash_repo.dart';
import 'package:ezdriver/data/repo/scheduled_ride/scheduled_ride_repo.dart';
import 'package:ezdriver/data/services/api_service.dart';

Future<Map<String, Map<String, String>>> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();

  Get.lazyPut(() => sharedPreferences, fenix: true);
  Get.lazyPut(() => ApiClient(sharedPreferences: Get.find()));
  Get.lazyPut(() => GeneralSettingRepo(apiClient: Get.find()));
  Get.lazyPut(() => SplashRepo(apiClient: Get.find()));
  Get.lazyPut(() => LocalizationController(sharedPreferences: Get.find()));
  Get.lazyPut(() =>
      SplashController(repo: Get.find(), localizationController: Get.find()));
  Get.lazyPut(() => ThemeController(sharedPreferences: Get.find()));

  // Scheduled Ride Module
  Get.lazyPut(() => ScheduledRideRepo(apiClient: Get.find()), fenix: true);
  Get.lazyPut(() => ScheduledRideController(repo: Get.find()), fenix: true);
  Get.lazyPut(() => ScheduledRideNavigationController(), fenix: true);

  Map<String, Map<String, String>> language = {};
  language['en_US'] = {'': ''};

  return language;
}
