import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Typed boundary for the Suraksha backend. It never exposes service secrets.
class ApiClient {
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = AppConstants.apiBaseUrl.endsWith('/')
        ? AppConstants.apiBaseUrl.substring(0, AppConstants.apiBaseUrl.length - 1)
        : AppConstants.apiBaseUrl;
    return Uri.parse('$base$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', _uri(path, query));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', _uri(path), body);

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', _uri(path), body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', _uri(path));

  Future<Map<String, dynamic>> _send(String method, Uri uri, [Map<String, dynamic>? body]) async {
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    String? accessToken;
    if (AppConstants.supabaseUrl.isNotEmpty && AppConstants.supabaseAnonKey.isNotEmpty) {
      try {
        accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        accessToken = null;
      }
    }
    if (accessToken != null && accessToken.isNotEmpty) headers['Authorization'] = 'Bearer $accessToken';

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    print('[ApiClient] -> $method $uri');
    final client = http.Client();
    late final http.Response response;
    try {
      response = await client.send(request).then(http.Response.fromStream);
      print('[ApiClient] <- ${response.statusCode} $uri');
    } catch (e) {
      print('[ApiClient] ERROR $method $uri: $e');
      rethrow;
    } finally {
      client.close();
    }
    Map<String, dynamic> payload = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) payload = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || payload['success'] == false) {
      throw ApiException(response.statusCode, payload['message'] as String? ?? 'Request failed');
    }
    return payload;
  }
}
