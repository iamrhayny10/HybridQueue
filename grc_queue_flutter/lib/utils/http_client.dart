// lib/utils/http_client.dart
//
// Centralised HTTP helper so every request automatically includes:
//   - Content-Type: application/json
//   - ngrok-skip-browser-warning: true
//     (bypasses the ngrok free-tier browser-warning interstitial that
//      otherwise breaks API calls when using ngrok for public access)
//
// Usage:
//   import '../utils/http_client.dart';
//   final resp = await AppHttp.get(Uri.parse(url));
//   final resp = await AppHttp.post(Uri.parse(url), body: jsonEncode(data));
//   final resp = await AppHttp.put(Uri.parse(url), body: jsonEncode(data));

import 'package:http/http.dart' as http;

class AppHttp {
  static const Map<String, String> _headers = {
    'Content-Type':               'application/json',
    'ngrok-skip-browser-warning': 'true',
    'bypass-tunnel-reminder':     'true',  // Serveo bypass
    'User-Agent':                 'GRCQueueApp/1.0',
  };

  static Future<http.Response> get(
    Uri url, {
    Duration timeout = const Duration(seconds: 8),
    Map<String, String>? headers,
  }) =>
      http.get(url, headers: {..._headers, ...?headers}).timeout(timeout);

  static Future<http.Response> post(
    Uri url, {
    Object? body,
    Duration timeout = const Duration(seconds: 10),
    Map<String, String>? headers,
  }) =>
      http.post(url, headers: {..._headers, ...?headers}, body: body).timeout(timeout);

  static Future<http.Response> put(
    Uri url, {
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) =>
      http.put(url, headers: _headers, body: body).timeout(timeout);
}
