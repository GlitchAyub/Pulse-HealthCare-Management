import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../data/healthreach_api.dart';
import 'api_client.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required HealthReachApi api,
    required SessionStore sessionStore,
  })  : _api = api,
        _sessionStore = sessionStore;

  final HealthReachApi _api;
  final SessionStore _sessionStore;

  User? _user;
  bool _isInitializing = false;
  bool _isBusy = false;
  String? _error;

  User? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isBusy => _isBusy;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _setInitializing(true);
    try {
      if (_sessionStore.hasSession) {
        final cachedUser = _sessionStore.user;
        if (cachedUser != null && cachedUser.isNotEmpty) {
          _user = User.fromJson(cachedUser);
        }

        try {
          final data = await _api.getCurrentUser();
          _user = User.fromJson(data);
          await _sessionStore.saveUser(data);
        } catch (error) {
          if (_isUnauthorized(error)) {
            _user = null;
            await _sessionStore.clear();
          } else if (_user == null) {
            rethrow;
          }
        }
      } else {
        _user = null;
        await _sessionStore.clearUser();
      }
      _error = null;
    } catch (error) {
      _user = null;
      _error = _resolveErrorMessage(error);
    } finally {
      _setInitializing(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setBusy(true);
    try {
      final data = await _api.login(email: email, password: password);
      _user = User.fromJson(data);
      await _sessionStore.saveUser(data);
      _error = null;
      return true;
    } catch (error) {
      _user = null;
      _error = _resolveErrorMessage(error);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    _setBusy(true);
    try {
      final data = await _api.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      _user = User.fromJson(data);
      await _sessionStore.saveUser(data);
      _error = null;
      return true;
    } catch (error) {
      _user = null;
      _error = _resolveErrorMessage(error);
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _api.logout();
    } catch (_) {
      // Ignore network errors on logout.
    } finally {
      _user = null;
      _error = null;
      await _sessionStore.clear();
      _setBusy(false);
    }
  }

  void _setInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  bool _isUnauthorized(Object error) {
    return error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403);
  }
}
