import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _cookieKey = 'session_cookie';
  static const _userKey = 'session_user';

  SharedPreferences? _prefs;
  String? _cookie;
  Map<String, dynamic>? _user;

  bool get hasSession => _cookie != null && _cookie!.isNotEmpty;
  String? get cookie => _cookie;
  Map<String, dynamic>? get user =>
      _user == null ? null : Map<String, dynamic>.from(_user!);

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _cookie = _prefs?.getString(_cookieKey);
    _user = _readStoredUser(_prefs?.getString(_userKey));
  }

  void updateFromResponse(http.Response response) {
    final rawCookie = response.headers['set-cookie'];
    if (rawCookie == null || rawCookie.isEmpty) return;
    final parsedCookie = _normalizeCookie(rawCookie);
    if (parsedCookie.isEmpty) return;
    _cookie = parsedCookie;
    _prefs?.setString(_cookieKey, parsedCookie);
  }

  Map<String, String> withCookie(Map<String, String> headers) {
    if (_cookie == null || _cookie!.isEmpty) return headers;
    return {
      ...headers,
      'Cookie': _cookie!,
    };
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    _user = Map<String, dynamic>.from(user);
    await _prefs?.setString(_userKey, jsonEncode(_user));
  }

  Future<void> clearUser() async {
    _user = null;
    await _prefs?.remove(_userKey);
  }

  Future<void> clear() async {
    _cookie = null;
    await _prefs?.remove(_cookieKey);
    await clearUser();
  }

  String _normalizeCookie(String rawCookie) {
    final parts = rawCookie.split(',');
    final cookies = <String>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (!trimmed.contains('=')) continue;
      cookies.add(trimmed.split(';').first);
    }
    return cookies.join('; ');
  }

  Map<String, dynamic>? _readStoredUser(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Ignore bad cached user data and treat it as missing.
    }
    return null;
  }
}
