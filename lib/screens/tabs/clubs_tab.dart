import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/club_model.dart';
import '../../services/auth_storage.dart';

class ClubsTab extends StatelessWidget {
  final List<Club> clubs;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<Club> onToggleJoinClub;

  const ClubsTab({
    super.key,
    required this.clubs,
    required this.isLoading,
    required this.onRefresh,
    required this.onToggleJoinClub,
  });

  static const Color navy = Color(0xFF050B25);
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  static const Color cyan = Color(0xFF19D9ED);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cyan,
      backgroundColor: navyCard,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          const Text(
            'Campus Clubs & Societies',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join official societies to receive private meetups and notifications.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          _registerClubButton(context),
          const SizedBox(height: 14),
          if (isLoading && clubs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(color: cyan),
              ),
            )
          else if (clubs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No clubs are available yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            )
          else
            ...clubs.map(_buildClubCard),
        ],
      ),
    );
  }

  Widget _registerClubButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ClubRegistrationPage(),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF102451),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cyan.withValues(alpha: 0.75)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF203D78),
                child: Icon(Icons.add_business_rounded, color: cyan, size: 20),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register a New Club',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Apply to establish and manage a university club.',
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: cyan, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  club.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${club.memberCount} members',
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            club.description,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: club.isJoined ? navyCard : blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => onToggleJoinClub(club),
              child: Text(
                club.isJoined ? 'Joined ✓' : 'Join Club +',
                style: TextStyle(
                  color: club.isJoined ? Colors.white70 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClubRegistrationPage extends StatefulWidget {
  const ClubRegistrationPage({super.key});

  @override
  State<ClubRegistrationPage> createState() => _ClubRegistrationPageState();
}

class _ClubRegistrationPageState extends State<ClubRegistrationPage> {
  static const Color navy = Color(0xFF050B25);
  static const Color blue = Color(0xFF3478FF);
  static const Color cyan = Color(0xFF19D9ED);
  static const String _baseUrl =
      'https://nexora-event-mgmt-api.onrender.com';

  final _formKey = GlobalKey<FormState>();
  final _clubNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const List<String> _categories = [
    'Technology',
    'Cultural',
    'Sports',
    'Academic',
    'Arts',
    'Social Service',
    'Other',
  ];

  String? _selectedCategory;
  PlatformFile? _appointmentLetter;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _clubNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  
Future<void> _chooseAppointmentLetter() async {
  try {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (file == null || !mounted) return;

    // Check file size (maximum 5 MB).
    final fileSize = file.lengthSync() ?? await file.length();

    if (!mounted) return;

    if (fileSize == null) {
      _showMessage(
        'Could not determine file size. Please try again.',
        isError: true,
      );
      return;
    }

    if (fileSize == 0) {
      _showMessage(
        'The selected file is empty.',
        isError: true,
      );
      return;
    }

    if (fileSize > 5 * 1024 * 1024) {
      _showMessage(
        'The appointment letter must be 5 MB or smaller.',
        isError: true,
      );
      return;
    }

    setState(() {
      _appointmentLetter = file;
    });

  } catch (error) {
    if (!mounted) return;

    _showMessage(
      'Unable to select the file: $error',
      isError: true,
    );
  }
}


  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showMessage('Please select a club category.', isError: true);
      return;
    }
    if (_appointmentLetter == null) {
      _showMessage('Please attach your appointment letter.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Your session has expired. Please log in again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/club-registration/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['club_name'] = _clubNameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['description'] = _descriptionController.text.trim();

      final file = _appointmentLetter!;

      // Read the selected file.
      final fileBytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'appointment_letter',
        fileBytes,
        filename: file.name,
      );

request.files.add(multipartFile);
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = null;
      }

      if (response.statusCode == 201) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(child: Text('Application submitted')),
              ],
            ),
            content: const Text(
              'Your club registration request has been submitted and is pending admin review. You will receive the President role only after approval.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        throw Exception(_extractError(responseData, response.statusCode));
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _extractError(dynamic data, int statusCode) {
    if (data is Map) {
      final detail = data['detail'] ?? data['message'];
      if (detail != null) return detail.toString();
      final messages = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          messages.add('$key: ${value.join(', ')}');
        } else {
          messages.add('$key: $value');
        }
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return 'Registration failed (HTTP $statusCode). Please try again.';
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // Use hintText instead of labelText so the placeholder stays inside
  // the field and never floats above it when the field receives focus.
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF7B8495),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: Icon(icon, color: blue, size: 21),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 52,
        minHeight: 52,
      ),
      filled: true,
      fillColor: const Color(0xFFF3F5F9),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Register a Club',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF102451),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: cyan.withValues(alpha: 0.45)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: cyan, size: 21),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Submit your club details and official appointment letter. The Nexora administrator will review your application before the club is registered.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Club name'),
              TextFormField(
                controller: _clubNameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 150,
                style: const TextStyle(
                  color: Color(0xFF0B1021),
                  fontSize: 16,
                ),
                decoration: _decoration(
                  'Enter the official club name',
                  Icons.groups_outlined,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the club name.'
                    : null,
              ),
              const SizedBox(height: 10),
              _fieldLabel('Club category'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                // Keep the popup readable against the Nexora dark theme.
                dropdownColor: const Color(0xFF102451),
                borderRadius: BorderRadius.circular(12),
                menuMaxHeight: 300,
                style: const TextStyle(
                  color: Color(0xFF0B1021),
                  fontSize: 16,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF7B8495),
                ),
                decoration: _decoration(
                  'Select a category',
                  Icons.category_outlined,
                ),
                hint: const Text(
                  'Select a category',
                  style: TextStyle(
                    color: Color(0xFF7B8495),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                selectedItemBuilder: (BuildContext context) {
  return _categories.map((category) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF102451),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }).toList();
},
                items: _categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Club description'),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Color(0xFF0B1021),
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlignVertical: TextAlignVertical.top,
                decoration: _decoration(
                  'Describe the club and its activities',
                  Icons.description_outlined,
                ).copyWith(
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a description.'
                    : null,
              ),
              const SizedBox(height: 10),
              _fieldLabel('Official appointment letter'),
              const Text(
                'Accepted formats: PDF, JPG, JPEG, PNG. Maximum size: 5 MB.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _chooseAppointmentLetter,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(_appointmentLetter == null ? 'Choose appointment letter' : 'Change selected file'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cyan,
                  side: const BorderSide(color: cyan),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
              if (_appointmentLetter != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102451),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: cyan),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _appointmentLetter!.name,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove file',
                        onPressed: _isSubmitting ? null : () => setState(() => _appointmentLetter = null),
                        icon: const Icon(Icons.close, color: Colors.white70, size: 19),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 25),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: blue.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.3, color: Colors.white),
                        )
                      : const Text(
                          'Submit Registration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Submitting this form does not immediately make you a club president. The role is assigned after an administrator approves the application.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 10.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
