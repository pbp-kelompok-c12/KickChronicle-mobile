import 'dart:convert';

import 'package:pbp_django_auth/pbp_django_auth.dart';

import 'package:kick_chronicle/models/standing.dart';
import 'package:kick_chronicle/utils/constants.dart';

class TimService {
  TimService(this.request);

  final CookieRequest request;

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<List<String>> fetchSeasons() async {
    final url = '$_baseUrl/tim/api/seasons/';
    final response = await request.get(url);

    if (response is Map<String, dynamic> || response is Map) {
      final map = Map<String, dynamic>.from(response as Map);
      final raw = map['seasons'] as List<dynamic>? ?? [];
      return raw.map((e) => e.toString()).toList();
    }

    // Fallback when using raw body string (defensive)
    if (response is String) {
      final decoded = jsonDecode(response) as Map<String, dynamic>;
      final raw = decoded['seasons'] as List<dynamic>? ?? [];
      return raw.map((e) => e.toString()).toList();
    }

    return [];
  }

  Future<List<Standing>> fetchStandings({String? season}) async {
    var url = '$_baseUrl/tim/api/standings/';
    if (season != null && season.isNotEmpty) {
      url = '$url?season=$season';
    }

    final response = await request.get(url);

    Map<String, dynamic> data;
    if (response is Map<String, dynamic> || response is Map) {
      data = Map<String, dynamic>.from(response as Map);
    } else if (response is String) {
      data = jsonDecode(response) as Map<String, dynamic>;
    } else {
      return [];
    }

    final rawList = data['standings'] as List<dynamic>? ?? [];
    return rawList
        .map((item) => Standing.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
