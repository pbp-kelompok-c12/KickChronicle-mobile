import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import 'package:pbp_django_auth/pbp_django_auth.dart';

class ApiMobile {
  final CookieRequest request;
  final String baseUrl;

  ApiMobile._(this.request, this.baseUrl);

  factory ApiMobile.fromContext(BuildContext context) {
    final req = context.read<CookieRequest>();
    final base = kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
    return ApiMobile._(req, base);
  }

  String _url(String path) {
    if (path.startsWith("/")) path = path.substring(1);
    return "$baseUrl/$path";
  }


  Future<Map<String, dynamic>> getComments({required String highlightId}) async {
    final url = _url("komen/mobile/highlight/$highlightId/comments/");
    try {
      final resp = await request.get(url);
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error getting comments: $e"};
    }
  }

  Future<Map<String, dynamic>> addComment({
    required String highlightId,
    required String content,
  }) async {
    final url = _url("komen/mobile/highlight/$highlightId/comment/");
    try {
      final resp = await request.postJson(url, jsonEncode({"content": content}));
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error adding comment: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteComment({required int commentId}) async {
    final url = _url("komen/mobile/comments/$commentId/delete/");
    try {
      final resp = await request.postJson(url, jsonEncode({}));
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error deleting comment: $e"};
    }
  }


  Future<Map<String, dynamic>> toggleFavorite({required String highlightId}) async {
    final url = _url("komen/mobile/highlight/$highlightId/favorite/");
    try {
      final resp = await request.postJson(url, jsonEncode({}));
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error toggling favorite: $e"};
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    final url = _url("komen/mobile/favorites/");
    try {
      final resp = await request.get(url);
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error fetching favorites: $e"};
    }
  }


  Future<Map<String, dynamic>> submitRating({
    required String highlightId,
    required int rating,
  }) async {
    final url = _url("komen/mobile/submit-rating/");
    try {
      final resp = await request.postJson(url, jsonEncode({
        "highlight_id": highlightId,
        "rating": rating,
      }));
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error submitting rating: $e"};
    }
  }


  Future<Map<String, dynamic>> getTopRated({
    String? startDate,
    String? endDate,
  }) async {
    String url = _url("komen/mobile/top-rated/");
print(startDate);
print(endDate);
    Map<String, String> query = {};
    if (startDate != null) query["start_date"] = startDate;
    if (endDate != null) query["end_date"] = endDate;

    if (query.isNotEmpty) {
      url += "?" +
          query.entries
              .map((e) => "${e.key}=${Uri.encodeComponent(e.value)}")
              .join("&");
    }

    try {
      final resp = await request.get(url);
      print(resp.toString());
      return {"ok": true, "data": resp};
    } catch (e) {
      return {"ok": false, "message": "Error fetching top rated: $e"};
    }
  }


 

  
   Future<Map<String, dynamic>> getUserRating({
    required String highlightId,
  }) async {
    final url = _url("komen/mobile/rating/$highlightId/");
    try {
      final resp = await request.get(url);
      return {"ok": true, "data": resp};
    } catch (e) {
      return {
        "ok": false,
        "message": "Error fetching user rating: $e"
      };
    }
  }
}

