
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_storage.dart';

class ProfileImageService {
  static Future<String> uploadProfileImage(File file) async {
    // Retrieve the logged-in user's access token.
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Please log in before uploading a profile image.',
      );
    }

    // Create multipart request for Django API.
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiService.baseUrl}/api/profile/image/',
      ),
    );

    // Add JWT authentication.
    request.headers['Authorization'] = 'Bearer $token';

    // Attach image using the field name expected by Django.
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        file.path,
      ),
    );

    // Print the exact upload URL.
    print('PROFILE UPLOAD URL: ${request.url}');
    // Upload image.
    final streamed = await request.send().timeout(
      const Duration(seconds: 45),
    );

    final response = await http.Response.fromStream(
      streamed,
    );

    // Handle upload errors.
    if (response.statusCode != 200) {
      throw Exception(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }

    // Decode Cloudinary image URL.
    final data = jsonDecode(response.body);
    final url = data['profile_image_url'];

    if (url is! String || !url.startsWith('https://')) {
      throw Exception(
        'Upload response did not contain a valid image URL.',
      );
    }

    return url;
  }
}
