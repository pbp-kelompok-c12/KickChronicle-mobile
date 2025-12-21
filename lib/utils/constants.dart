import 'package:flutter/foundation.dart'; 

class ApiConfig {
  static const String baseUrlProd =
      'https://derrick-kickchronicle.pbp.cs.ui.ac.id';
  static const String baseUrlLocal = 'http://127.0.0.1:8000'; // Untuk Web & iOS
  static const String baseUrlAndroid =
      'http://10.0.2.2:8000'; // Untuk Android Emulator

  static String get baseUrl {
    return baseUrlProd;
  //   if (kReleaseMode) {
  //     return baseUrlProd;
  //   }

  //   if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
  //     return baseUrlLocal;
  //   }
  //   return baseUrlAndroid;
  }
}
