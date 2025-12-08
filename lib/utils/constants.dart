import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Backend URL untuk Flutter Web/Chrome saat backend jalan di localhost.
  static const String baseUrlWeb = 'http://127.0.0.1:8000';

  /// Backend URL untuk Android emulator. Jika memakai device fisik,
  /// ganti ke IP laptop, mis: http://192.168.x.x:8000
  static const String baseUrlMobile = 'http://10.0.2.2:8000';

  /// Pilih base URL otomatis sesuai platform.
  static String get baseUrl => kIsWeb ? baseUrlWeb : baseUrlMobile;
}

