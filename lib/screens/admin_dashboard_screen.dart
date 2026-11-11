import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../login_screen.dart';
import '../services/api_service.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  
  int _currentTabIndex = 0; // Moderation, Events, Clubs, President Applications
  String _selectedPresidentFilter = 'All';
  bool _isLoadingPresidentApplications = false;
  String? _presidentApplicationsError;
  List<Map<String, dynamic>> _presidentApplications = [];
  String _selectedModerationFilter = 'All';
  String _selectedEventFilter = 'All';
  String _selectedClubFilter = 'All';

  String _searchQuery = '';
  String _adminInitial = 'A';
  String _adminName = 'Admin';
  String _adminEmail = 'admin.nexora@gmail.com';
  String _adminId = 'NXR-ADMIN-2026-01';
  String? _profileImageUrl;
  bool _isUploadingProfileImage = false;
  final ValueNotifier<int> _profileRevision = ValueNotifier<int>(0);
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  // Exact Brand Color Palette
  static const Color navy = Color(0xFF050B25);
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  static const Color purple = Color(0xFF8052F5);
  static const Color cyan = Color(0xFF19D9ED);
  static const Color kTextGrey = Color(0xFF64748B);

  // System notifications log
  final List<String> _systemNotifications = [
    'System initialized successfully with default security policies.',
    'New event submission received from IEEE Computer Society.',
    'Annual club roster audit completed.',
  ];


  // Real event proposals awaiting administrator review.
  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _approvedEvents = [];
  bool _eventsLoading = false;
  String? _eventsError;

  Future<void> _loadEventSubmissions() async {
    if (!mounted) return;
    setState(() { _eventsLoading = true; _eventsError = null; });
    try {
      final events = await ApiService.getPendingAdminEvents();
      final approved = await ApiService.getApprovedAdminEvents();
      if (!mounted) return;
      setState(() {
        _approvedEvents = approved.map((event) => {
          ...event,
          'title': (event['title'] ?? '').toString(),
          'category': (event['category'] ?? 'EVENT').toString(),
          'status': 'APPROVED',
          'timing': 'Upcoming',
          'organizer': (event['club_name'] ?? event['organizer'] ?? 'Club').toString(),
          'description': (event['description'] ?? '').toString(),
          'date': (event['event_date'] ?? '').toString(),
          'location': (event['location'] ?? '').toString(),
          'registered': '0/${event['capacity'] ?? 0} Registered',
        }).toList();
        _allEvents = events.map((event) => {
          ...event,
          'title': (event['title'] ?? '').toString(),
          'category': (event['category'] ?? 'EVENT').toString(),
          'status': 'PENDING REVIEW',
          'timing': 'Upcoming',
          'organizer': (event['club_name'] ?? event['organizer'] ?? 'Club').toString(),
          'description': (event['description'] ?? '').toString(),
          'date': (event['event_date'] ?? '').toString(),
          'location': (event['location'] ?? '').toString(),
          'registered': '0/${event['capacity'] ?? 0} Registered',
        }).toList();
      });
    } catch (error) {
      if (mounted) setState(() => _eventsError = error.toString());
    } finally {
      if (mounted) setState(() => _eventsLoading = false);
    }
  }

  // Campus clubs list
  final List _campusClubs = [
    {
      'name': 'IEEE Computer Society',
      'category': 'Technology',
      'members': '342 members',
      'status': 'Active',
      'initials': 'CS',
      'color': Colors.indigo,
    },
    {
      'name': 'Data Science Society',
      'category': 'Technology',
      'members': '210 members',
      'status': 'Active',
      'initials': 'DS',
      'color': Colors.teal,
    },
    {
      'name': 'Arts & Drama Circle',
      'category': 'Cultural',
      'members': '175 members',
      'status': 'Pending Renewal',
      'initials': 'AD',
      'color': Colors.purple,
    },
    {
      'name': 'Robotics Club',
      'category': 'Engineering',
      'members': '120 members',
      'status': 'Active',
      'initials': 'RC',
      'color': Colors.blueAccent,
    },
    {
      'name': 'Photography Society',
      'category': 'Media',
      'members': '95 members',
      'status': 'Inactive',
      'initials': 'PS',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadSavedAdminProfile();
    _loadRemoteAdminProfile();
    _loadPresidentApplications();
    _loadEventSubmissions(); 
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  Future<void> _loadSavedAdminProfile() async {
    String? savedName = await _storage.read(key: 'admin_name');
    String? savedEmail = await _storage.read(key: 'admin_email');
    String? savedId = await _storage.read(key: 'admin_id');
    
    if (savedName != null && savedName.isNotEmpty) {
      setState(() {
        _adminName = savedName;
        _adminInitial = savedName[0].toUpperCase();
      });
    }
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() => _adminEmail = savedEmail);
    }
    if (savedId != null && savedId.isNotEmpty) {
      setState(() => _adminId = savedId);
    }
  }

  // The server is the source of truth for the admin photo. This also runs
  // after a Remember Me session has been restored by the login/splash flow.
  Future<void> _loadRemoteAdminProfile() async {
    try {
      Map<String, dynamic> profile;
      try {
        profile = await ApiService.getProfile();
      } catch (_) {
        // An access token may have expired while a remembered refresh token
        // remains valid. Refresh once before retrying the profile request.
        if (!await ApiService.refreshSession()) rethrow;
        profile = await ApiService.getProfile();
      }
      if (!mounted) return;
      final url = profile['profile_image_url']?.toString().trim();
      final name = (profile['full_name'] ?? profile['name'])?.toString().trim();
      final email = profile['email']?.toString().trim();
      setState(() {
        _profileImageUrl = (url == null || url.isEmpty) ? null : url;
        if (name != null && name.isNotEmpty) {
          _adminName = name;
          _adminInitial = name[0].toUpperCase();
        }
        if (email != null && email.isNotEmpty) _adminEmail = email;
      });
      _profileRevision.value++;
    } catch (error) {
      debugPrint('Could not load admin profile: $error');
    }
  }

  ImageProvider<Object>? get _adminAvatarImage {
    final url = _profileImageUrl;
    return url == null || url.isEmpty ? null : NetworkImage(url);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    _profileRevision.dispose();
    super.dispose();
  }

  bool _isClubInactive(String organizerName) {
    final club = _campusClubs.firstWhere(
      (c) => c['name'] == organizerName,
      orElse: () => {'status': 'Active'},
    );
    return club['status'] == 'Inactive';
  }

  List get _filteredSubmissions {
    var list = _allEvents;
    
    list = list.where((item) {

      return true;
    }).toList();

    if (_selectedModerationFilter != 'All') {
      String filterValue = _selectedModerationFilter == 'Pending' 
          ? 'PENDING REVIEW' 
          : _selectedModerationFilter.toUpperCase();
      list = list.where((item) => item['status'] == filterValue).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) =>
          item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['organizer'].toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  List get _filteredSystemEvents {
    var list = _approvedEvents;
    
    list = list.where((item) {

      return true;
    }).toList();

    if (_selectedEventFilter != 'All') {
      list = list.where((item) => item['timing'] == _selectedEventFilter).toList();
    }
    return list;
  }

  List get _filteredClubs {
    var list = _campusClubs;
    if (_selectedClubFilter != 'All') {
      String filterVal = _selectedClubFilter == 'Renewal' ? 'Pending Renewal' : _selectedClubFilter;
      list = list.where((club) => club['status'] == filterVal).toList();
    }
    return list;
  }

  Future<void> _updateStatus(Map item, String newStatus) async {
    final eventId = int.tryParse('${item['event_id'] ?? ''}');
    if (eventId == null) return;
    final approve = newStatus == 'APPROVED';
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve event?' : 'Reject event?'),
        content: approve
            ? Text('Publish "${item['title']}" for students?')
            : TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason (required)',
                  border: OutlineInputBorder(),
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(approve ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (confirmed != true || !mounted) { reasonController.dispose(); return; }
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (!approve && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a rejection reason.')));
      return;
    }
    try {
      await ApiService.reviewAdminEvent(eventId, approve: approve, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Event approved and published.' : 'Event rejected.')));
      await _loadEventSubmissions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Review failed: $error')));
    }
  }

  void _showChangeClubStatusDialog(Map club) {
    String currentStatus = club['status'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Status: ${club['name']}', style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Active', 'Pending Renewal', 'Inactive'].map((status) {
            return RadioListTile<String>(
              title: Text(status, style: const TextStyle(fontSize: 13, color: navy, fontWeight: FontWeight.w600)),
              value: status,
              groupValue: currentStatus,
              activeColor: blue,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    club['status'] = val;
                    if (val == 'Inactive') {
                      _systemNotifications.insert(0, 'Club "${club['name']}" set to Inactive. Upcoming events hidden.');
                    } else {
                      _systemNotifications.insert(0, 'Club "${club['name']}" status changed to $val.');
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Club status updated to $val successfully.')),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: kTextGrey))),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController msgController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Broadcast Announcement', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send an instant push notification alert to all Nexora student portals.', style: TextStyle(color: kTextGrey, fontSize: 12.5)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Announcement Title',
                labelStyle: const TextStyle(color: kTextGrey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: msgController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message Body',
                labelStyle: const TextStyle(color: kTextGrey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kTextGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
            onPressed: () {
              if (titleController.text.isNotEmpty && msgController.text.isNotEmpty) {
                setState(() {
                  _systemNotifications.insert(0, 'Broadcast: ${titleController.text} - ${msgController.text}');
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement broadcasted successfully to all students!')),
                );
              }
            },
            child: const Text('Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClub(Map club) {
    final String clubName = club['name'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Club & Events', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "$clubName"? This will also remove all associated events organized by this club.',
          style: const TextStyle(color: kTextGrey, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: kTextGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _campusClubs.remove(club);
                _allEvents.removeWhere((event) => event['organizer'] == clubName);
                _systemNotifications.insert(0, 'Club "$clubName" and its events were deleted.');
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Club "$clubName" and its events deleted successfully.')),
              );
            },
            child: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploadingProfileImage) return;
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;
      Navigator.of(context).pop(); // Close the image source sheet.
      setState(() => _isUploadingProfileImage = true);
      _profileRevision.value++;
      final uploadedUrl = await ApiService.uploadProfileImage(pickedFile);
      if (!mounted) return;
      setState(() {
        _profileImageUrl = uploadedUrl;
        _systemNotifications.insert(0, 'Admin profile photo updated successfully.');
      });
      _profileRevision.value++;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo saved successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingProfileImage = false);
        _profileRevision.value++;
      }
    }
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Update Profile Picture",
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Select a photo from your device storage or camera.",
              style: TextStyle(color: kTextGrey, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: blue),
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: purple),
              ),
              title: const Text(
                "Take a Photo",
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSystemNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('System Notifications Log', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _systemNotifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.notifications_active_rounded, color: blue, size: 18),
                title: Text(_systemNotifications[index], style: const TextStyle(fontSize: 12, color: navy)),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProfileInfoDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(description, style: const TextStyle(color: kTextGrey, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your administrator account?',
          style: TextStyle(color: kTextGrey, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTextGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    try {
      // Clear locally stored authentication tokens.
      await ApiService.logout();

      if (!mounted) return;

      // Remove the dashboard and all previous routes from the navigation stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (error) {
      debugPrint('Logout error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep dashboard text at a consistent, normal size regardless of a
    // device's system font-scale setting.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              color: navy,
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/nexora_icon.png',
                          height: 38,
                          width: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: navyCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cyan.withValues(alpha: 0.5)),
                            ),
                            child: const Icon(Icons.school, color: cyan, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NEXORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: cyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Admin Portal',
                                style: TextStyle(
                                  color: cyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.campaign_rounded, color: cyan, size: 24),
                        tooltip: 'Broadcast Announcement',
                        onPressed: _showBroadcastDialog,
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _isSearchVisible ? Icons.close : Icons.search_rounded,
                            color: navy,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearchVisible = !_isSearchVisible;
                              if (!_isSearchVisible) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _openProfileScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cyan.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [purple, blue, cyan],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: navy,
                                  backgroundImage: _adminAvatarImage,
                                  child: _adminAvatarImage == null
                                      ? Text(
                                          _adminInitial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _adminName.split(' ').first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSearchVisible) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search submissions or organizers...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                        prefixIcon: const Icon(Icons.search, color: blue, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dashboard navigation
            Container(
              decoration: BoxDecoration(
                color: navy,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: cyan,
                indicatorWeight: 3.0,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: cyan,
                unselectedLabelColor: Colors.white54,
                labelPadding: EdgeInsets.zero,
                onTap: (index) {
                  setState(() => _currentTabIndex = index);
                  _tabController.animateTo(index);
                },
                tabs: const [
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 20),
                        SizedBox(height: 2),
                        Text('Moderation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_rounded, size: 20),
                        SizedBox(height: 2),
                        Text('Events', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_rounded, size: 20),
                        SizedBox(height: 2),
                        Text('Clubs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 20),
                        SizedBox(height: 2),
                        Text('President Apps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // The greeting belongs only to the moderation dashboard.
            if (_currentTabIndex == 0) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_adminName 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Review pending approvals, monitor events, and manage system access.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Responsive Wrap Layout for Filter Pills with Normal Font Size (12px)
            if (_currentTabIndex == 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildModerationFilterPill('All'),
                    _buildModerationFilterPill('Pending'),
                    _buildModerationFilterPill('Approved'),
                    _buildModerationFilterPill('Rejected'),
                  ],
                ),
              ),
            ] else if (_currentTabIndex == 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildEventFilterPill('All'),
                    _buildEventFilterPill('Upcoming'),
                    _buildEventFilterPill('Ongoing'),
                    _buildEventFilterPill('Completed'),
                  ],
                ),
              ),
            ] else if (_currentTabIndex == 2) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildClubFilterPill('All'),
                    _buildClubFilterPill('Active'),
                    _buildClubFilterPill('Renewal'),
                    _buildClubFilterPill('Inactive'),
                  ],
                ),
              ),
            ] else if (_currentTabIndex == 3) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: ['All', 'Pending', 'Approved', 'Rejected']
                      .map(_buildPresidentFilterPill)
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Main Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildModerationTab(),
                  _buildEventsTab(),
                  _buildClubsTab(),
                  _buildPresidentApplicationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _openProfileScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: AnimatedBuilder(
            animation: _profileRevision,
            builder: (context, _) => Scaffold(
            backgroundColor: navy,
            appBar: AppBar(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              title: const Text('Admin Profile', style: TextStyle(fontSize: 18)),
            ),
            body: SafeArea(child: _buildProfileTab()),
          ),
          ),
        ),
      ),
    );
  }


  Future<void> _loadPresidentApplications() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPresidentApplications = true;
      _presidentApplicationsError = null;
    });
    try {
      final result = await ApiService.getPresidentApplications();
      if (!mounted) return;
      setState(() {
        _presidentApplications = result;
        _isLoadingPresidentApplications = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _presidentApplicationsError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingPresidentApplications = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPresidentApplications {
    var items = _presidentApplications;
    if (_selectedPresidentFilter != 'All') {
      items = items.where((item) =>
        (item['status'] ?? '').toString().toLowerCase() ==
        _selectedPresidentFilter.toLowerCase()).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) =>
        (item['applicant_name'] ?? '').toString().toLowerCase().contains(query) ||
        (item['applicant_email'] ?? '').toString().toLowerCase().contains(query)).toList();
    }
    return items;
  }

  Widget _buildPresidentFilterPill(String value) {
    final selected = _selectedPresidentFilter == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) => setState(() => _selectedPresidentFilter = value),
      selectedColor: blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : navy,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? blue : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Future<void> _reviewPresidentApplication(Map<String, dynamic> item, bool approve) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve President Application?' : 'Reject President Application?'),
        content: approve
            ? const Text('This student will be granted Club President status.')
            : TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }
    try {
      if (approve) {
        await ApiService.approvePresidentApplication(id);
      } else {
        await ApiService.rejectPresidentApplication(
          id, reviewReason: reasonController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Application approved.' : 'Application rejected.')),
      );
      await _loadPresidentApplications();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update application: $error')),
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _showPresidentSupportingDocument(int id) async {
    try {
      final response = await ApiService.getPresidentApplicationDocument(id);
      if (!mounted) return;
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.startsWith('image/')) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.memory(response.bodyBytes, fit: BoxFit.contain),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document retrieved. PDF preview is not supported in this screen yet.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open supporting document: $error')),
      );
    }
  }

  Widget _buildPresidentApplicationsTab() {
    final applications = _filteredPresidentApplications;
    if (_isLoadingPresidentApplications) {
      return const Center(child: CircularProgressIndicator(color: cyan));
    }
    if (_presidentApplicationsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 36),
              const SizedBox(height: 10),
              Text(_presidentApplicationsError!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadPresidentApplications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPresidentApplications,
      child: applications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 70),
                Icon(Icons.inbox_outlined, color: Colors.white54, size: 42),
                SizedBox(height: 12),
                Center(child: Text('No President Applications found.',
                    style: TextStyle(color: Colors.white70))),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: applications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = applications[index];
                final status = (item['status'] ?? 'pending').toString().toLowerCase();
                final pending = status == 'pending';
                final statusColor = status == 'approved'
                    ? Colors.green : status == 'rejected' ? Colors.redAccent : Colors.orange;
                final id = int.tryParse(item['id'].toString()) ?? 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(
                            (item['applicant_name'] ?? 'Student').toString(),
                            style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 15),
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text((item['applicant_email'] ?? '').toString(),
                        style: const TextStyle(color: kTextGrey, fontSize: 12)),
                      const SizedBox(height: 12),
                      const Text('Proposed club',
                        style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Name: ${item['club_name'] ?? 'Legacy application'}\nCategory: ${item['category'] ?? '-'}\nDescription: ${item['description'] ?? item['reason'] ?? '-'}',
                        style: const TextStyle(color: kTextGrey, fontSize: 12)),
                      if ((item['created_at'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Submitted: ${item['created_at']}',
                          style: const TextStyle(color: kTextGrey, fontSize: 12)),
                      ],
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: id == 0 ? null : () => _showPresidentSupportingDocument(id),
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('View supporting document'),
                      ),
                      if (pending) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(
                              onPressed: () => _reviewPresidentApplication(item, true),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, foregroundColor: Colors.white,
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _reviewPresidentApplication(item, false),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                            )),
                          ],
                        ),
                      ] else if ((item['review_reason'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Review note: ${item['review_reason']}',
                          style: const TextStyle(color: kTextGrey, fontSize: 12)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Tab 0: Moderation View
  Widget _buildModerationTab() {
    final submissions = _filteredSubmissions;
    if (_eventsLoading) return const Center(child: CircularProgressIndicator());
    if (_eventsError != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_eventsError!, style: const TextStyle(color: Colors.white)),
      TextButton(onPressed: _loadEventSubmissions, child: const Text('Retry')),
    ]));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statBox('Students', '1,240', blue),
              const SizedBox(width: 8),
              _statBox('Pending', '${_allEvents.where((e) => e['status'] == 'PENDING REVIEW').length}', Colors.orange),
              const SizedBox(width: 8),
              _statBox('Clubs', '${_campusClubs.length}', purple),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: blue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _searchQuery.isEmpty ? 'Review campus event submissions requiring authorization.' : 'Showing search results for "$_searchQuery"',
                    style: const TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          submissions.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('No submissions found.', style: TextStyle(color: Colors.white70, fontSize: 13))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = submissions[index];
                    final String status = item['status'];
                    final bool isPending = status == 'PENDING REVIEW';

                    Color statusColor = Colors.orange;
                    if (status == 'APPROVED') statusColor = Colors.green;
                    if (status == 'REJECTED') statusColor = Colors.redAccent;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(item['category'], style: const TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                          const SizedBox(height: 4),
                          Text('Organized by: ${item['organizer']}', style: const TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(item['description'], style: const TextStyle(color: kTextGrey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: blue),
                              const SizedBox(width: 4),
                              Text(item['date'], style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on, size: 14, color: blue),
                              const SizedBox(width: 4),
                              Expanded(child: Text(item['location'], style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
                          if (isPending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateStatus(item, 'APPROVED'),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Approve', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateStatus(item, 'REJECTED'),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Reject', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Tab 1: Events Management View
  Widget _buildEventsTab() {
    final events = _filteredSystemEvents;
    if (_eventsLoading) return const Center(child: CircularProgressIndicator());
    if (_eventsError != null) return Center(child: Text(_eventsError!, style: const TextStyle(color: Colors.white)));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
            child: Row(
              children: const [
                Icon(Icons.event_available_rounded, color: blue, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Active approved campus events and attendee tracking.', style: TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          events.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('No approved events found.', style: TextStyle(color: Colors.white70, fontSize: 13))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(event['category'], style: const TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: event['timing'] == 'Upcoming' ? blue.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(event['timing'], style: TextStyle(color: event['timing'] == 'Upcoming' ? blue : Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(event['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                          const SizedBox(height: 4),
                          Text('Organized by: ${event['organizer']}', style: const TextStyle(fontSize: 12, color: blue, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: blue),
                              const SizedBox(width: 4),
                              Text(event['date'], style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on, size: 14, color: blue),
                              const SizedBox(width: 4),
                              Expanded(child: Text(event['location'], style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(event['registered'], style: const TextStyle(fontSize: 12, color: kTextGrey, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Tab 2: Clubs View with Manual Status Override and Event Auto-Hiding
  Widget _buildClubsTab() {
    final clubs = _filteredClubs;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
            child: Row(
              children: const [
                Icon(Icons.group_work_rounded, color: blue, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Registered university clubs, societies, and leadership rosters.', style: TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          clubs.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('No clubs found for this filter status.', style: TextStyle(color: Colors.white70, fontSize: 13))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clubs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    final String status = club['status'];
                    
                    Color statusBgColor = Colors.green.withValues(alpha: 0.12);
                    Color statusTextColor = Colors.green;
                    if (status == 'Pending Renewal') {
                      statusBgColor = Colors.orange.withValues(alpha: 0.12);
                      statusTextColor = Colors.orange;
                    } else if (status == 'Inactive') {
                      statusBgColor = Colors.redAccent.withValues(alpha: 0.12);
                      statusTextColor = Colors.redAccent;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: club['color'], radius: 22, child: Text(club['initials'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(club['category'], style: const TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.bold)),
                                    InkWell(
                                      onTap: () => _showChangeClubStatusDialog(club),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(status, style: TextStyle(color: statusTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 3),
                                            Icon(Icons.edit, size: 10, color: statusTextColor),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(club['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navy)),
                                const SizedBox(height: 2),
                                Text(club['members'], style: const TextStyle(fontSize: 12, color: kTextGrey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                            tooltip: 'Delete Club',
                            onPressed: () => _confirmDeleteClub(club),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // Profile screen, opened from the account control in the dashboard header.
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6))]),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _isUploadingProfileImage ? null : _changeProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [purple, blue, cyan])),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: navy,
                        backgroundImage: _adminAvatarImage,
                        child: _adminAvatarImage == null ? Text(_adminInitial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)) : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isUploadingProfileImage ? null : _changeProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              if (_isUploadingProfileImage) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
                const Text("Uploading photo...", style: TextStyle(color: kTextGrey)),
              ],
              const SizedBox(height: 12),
              Text(_adminName, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.bold)),
              Text(_adminEmail, style: const TextStyle(color: kTextGrey, fontSize: 12.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: blue.withValues(alpha: 0.3))),
                child: Text('Admin ID: $_adminId', style: const TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      String nameField = _adminName;
                      String emailField = _adminEmail;
                      String idField = _adminId;
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Update Admin Profile', style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 18)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              style: const TextStyle(color: navy, fontSize: 13.5),
                              decoration: InputDecoration(labelText: 'Full Name', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              controller: TextEditingController(text: _adminName),
                              onChanged: (val) => nameField = val,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              style: const TextStyle(color: navy, fontSize: 13.5),
                              decoration: InputDecoration(labelText: 'Email Address', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              controller: TextEditingController(text: _adminEmail),
                              onChanged: (val) => emailField = val,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              style: const TextStyle(color: navy, fontSize: 13.5),
                              decoration: InputDecoration(labelText: 'Admin ID', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              controller: TextEditingController(text: _adminId),
                              onChanged: (val) => idField = val,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: kTextGrey))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white),
                            onPressed: () async {
                              setState(() {
                                _adminName = nameField;
                                _adminEmail = emailField;
                                _adminId = idField;
                                _adminInitial = nameField.isNotEmpty ? nameField[0].toUpperCase() : _adminInitial;
                                _systemNotifications.insert(0, 'Admin profile details updated successfully.');
                              });

                              await _storage.write(key: 'admin_name', value: _adminName);
                              await _storage.write(key: 'admin_email', value: _adminEmail);
                              await _storage.write(key: 'admin_id', value: _adminId);

                              Navigator.pop(context);
                            },
                            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.edit, size: 15, color: blue),
                label: const Text("Edit Profile Details", style: TextStyle(color: blue, fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFBFDBFE)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _profileActionTile(Icons.notifications_active_outlined, 'System Notifications', _showSystemNotificationsDialog),
        _profileActionTile(Icons.privacy_tip_outlined, 'Privacy & Policies', () {
          _showProfileInfoDialog('Privacy & Policies', 'NEXORA data privacy compliance v2.4: All student credentials and logs are strictly protected under university data governance policies.');
        }),
        _profileActionTile(
          Icons.logout_rounded,
          'Log Out',
          _logout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _profileActionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : blue, size: 21),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : navy, fontSize: 13.5, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildModerationFilterPill(String category) {
    bool isSelected = _selectedModerationFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedModerationFilter = category),
      selectedColor: blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : navy, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? blue : const Color(0xFFCBD5E1))),
    );
  }

  Widget _buildEventFilterPill(String category) {
    bool isSelected = _selectedEventFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedEventFilter = category),
      selectedColor: blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : navy, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? blue : const Color(0xFFCBD5E1))),
    );
  }

  Widget _buildClubFilterPill(String category) {
    bool isSelected = _selectedClubFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedClubFilter = category),
      selectedColor: blue,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : navy, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? blue : const Color(0xFFCBD5E1))),
    );
  }

}
