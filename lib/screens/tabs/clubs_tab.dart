import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/club_model.dart';
import '../../services/auth_storage.dart';
import '../../services/api_service.dart';

class ClubsTab extends StatefulWidget {
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

  @override
  State<ClubsTab> createState() => _ClubsTabState();
}

class _ClubsTabState extends State<ClubsTab> {
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  static const Color cyan = Color(0xFF19D9ED);

  List<Club> _clubs = [];
  Map<String, dynamic>? _application;
  bool _loading = true;
  List<Map<String, dynamic>> _presidentClubs = [];
  String? _error;

  String get _status => ((_application?['application'] is Map ? _application!['application']['status'] : _application?['status']) ?? '').toString().toLowerCase();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    // Fetch the two resources independently. A failure to fetch clubs must
    // never hide a President Application that has already been approved.
    List<Club>? loadedClubs;
    Map<String, dynamic>? loadedApplication;
    final errors = <String>[];

    try {
      loadedApplication = await ApiService.getMyPresidentApplication();
    } catch (error) {
      errors.add('President status: ${error.toString().replaceFirst('Exception: ', '')}');
    }

    try {
      loadedClubs = await ApiService.getClubs();
    } catch (error) {
      errors.add('Clubs: ${error.toString().replaceFirst('Exception: ', '')}');
    }

    List<Map<String, dynamic>>? ownedClubs;
    final status = ((loadedApplication?['application'] is Map
        ? loadedApplication!['application']['status']
        : loadedApplication?['status']) ?? '').toString().toLowerCase();
    if (status == 'approved') {
      try { ownedClubs = await ApiService.getMyPresidentClubs(); }
      catch (error) { errors.add('President clubs: $error'); }
    }
    if (!mounted) return;
    setState(() {
      if (ownedClubs != null) _presidentClubs = ownedClubs;
      _clubs = loadedClubs ?? (widget.clubs.isNotEmpty ? widget.clubs : _clubs);
      // Preserve a previously verified status if refreshing fails.
      if (loadedApplication != null || !errors.any((e) => e.startsWith('President status:'))) {
        _application = loadedApplication;
      }
      _error = errors.isEmpty ? null : errors.join(' | ');
      _loading = false;
    });
  }

  Future<void> _openApplication() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ClubRegistrationPage()),
    );
    if (submitted == true && mounted) await _loadData();
  }

  Future<void> _openClubRegistration() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ClubRegistrationPage()),
    );
    if (submitted == true && mounted) await _loadData();
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEventPage(clubs: _presidentClubs)),
    );
    if (created == true && mounted) await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await widget.onRefresh();
      },
      color: cyan,
      backgroundColor: navyCard,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          const Text('Campus Clubs & Societies',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Join official societies to receive private meetups and notifications.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 14),
          if (_loading && _clubs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator(color: cyan)),
            )
          else if (status == 'approved')
            _actionCard(
              icon: Icons.add_business_rounded,
              title: 'President Request Approved',
              subtitle: 'Please log out and sign in again to open your President Dashboard.',
              action: 'Awaiting re-login',
              color: cyan,
              onTap: () {},
            )
          else if (status == 'pending')
            _statusCard(
              title: 'President Application Pending',
              message: 'Your club and President application is awaiting administrator approval.',
              icon: Icons.hourglass_top_rounded,
              color: Colors.orangeAccent,
            )
          else if (status == 'rejected')
            _statusCard(
              title: 'President Application Rejected',
              message: ((_application?['application'] is Map ? _application!['application']['review_reason'] : _application?['review_reason']) ?? 'Your application was not approved.').toString(),
              icon: Icons.cancel_outlined,
              color: Colors.redAccent,
            )
          else if (_error != null && _error!.contains('President status:') && _application == null)
            _statusCard(
              title: 'Unable to verify President status',
              message: 'Please retry before submitting another application.',
              icon: Icons.error_outline,
              color: Colors.orangeAccent,
            )
          else
            _actionCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Register a Club & Apply as President & Become President',
              subtitle: 'Submit your club details and appointment letter for one administrator approval.',
              action: 'Apply Now',
              color: cyan,
              onTap: _openApplication,
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text('Could not refresh club information: $_error',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: cyan),
              label: const Text('Retry', style: TextStyle(color: cyan)),
            ),
          ],
          const SizedBox(height: 14),
          if (!_loading && _clubs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No approved clubs are available yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 13))),
            ),
          ..._clubs.map(_buildClubCard),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF102451),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.65)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF203D78),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.35)),
                const SizedBox(height: 7),
                Text(action, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            )),
            Icon(Icons.arrow_forward_ios, color: color, size: 15),
          ]),
        ),
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102451),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
        ])),
      ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(club.name,
              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Text('${club.memberCount} members',
              style: const TextStyle(color: Color(0xFF059669), fontSize: 11)),
        ]),
        const SizedBox(height: 6),
        Text(club.description, style: const TextStyle(color: Colors.black, fontSize: 12)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: club.isJoined ? navyCard : blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => widget.onToggleJoinClub(club),
            child: Text(club.isJoined ? 'Joined ✓' : 'Join Club +',
                style: TextStyle(color: club.isJoined ? Colors.white70 : Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}

class PresidentApplicationPage extends StatefulWidget {
  const PresidentApplicationPage({super.key});

  @override
  State<PresidentApplicationPage> createState() => _PresidentApplicationPageState();
}

class _PresidentApplicationPageState extends State<PresidentApplicationPage> {
  static const Color navy = Color(0xFF050B25);
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color cyan = Color(0xFF19D9ED);
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  PlatformFile? _document;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (file == null || !mounted) return;
      final fileSize = await file.length();
      if (fileSize == null || fileSize <= 0 || fileSize > 5 * 1024 * 1024) {
        _showMessage('Choose a readable PDF or image no larger than 5 MB.');
        return;
      }
      setState(() => _document = file);
    } catch (error) {
      _showMessage('Unable to select document: $error');
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_document == null) {
      _showMessage('Please attach your supporting document.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.submitPresidentApplication(
        reason: _reasonController.text,
        supportingDocument: _document!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('President Application submitted successfully.'),
        backgroundColor: Color(0xFF059669),
      ));
      Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('President Application'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF102451),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cyan.withValues(alpha: 0.45)),
            ),
            child: const Text(
              'Apply to become a Club President. Your application and supporting document will be reviewed by a Nexora administrator. You can register a club only after approval.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Why do you want to become a Club President?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reasonController,
            minLines: 4,
            maxLines: 6,
            maxLength: 2000,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Explain your experience, motivation and plans...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: navyCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cyan, width: 1.5),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please provide an application reason.'
                : null,
          ),
          const SizedBox(height: 14),
          const Text('Supporting document',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text('PDF, JPG or PNG • Maximum 5 MB',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickDocument,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_document?.name ?? 'Choose supporting document',
                overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: cyan,
              side: const BorderSide(color: cyan),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3478FF),
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
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
  static const String _baseUrl = ApiService.baseUrl;

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
      final fileSize = await file.length();
      if (fileSize == null || fileSize <= 0 || fileSize > 5 * 1024 * 1024) {
        _showMessage('Choose a readable PDF or image no larger than 5 MB.', isError: true);
        return;
      }
      setState(() => _appointmentLetter = file);
    } catch (error) {
      if (mounted) _showMessage('Unable to select the file: $error', isError: true);
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
        Uri.parse('$_baseUrl/api/president-applications/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['club_name'] = _clubNameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['description'] = _descriptionController.text.trim();

      final file = _appointmentLetter!;

      // Read the selected file.
      final fileBytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'supporting_document',
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
              'Your club and President application is pending admin review. Approval will create your club and assign you as its President.',
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
          'Register a Club & Apply as President',
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
                        'Submit your club details and official appointment letter. One Nexora administrator approval will create your club and assign you as President.',
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
                          'Submit Application',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your club and President membership are created together after approval.',
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


class AddEventPage extends StatefulWidget {
  final List<Map<String, dynamic>> clubs;
  const AddEventPage({super.key, required this.clubs});
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  String _category = 'Technology';
  int? _clubId;
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;
  static const _navy = Color(0xFF050B25);
  static const _cyan = Color(0xFF19D9ED);

  @override
  void initState() {
    super.initState();
    if (widget.clubs.isNotEmpty) _clubId = widget.clubs.first['club_id'] as int;
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose(); _location.dispose(); _capacity.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
    filled: true, fillColor: const Color(0xFF102451),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white30)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _cyan)),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
  );

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_clubId == null || _date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select your club, date and time.')));
      return;
    }
    final dateTime = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    if (!dateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future date and time.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.createEvent(
        clubId: _clubId!, title: _title.text, category: _category,
        description: _description.text, dateTime: dateTime,
        location: _location.text, capacity: int.parse(_capacity.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event published successfully.')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _navy,
    appBar: AppBar(title: const Text('Add New Event'), backgroundColor: _navy, foregroundColor: Colors.white),
    body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Create an event for your approved club. The event will be published immediately.',
        style: TextStyle(color: Colors.white70)),
      _label('Organizing club'),
      DropdownButtonFormField<int>(
        initialValue: _clubId, dropdownColor: const Color(0xFF102451),
        style: const TextStyle(color: Colors.white), decoration: _dec('Choose club'),
        items: widget.clubs.map((c) => DropdownMenuItem<int>(
          value: c['club_id'] as int, child: Text(c['club_name'].toString()),
        )).toList(),
        onChanged: (v) => setState(() => _clubId = v),
        validator: (v) => v == null ? 'Choose a club' : null,
      ),
      _label('Event title'),
      TextFormField(controller: _title, style: const TextStyle(color: Colors.white),
        decoration: _dec('Nexora Annual Hackathon 2026'), maxLength: 200,
        validator: (v) => v == null || v.trim().isEmpty ? 'Enter event title' : null),
      _label('Category'),
      DropdownButtonFormField<String>(
        initialValue: _category, dropdownColor: const Color(0xFF102451),
        style: const TextStyle(color: Colors.white), decoration: _dec('Category'),
        items: ['Technology', 'Cultural', 'Sports', 'Academic', 'Arts', 'Social Service', 'Other']
          .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _category = v ?? 'Technology'),
      ),
      _label('Description'),
      TextFormField(controller: _description, style: const TextStyle(color: Colors.white),
        decoration: _dec('Describe the event'), minLines: 3, maxLines: 5,
        validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null),
      _label('Date and time'),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month),
          label: Text(_date == null ? 'Choose date' : '${_date!.day}/${_date!.month}/${_date!.year}'),
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 1825)));
            if (d != null && mounted) setState(() => _date = d);
          },
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          icon: const Icon(Icons.access_time),
          label: Text(_time == null ? 'Choose time' : _time!.format(context)),
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (t != null && mounted) setState(() => _time = t);
          },
        )),
      ]),
      _label('Venue'),
      TextFormField(controller: _location, style: const TextStyle(color: Colors.white),
        decoration: _dec('Innovation Center'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Enter venue' : null),
      _label('Total available spots'),
      TextFormField(controller: _capacity, keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white), decoration: _dec('100'),
        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter a positive whole number' : null),
      const SizedBox(height: 28),
      ElevatedButton(
        onPressed: _saving ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3478FF), foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52)),
        child: Text(_saving ? 'Submitting...' : 'Publish Event'),
      ),
      const SizedBox(height: 20),
    ])),
  );
}
