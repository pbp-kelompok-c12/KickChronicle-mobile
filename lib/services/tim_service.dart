import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:kick_chronicle/models/standing.dart';
import 'package:kick_chronicle/utils/constants.dart';

class TimService {
  TimService(this.request);

  final CookieRequest request;

  static String get _baseUrl => ApiConfig.baseUrl;

  Future<bool> isStaff() async {
    final url = '$_baseUrl/tim/api/check_admin/';
    try {
      final response = await request.get(url);
      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        return map['is_staff'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<String>> fetchSeasons() async {
    final url = '$_baseUrl/tim/api/seasons/';
    final response = await request.get(url);

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
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
    if (response is Map) {
      data = Map<String, dynamic>.from(response);
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

  Future<Map<String, dynamic>> createStanding(Map<String, dynamic> payload) async {
    final url = '$_baseUrl/tim/api/create/';
    final response = await request.postJson(url, jsonEncode(payload));
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid response'};
      }
    }
    return {'status': 'error', 'message': 'Invalid response'};
  }

  Future<Map<String, dynamic>> editStanding(int id, Map<String, dynamic> payload) async {
    final url = '$_baseUrl/tim/api/edit/$id/';
    final response = await request.postJson(url, jsonEncode(payload));
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid response'};
      }
    }
    return {'status': 'error', 'message': 'Invalid response'};
  }

  Future<Map<String, dynamic>> deleteStanding(int id) async {
    final url = '$_baseUrl/tim/api/delete/$id/';
    final response = await request.postJson(url, jsonEncode({}));
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid response'};
      }
    }
    return {'status': 'error', 'message': 'Invalid response'};
  }

  Future<Map<String, dynamic>> clearSeason(String season) async {
    final url = '$_baseUrl/tim/api/clear-season/';
    final response = await request.postJson(url, jsonEncode({'season': season}));
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid response'};
      }
    }
    return {'status': 'error', 'message': 'Invalid response'};
  }

  Future<Map<String, dynamic>> uploadStandingsCsv({
    required String season,
    required String csvContent,
  }) async {
    final url = '$_baseUrl/tim/api/upload_flutter/';
    final response = await request.post(url, {
      'season': season,
      'csv_content': csvContent,
    });

    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is String) {
      try {
        return jsonDecode(response) as Map<String, dynamic>;
      } catch (_) {
        return {'status': 'error', 'message': 'Invalid response'};
      }
    }
    return {'status': 'error', 'message': 'Invalid response'};
  }
}
