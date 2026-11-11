import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/event_model.dart';
import '../models/club_model.dart';
import 'package:file_picker/file_picker.dart';
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
      if (data is Map) {
        final emailError = data['email'];
        if (emailError is List && emailError.isNotEmpty) {
          throw Exception(emailError.first.toString());
        }
        if (emailError is String && emailError.isNotEmpty) {
          throw Exception(emailError);
        }

        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }

        for (final value in data.values) {
          if (value is List && value.isNotEmpty) {
            throw Exception(value.first.toString());
          }
          if (value is String && value.isNotEmpty) {
            throw Exception(value);
          }
        }
      }

      throw Exception('Unable to create your account. Please try again.');
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


  // Public API - Get clubs approved for public display.
  static Future<List<Club>> getClubs() async {
  final token = await AuthStorage.getToken();

  if (token == null || token.isEmpty) {
    throw Exception('Session expired. Please log in again.');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/api/clubs/'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    final List<dynamic> items = decoded is List
        ? decoded
        : decoded is Map && decoded['results'] is List
            ? decoded['results'] as List<dynamic>
            : <dynamic>[];

    return items
        .whereType<Map>()
        .map(
          (item) => Club.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  if (response.statusCode == 401) {
    throw Exception('Session expired. Please log in again.');
  }

  throw Exception(
    'Failed to load clubs (${response.statusCode}).',
  );
}

  // Get the current student's President Application; 404 means none exists.
  static Future<Map<String, dynamic>?> getMyPresidentApplication() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/api/president-applications/me/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return null;
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
      return null;
    }
    throw Exception('Unable to load President Application (${response.statusCode}).');
  }

  // Submit President Application as multipart form data.
  static Future<Map<String, dynamic>> submitPresidentApplication({
    required String reason,
    required PlatformFile supportingDocument,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }
    final bytes = await supportingDocument.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Could not read the selected document. Please select it again.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/president-applications/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['reason'] = reason.trim();
    request.files.add(http.MultipartFile.fromBytes(
      'supporting_document',
      bytes,
      filename: supportingDocument.name,
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {'status': 'pending'};
    }
    if (decoded is Map) {
      final detail = decoded['detail'] ?? decoded['message'];
      if (detail != null) throw Exception(detail.toString());
      throw Exception(decoded.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
    }
    throw Exception('President application failed (${response.statusCode}).');
  }


  static Future<List<Map<String, dynamic>>> getPresidentApplications() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your admin session has expired. Please log in again.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/president-applications/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    dynamic decoded;
    try { decoded = jsonDecode(response.body); } catch (_) { decoded = null; }
    if (response.statusCode == 200) {
      final List<dynamic> items = decoded is List
          ? decoded
          : (decoded is Map && decoded['results'] is List
              ? decoded['results'] as List<dynamic> : <dynamic>[]);
      return items.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
    }
    final message = decoded is Map
        ? (decoded['detail'] ?? decoded['message'] ?? decoded.toString())
        : 'Unable to load President Applications (${response.statusCode}).';
    throw Exception(message.toString());
  }

  static Future<void> approvePresidentApplication(int id) async {
    await _presidentApplicationAction(id, 'approve', {});
  }

  static Future<void> rejectPresidentApplication(int id, {String reviewReason = ''}) async {
    await _presidentApplicationAction(id, 'reject', {'review_reason': reviewReason});
  }

  static Future<void> _presidentApplicationAction(
    int id, String action, Map<String, dynamic> body,
  ) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your admin session has expired. Please log in again.');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/president-applications/$id/$action/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    dynamic decoded;
    try { decoded = jsonDecode(response.body); } catch (_) { decoded = null; }
    final message = decoded is Map
        ? (decoded['detail'] ?? decoded['message'] ?? decoded.toString())
        : 'Could not $action application (${response.statusCode}).';
    throw Exception(message.toString());
  }

  // Returns a short-lived, authenticated Cloudinary link for the document.
  static Future<String> getPresidentApplicationDocumentUrl(
    int id, {bool download = false}
  ) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your admin session has expired. Please log in again.');
    }
    final uri = Uri.parse('$baseUrl/api/admin/president-applications/$id/document/')
        .replace(queryParameters: {'download': download ? '1' : '0'});
    final response = await http.get(
      uri, headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Unable to retrieve document (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['document_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Document link was not returned by the server.');
    }
    return url;
  }

  // Clubs where the logged-in approved President can create events.
  static Future<List<Map<String, dynamic>>> getMyPresidentClubs() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.get(
      Uri.parse('$baseUrl/api/president/clubs/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Unable to load your clubs (${response.statusCode}).');
    }
    final data = jsonDecode(response.body);
    return (data['clubs'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> createEvent({
    required int clubId,
    required String title,
    required String category,
    required String description,
    required DateTime dateTime,
    required String location,
    required int capacity,
    required PlatformFile proposalPdf,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/events/create/'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'club': clubId.toString(), 'title': title.trim(), 'category': category,
      'description': description.trim(), 'event_date': dateTime.toUtc().toIso8601String(),
      'location': location.trim(), 'capacity': capacity.toString(),
    });
    if (!proposalPdf.name.toLowerCase().endsWith('.pdf')) {
      throw Exception('Please select a PDF file.');
    }
    final pdfSize = await proposalPdf.length();
    if (pdfSize == null || pdfSize <= 0 || pdfSize > 10 * 1024 * 1024) {
      throw Exception('Choose a readable PDF no larger than 10 MB.');
    }
    final pdfBytes = await proposalPdf.readAsBytes();
    if (pdfBytes.length < 5 ||
        pdfBytes[0] != 0x25 || pdfBytes[1] != 0x50 ||
        pdfBytes[2] != 0x44 || pdfBytes[3] != 0x46 ||
        pdfBytes[4] != 0x2D) {
      throw Exception('The selected file is not a valid PDF.');
    }
    request.files.add(http.MultipartFile.fromBytes(
      'proposal_pdf', pdfBytes, filename: proposalPdf.name,
    ));
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 60)),
    );
    if (response.statusCode == 201) return;
    dynamic data;
    try { data = jsonDecode(response.body); } catch (_) { data = null; }
    throw Exception(data is Map ? (data['detail'] ?? data.toString()).toString()
        : 'Could not submit event (${response.statusCode}).');
  }

  // Events belonging to the authenticated club president.
  static Future<List<Map<String, dynamic>>> getMyPresidentEvents() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.get(
      Uri.parse('$baseUrl/api/president/events/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Could not load club events (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : decoded is Map && decoded['results'] is List
            ? decoded['results'] as List
            : decoded is Map && decoded['events'] is List
                ? decoded['events'] as List
                : null;
    if (items == null) throw Exception('Unexpected club events response.');
    return items.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // Edit an existing event owned by the authenticated club president.
  static Future<void> updatePresidentEvent({
    required int eventId,
    required String title,
    required String category,
    required String description,
    required DateTime dateTime,
    required String location,
    required int capacity,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.patch(
      Uri.parse('$baseUrl/api/president/events/$eventId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title.trim(),
        'category': category,
        'description': description.trim(),
        'event_date': dateTime.toUtc().toIso8601String(),
        'location': location.trim(),
        'capacity': capacity,
      }),
    ).timeout(const Duration(seconds: 25));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    dynamic data;
    try { data = jsonDecode(response.body); } catch (_) { data = null; }
    throw Exception(data is Map
        ? (data['detail'] ?? data.toString()).toString()
        : 'Could not update event (${response.statusCode}).');
  }

  // Delete an event owned by the authenticated club president.
  static Future<void> deletePresidentEvent(int eventId) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/president/events/$eventId/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 25));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    dynamic data;
    try { data = jsonDecode(response.body); } catch (_) { data = null; }
    throw Exception(data is Map
        ? (data['detail'] ?? data.toString()).toString()
        : 'Could not delete event (${response.statusCode}).');
  }

  // Admin event approval queue.
  static Future<List<Map<String, dynamic>>> getPendingAdminEvents() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/events/pending/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Unable to load event submissions (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return (decoded as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<List<Map<String, dynamic>>> getApprovedAdminEvents() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/events/approved/'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw Exception('Unable to load approved events (${response.statusCode}).');
    return (jsonDecode(response.body) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<String> getAdminEventProposalUrl(int eventId, {bool download = false}) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final uri = Uri.parse('$baseUrl/api/admin/events/$eventId/proposal/')
        .replace(queryParameters: {'download': download ? '1' : '0'});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Unable to access proposal (${response.statusCode}): ${response.body}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['url'] as String;
  }

  static Future<void> reviewAdminEvent(int eventId, {
    required bool approve,
    String reason = '',
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/events/$eventId/review/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'decision': approve ? 'approved' : 'rejected',
        'comments': reason.trim(),
      }),
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to review event (${response.statusCode}): ${response.body}');
    }
  }

  // Upload via authenticated Django endpoint; Django uploads to Cloudinary
  // and saves the URL on the current user's database record.
  static Future<String> uploadProfileImage(XFile image) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in again.');
    }
    final request = http.MultipartRequest(
      'POST', Uri.parse('$baseUrl/api/profile/image/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes(
      'image', await image.readAsBytes(), filename: image.name,
    ));
    final streamed = await request.send().timeout(const Duration(seconds: 40));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['profile_image_url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Server did not return an image URL.');
    }
    return url;
  }

  // Logout - Delete locally stored JWT token
  static Future<void> logout() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await http.post(
          Uri.parse('$baseUrl/api/logout/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Clear the local session even if the server is temporarily unavailable.
    } finally {
      await AuthStorage.deleteToken();
    }
  }
  // Phase 1: authenticated RSVP and attendance API.
  static Future<http.Response> _phase1Request(String method, String path, [Map<String, dynamic>? body]) async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Please log in again.');
    final uri = Uri.parse('$baseUrl/api/$path');
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 25));
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 25));
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 25));
    } else { throw ArgumentError('Unsupported HTTP method'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) message = decoded['detail'].toString();
      } catch (_) {}
      throw Exception(message);
    }
    return response;
  }

  static Future<List<Map<String, dynamic>>> getMyRsvps() async {
    final response = await _phase1Request('GET', 'rsvps/');
    return (jsonDecode(response.body) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> registerRsvp(int eventId) async {
    final response = await _phase1Request('POST', 'rsvps/', {'event_id': eventId});
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> cancelRsvp(int rsvpId) async {
    await _phase1Request('DELETE', 'rsvps/$rsvpId/');
  }

  static Future<List<Map<String, dynamic>>> getPresidentParticipants({int? eventId}) async {
    final query = eventId == null ? '' : '?event_id=$eventId';
    final response = await _phase1Request('GET', 'president/participants/$query');
    return (jsonDecode(response.body) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> checkInTicket(String qrCode) async {
    await _phase1Request('POST', 'president/check-in/', {'qr_code': qrCode});
  }

  static Future<void> undoTicketCheckIn(String qrCode) async {
    await _phase1Request('DELETE', 'president/check-in/', {'qr_code': qrCode});
  }

  static Future<int> getAdminStudentCount() async {
  final token = await AuthStorage.getToken();

  if (token == null || token.isEmpty) {
    throw Exception('Please log in again.');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/students/count/'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  ).timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw Exception(
      'Unable to load student count (${response.statusCode}).',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return (data['count'] as num).toInt();
}

}
