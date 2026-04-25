import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:hello/core/services/api_service.dart';

/// Centralized session management with secure token storage.
///
/// Tokens are stored in FlutterSecureStorage (encrypted).
/// Non-sensitive user profile data is stored in SharedPreferences.
class SessionManager {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Secure storage keys (tokens) ────────────────────────────────────────
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  // ─── SharedPreferences keys (non-sensitive) ──────────────────────────────
  static const _keyUserData = 'user_data';
  static const _keySavedAccount = 'saved_account';  // For "Continue as" feature
  static const _keyIsLoggedIn = 'is_logged_in';

  // ═══════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT (FlutterSecureStorage)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save both tokens after login/signup
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(key: _keyAccessToken, value: accessToken),
      _secureStorage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  /// Get the current access token
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  /// Get the current refresh token
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  /// Delete all tokens
  static Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: _keyAccessToken),
      _secureStorage.delete(key: _keyRefreshToken),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER DATA MANAGEMENT (SharedPreferences)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save user profile data after login
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, json.encode(userData));
    await prefs.setBool(_keyIsLoggedIn, true);

    // Also save to legacy keys for backward compatibility
    await prefs.setString('userData', json.encode(userData));
    await prefs.setString('user_data', json.encode(userData));
  }

  /// Get stored user profile data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data != null && data.isNotEmpty) {
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Clear user data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove('userData');
    await prefs.remove('user_data');
    await prefs.remove('token');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVED ACCOUNT (for "Continue as..." feature)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save account info for the "Continue as" feature on the login screen
  static Future<void> saveAccountForRemember(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final account = {
      'email': userData['email'] ?? '',
      'firstName': userData['firstName'] ?? '',
      'lastName': userData['lastName'] ?? '',
      'profileImage': userData['profileImage'] ?? '',
      'role': userData['role'] ?? '',
    };
    await prefs.setString(_keySavedAccount, json.encode(account));
  }

  /// Get saved account for the "Continue as" login screen
  static Future<Map<String, dynamic>?> getSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keySavedAccount);
    if (data != null && data.isNotEmpty) {
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  /// Clear saved account (when user picks "Use another account")
  static Future<void> clearSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedAccount);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Complete login: save tokens, user data, and account for remember
  static Future<void> createSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    await Future.wait([
      saveTokens(accessToken: accessToken, refreshToken: refreshToken),
      saveUserData(userData),
      saveAccountForRemember(userData),
    ]);

    // Also save to legacy SharedPreferences 'token' key for backward compat
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', accessToken);
  }

  /// Check if user is currently logged in (has tokens)
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Try to refresh the session using the refresh token.
  /// Returns true if session was refreshed, false if user needs to login again.
  static Future<bool> refreshSession() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Save the new tokens and updated user data
          await createSession(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            userData: data['user'],
          );
          return true;
        }
      }

      // If refresh failed, the session is invalid
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validate the current session.
  /// Checks if access token exists and is not expired.
  /// If expired, attempts to refresh using refresh token.
  /// Returns the user's role if session is valid, null otherwise.
  static Future<String?> validateSession() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }

      // Check if the JWT token is expired by decoding it
      if (_isTokenExpired(accessToken)) {
        // Try to refresh
        final refreshed = await refreshSession();
        if (!refreshed) {
          await clearSession();
          return null;
        }
      }

      // Session is valid — return role from stored user data
      final userData = await getUserData();
      if (userData != null) {
        return userData['role']?.toString().toLowerCase();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if a JWT token is expired
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'];
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Add a 60-second buffer to avoid edge cases
      return DateTime.now().isAfter(expiryDate.subtract(const Duration(seconds: 60)));
    } catch (e) {
      return true;
    }
  }

  /// Full logout: clear everything and notify backend
  static Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();

      // Notify backend to invalidate the refresh token
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await http.post(
            Uri.parse('${ApiService.baseUrl}/auth/logout'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refreshToken': refreshToken}),
          );
        } catch (_) {
          // Even if backend call fails, clear local session
        }
      }
    } catch (_) {}

    await clearSession();
  }

  /// Clear local session data (but keep saved account for "Continue as")
  static Future<void> clearSession() async {
    await clearTokens();
    await clearUserData();
  }

  /// Full wipe: clear everything including saved account
  static Future<void> clearEverything() async {
    await clearTokens();
    await clearUserData();
    await clearSavedAccount();
  }
}
