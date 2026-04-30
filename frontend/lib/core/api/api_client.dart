import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/auth_provider.dart';

part 'api_client.g.dart';

String computeWebBaseUrl() {
  if (kDebugMode) return 'http://localhost:3000';
  final uri = Uri.base;
  return '${uri.scheme}://${uri.host}${uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient(this._apiKey, this._baseUrl);

  final String? _apiKey;
  final String _baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
  };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<String> transcribeAudio(Uint8List bytes, String mimeType) async {
    final uri = Uri.parse('$_baseUrl/api/transcribe');
    final request = http.MultipartRequest('POST', uri);
    if (_apiKey != null) request.headers['Authorization'] = 'Bearer $_apiKey';
    request.files.add(http.MultipartFile.fromBytes(
      'audio',
      bytes,
      filename: 'recording.${mimeType.split('/').last}',
    ));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = _handle(res) as Map<String, dynamic>;
    return body['transcript'] as String? ?? '';
  }

  Future<void> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    // Try to extract the error message from the JSON body.
    // If the response is not JSON (e.g. an HTML 413 page from a reverse proxy),
    // fall back to the HTTP reason phrase so we don't crash with a FormatException.
    String message = res.reasonPhrase ?? 'HTTP ${res.statusCode}';
    if (res.body.isNotEmpty) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        message = body['error'] ?? message;
      } catch (_) {
        // Non-JSON response (e.g. proxy error page) – keep the fallback message.
      }
    }
    throw ApiException(res.statusCode, message);
  }
}

@riverpod
ApiClient apiClient(Ref ref) {
  final apiKey = ref.watch(authNotifierProvider).valueOrNull;
  final String baseUrl;
  if (kIsWeb) {
    baseUrl = computeWebBaseUrl();
  } else {
    baseUrl = ref.watch(serverUrlNotifierProvider).valueOrNull ?? 'http://10.0.2.2:3000';
  }
  return ApiClient(apiKey, baseUrl);
}
