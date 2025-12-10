import 'package:pbp_django_auth/pbp_django_auth.dart';

class CookieService {
  final CookieRequest request;

  CookieService({required String baseUrl})
      : request = CookieRequest() {
    (request as dynamic).baseUrl = baseUrl; 
    (request as dynamic).baseUri = Uri.parse(baseUrl);
  }
}