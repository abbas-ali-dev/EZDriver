import 'package:just_audio/just_audio.dart';
import 'package:ezdriver/core/helper/string_format_helper.dart';
import 'package:ezdriver/data/services/api_service.dart';
import 'package:get/get.dart';

class AudioUtils {
  static Future<void> playAudio(String path) async {
    if (Get.find<ApiClient>().isNotificationAudioEnable()) {
      try {
        final player = AudioPlayer();
        await player.setUrl(path);
        await player.play();
        await player.dispose();
      } catch (e) {
        printX(e);
      }
    }
  }
}
