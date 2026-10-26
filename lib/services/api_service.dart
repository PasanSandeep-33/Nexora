import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

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
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
          }),
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

  // Protected API - Get logged-in user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/profile/'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired or invalid. Please login again.');
    }

    throw Exception(
      'Failed to load profile: ${response.statusCode}',
    );
  }

  // Logout - Delete locally stored JWT token
  static Future<void> logout() async {
    await AuthStorage.deleteToken();
  }
}
