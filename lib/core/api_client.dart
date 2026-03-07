import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({SessionStore? sessionStore, http.Client? client})
      : _sessionStore = sessionStore ?? SessionStore.instance,
        _client = client ?? http.Client();

  final SessionStore _sessionStore;
  final http.Client _client;

  Uri uri(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$normalized').replace(queryParameters: query);
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _send(
      () => _client.get(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
      ),
    );
    return _decode(response);
  }

  Future<String> getRaw(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    final response = await _send(
      () => _client.get(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
      ),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }
    throw ApiException(response.statusCode, response.reasonPhrase ?? 'Error');
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _client.post(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> patchJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _client.patch(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _client.put(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _client.delete(
        uri(path, query: query),
        headers: _sessionStore.withCookie({
          ..._headers(),
          if (headers != null) ...headers,
        }),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    required http.MultipartFile file,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest('POST', uri(path))
      ..fields.addAll(fields)
      ..files.add(file)
      ..headers.addAll(_sessionStore.withCookie({
        if (headers != null) ...headers,
      }));

    final streamed = await _sendMultipart(request);
    final response = await http.Response.fromStream(streamed);
    _sessionStore.updateFromResponse(response);
    return _decode(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      _sessionStore.updateFromResponse(response);
      return response;
    } catch (error) {
      throw _transportException(error);
    }
  }

  Future<http.StreamedResponse> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    try {
      return await request.send();
    } catch (error) {
      throw _transportException(error);
    }
  }

  Map<String, String> _headers() {
    return const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  ApiException _transportException(Object error) {
    final message = error.toString();
    final normalized = message.toLowerCase();

    if (normalized.contains('failed host lookup') ||
        normalized.contains('no address associated with hostname') ||
        normalized.contains('name or service not known')) {
      return ApiException(
        -1,
        'Unable to reach the server. Check your internet connection and try again.',
      );
    }

    if (normalized.contains('connection refused') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection timed out')) {
      return ApiException(
        -1,
        'The server is unavailable right now. Please try again in a moment.',
      );
    }

    return ApiException(-1, message);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        final body = response.body.trimLeft();
        if (_looksLikeHtml(body)) {
          throw ApiException(
            response.statusCode,
            'Endpoint returned HTML instead of JSON.',
          );
        }
        throw ApiException(
          response.statusCode,
          'Endpoint returned invalid JSON.',
        );
      }
    }
    String message = response.reasonPhrase ?? 'Request failed';
    if (response.body.isNotEmpty) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] is String) {
          message = body['message'] as String;
        } else if (body is String) {
          message = body;
        }
      } catch (_) {
        message = response.body;
      }
    }
    throw ApiException(response.statusCode, message);
  }

  bool _looksLikeHtml(String body) {
    final lower = body.toLowerCase();
    return lower.startsWith('<!doctype html') || lower.startsWith('<html');
  }
}
