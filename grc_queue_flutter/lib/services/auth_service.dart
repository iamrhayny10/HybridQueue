// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/http_client.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  bool       _loading = false;
  String?    _error;

  UserModel? get user      => _user;
  bool       get isLoading => _loading;
  String?    get error     => _error;
  bool       get isLoggedIn => _user != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(AppConstants.prefSession);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _user = UserModel.fromJson(map, map['token'] as String? ?? '');
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final resp = await AppHttp.post(
        Uri.parse(AppConstants.authEndpoint),
        body: jsonEncode({
          'action':   'login',
          'username': username.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (data['success'] == true) {
        _user = UserModel.fromJson(
          data['user'] as Map<String, dynamic>,
          data['token'] as String,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          AppConstants.prefSession,
          jsonEncode({..._user!.toJson(), 'token': _user!.token}),
        );
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error   = data['error'] as String? ?? 'Login failed.';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (_) {
      _error   = 'Cannot connect to server. Check your network.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> register({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final resp = await AppHttp.post(
        Uri.parse(AppConstants.authEndpoint),
        body: jsonEncode({
          'action':     'register',
          'full_name':  fullName.trim(),
          'student_id': studentId.trim(),
          'email':      email.trim(),
          'password':   password,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _loading = false;
      notifyListeners();

      if (data['success'] == true) return null;
      return data['error'] as String? ?? 'Registration failed.';
    } catch (_) {
      _loading = false;
      notifyListeners();
      return 'Cannot connect to server.';
    }
  }

  /// Forgot password — step 1: confirm Student ID + registered email.
  /// Returns a short-lived reset token, or null (see [error]).
  Future<String?> verifyResetIdentity({
    required String studentId,
    required String email,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final resp = await AppHttp.post(
        Uri.parse(AppConstants.authEndpoint),
        body: jsonEncode({
          'action':     'verify_reset',
          'student_id': studentId.trim(),
          'email':      email.trim(),
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _loading = false;

      if (data['success'] == true) {
        notifyListeners();
        return data['reset_token'] as String?;
      }
      _error = data['error'] as String? ?? 'Verification failed.';
      notifyListeners();
      return null;
    } catch (_) {
      _error   = 'Cannot connect to server. Check your network.';
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  /// Forgot password — step 2: save the new password.
  /// Returns null on success, otherwise an error message.
  Future<String?> resetPassword({
    required String studentId,
    required String resetToken,
    required String newPassword,
  }) async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      final resp = await AppHttp.post(
        Uri.parse(AppConstants.authEndpoint),
        body: jsonEncode({
          'action':       'reset_password',
          'student_id':   studentId.trim(),
          'reset_token':  resetToken,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      _loading = false;
      notifyListeners();

      if (data['success'] == true) return null;
      return data['error'] as String? ?? 'Could not reset password.';
    } catch (_) {
      _loading = false;
      notifyListeners();
      return 'Cannot connect to server.';
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefSession);
    await prefs.remove(AppConstants.prefTicketId);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
