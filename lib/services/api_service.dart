import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

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
}
