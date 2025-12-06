import 'dart:convert';
import 'package:kick_chronicle/models/highlight.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

// Updated to accept a page number for pagination
Future<List<Highlight>> fetchHighlights(CookieRequest request, {int page = 1,String query = ''}) async {
  String baseUrl = 'http://127.0.0.1:8000/highlights-json/';

  String url = '$baseUrl?page=$page';
  if (query.isNotEmpty) {
    url += '&q=${Uri.encodeComponent(query)}';
  }

  final response = await request.get(url);

  List<Highlight> listHighlights = [];

  // Handle case where Django Paginator returns a dictionary { "results": [...], "next": ... }
  // OR the standard list [...] you showed earlier.
  var results = response;

  if (response is Map && response.containsKey('results')) {
    results = response['results'];
  }

  for (var d in results) {
    if (d != null) {
      if (d is Map && d.containsKey('fields')) {
        var fields = d['fields'];
        if (d.containsKey('pk')) {
          fields['id'] = d['pk'].toString();
        }
        listHighlights.add(Highlight.fromJson(fields));
      } else {
        listHighlights.add(Highlight.fromJson(d));
      }
    }
  }

  return listHighlights;
}