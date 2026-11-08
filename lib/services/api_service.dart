import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';
import 'auth_storage.dart';

class ApiService {
  // static const String baseUrl = 'https://nexora-event-mgmt-api.onrender.com';
  static const String baseUrl =
    'https://nexora-event-mgmt-api.onrender.com';

  // Public API - Get approved events
  static Future<List<Event>> getEvents() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/events/'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => Event.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }

  // Public API - Signup
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/signup/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Signup failed: $data');
    }
  }

  // Public API - Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(
        data is Map && data['message'] != null
            ? data['message']
            : 'Login failed',
      );
    }
  }


  // Administrator MFA: begin first-time authenticator enrollment.
  static Future<Map<String, dynamic>> adminMfaSetup({
    required String challengeToken,
  }) async {
    return _mfaPost('/api/admin/mfa/setup/', {
      'challenge_token': challengeToken,
    });
  }

  // Administrator MFA: verify first-time enrollment.
  static Future<Map<String, dynamic>> adminMfaVerifySetup({
    required String enrollmentToken,
    required String code,
  }) async {
    return _mfaPost('/api/admin/mfa/verify-setup/', {
      'enrollment_token': enrollmentToken,
      'code': code,
    });
  }

  // Administrator MFA: verify an authenticator code during login.
  static Future<Map<String, dynamic>> adminMfaVerifyLogin({
    required String challengeToken,
    required String code,
  }) async {
    return _mfaPost('/api/admin/mfa/verify-login/', {
      'challenge_token': challengeToken,
      'code': code,
    });
  }

  // Administrator MFA: use a one-time recovery code instead of TOTP.
  static Future<Map<String, dynamic>> adminMfaRecovery({
    required String challengeToken,
    required String recoveryCode,
  }) async {
    return _mfaPost('/api/admin/mfa/recovery/', {
      'challenge_token': challengeToken,
      'recovery_code': recoveryCode,
    });
  }

  static Future<Map<String, dynamic>> _mfaPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected server response.');
    }

    final message = decoded is Map && decoded['message'] != null
        ? decoded['message'].toString()
        : 'MFA request failed (${response.statusCode}).';
    throw Exception(message);
  }

  // Protected API - Get logged-in user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/profile/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired or invalid. Please login again.');
    }

    throw Exception('Failed to load profile: ${response.statusCode}');
  }

  
static Future<bool> refreshSession() async {
  final refreshToken = await AuthStorage.getRefreshToken();

  if (refreshToken == null || refreshToken.isEmpty) {
    return false;
  }

  final response = await http
      .post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    return false;
  }

  final data = jsonDecode(response.body);
  final accessToken = data['access_token'];
  final newRefreshToken = data['refresh_token'];

  if (accessToken is! String ||
      accessToken.isEmpty ||
      newRefreshToken is! String ||
      newRefreshToken.isEmpty) {
    return false;
  }

  await AuthStorage.updateTokens(
    accessToken: accessToken,
    refreshToken: newRefreshToken,
  );

  return true;
}

  // Logout - Delete locally stored JWT token
  static Future<void> logout() async {
    await AuthStorage.deleteToken();
  }
}
