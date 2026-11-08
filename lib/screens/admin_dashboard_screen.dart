import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  
  int _currentTabIndex = 0; // 0: Moderation, 1: Events, 2: Clubs, 3: Users, 4: Profile
  String _selectedModerationFilter = 'All';
  String _selectedEventFilter = 'All';
  String _selectedClubFilter = 'All';
  String _selectedUserFilter = 'All';

  String _searchQuery = '';
  String _adminInitial = 'A';
  String _adminName = 'Admin';
  String _adminEmail = 'admin.nexora@campus.nexora.edu';
  String _adminId = 'NXR-ADMIN-2026-01';
  File? _profileImageFile;
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

  // Registered University Users list for Role Management
  final List _universityUsers = [
    {'name': 'Raveen Perera', 'email': 'raveen.p@campus.nexora.edu', 'role': 'Club President', 'status': 'Active'},
    {'name': 'Amal De Silva', 'email': 'amal.d@campus.nexora.edu', 'role': 'Student', 'status': 'Active'},
    {'name': 'Nimesha Fernando', 'email': 'nimesha.f@campus.nexora.edu', 'role': 'Student', 'status': 'Active'},
    {'name': 'Kasun Gunawardena', 'email': 'kasun.g@campus.nexora.edu', 'role': 'Club President', 'status': 'Active'},
  ];

  // Mock event submissions with correct upcoming dates (Nov/Dec 2026)
  final List _allEvents = [
    {
      'title': 'Tech Talk & Workshop 1',
      'category': 'TECHNOLOGY',
      'status': 'PENDING REVIEW',
      'timing': 'Upcoming',
      'organizer': 'IEEE Computer Society',
      'description': 'A 3-hour technical workshop covering cloud computing fundamentals and deployment pipelines.',
      'date': '15/11/2026 • 14:00',
      'location': 'Innovation Center',
      'registered': '45/100 Registered',
    },
    {
      'title': 'AI & Machine Learning Symposium',
      'category': 'TECHNOLOGY',
      'status': 'APPROVED',
      'timing': 'Upcoming',
      'organizer': 'Data Science Society',
      'description': 'An introduction to neural networks and real-world machine learning applications.',
      'date': '28/11/2026 • 10:00',
      'location': 'Auditorium A',
      'registered': '88/100 Registered',
    },
    {
      'title': 'Annual Drama Night Auditions',
      'category': 'CULTURAL',
      'status': 'REJECTED',
      'timing': 'Upcoming',
      'organizer': 'Arts & Drama Circle',
      'description': 'Open auditions for the upcoming university annual stage play production.',
      'date': '30/11/2026 • 16:30',
      'location': 'Student Center Hall',
      'registered': '0/50 Registered',
    },
    {
      'title': 'Windaneeya Handawa',
      'category': 'CULTURAL',
      'status': 'APPROVED',
      'timing': 'Upcoming',
      'organizer': 'Art Sub Committee',
      'description': 'Live acoustic music, drama performances, under the campus amphitheatre lights.',
      'date': '18/12/2026 • 17:00',
      'location': 'University Amphitheatre',
      'registered': '140/200 Registered',
    },
    {
      'title': 'Robotics Bootcamp 2026',
      'category': 'TECHNOLOGY',
      'status': 'APPROVED',
      'timing': 'Completed',
      'organizer': 'Robotics Club',
      'description': 'Hands-on hardware and microcontrollers programming bootcamp.',
      'date': '15/09/2026 • 10:00',
      'location': 'Engineering Lab 2',
      'registered': '50/50 Registered',
    },
  ];

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
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadSavedAdminProfile(); 
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

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
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
      if (item['timing'] == 'Upcoming' && _isClubInactive(item['organizer'])) {
        return false;
      }
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
    var list = _allEvents.where((item) => item['status'] == 'APPROVED').toList();
    
    list = list.where((item) {
      if (item['timing'] == 'Upcoming' && _isClubInactive(item['organizer'])) {
        return false;
      }
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

  List get _filteredUsers {
    var list = _universityUsers;
    if (_selectedUserFilter == 'Students') {
      list = list.where((u) => u['role'] == 'Student').toList();
    } else if (_selectedUserFilter == 'Presidents') {
      list = list.where((u) => u['role'] == 'Club President').toList();
    }
    return list;
  }

  void _updateStatus(Map item, String newStatus) {
    setState(() {
      item['status'] = newStatus;
      _systemNotifications.insert(0, 'Event "${item['title']}" status updated to $newStatus.');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${item['title']}" status updated to $newStatus.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
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
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
          _systemNotifications.insert(0, 'Admin profile photo updated successfully.');
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully!'), duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                  fontSize: 11,
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
                        onTap: () {
                          setState(() {
                            _currentTabIndex = 4;
                            _tabController.animateTo(4);
                          });
                        },
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
                                  backgroundImage: _profileImageFile != null
                                      ? FileImage(_profileImageFile!)
                                      : null,
                                  child: _profileImageFile == null
                                      ? Text(
                                          _adminInitial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
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

            // 5 Tabs Navigation Bar
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
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Moderation', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_rounded, size: 20),
                        SizedBox(height: 2),
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Events', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_rounded, size: 20),
                        SizedBox(height: 2),
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Clubs', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_rounded, size: 20),
                        SizedBox(height: 2),
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Users', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                  Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, size: 20),
                        SizedBox(height: 2),
                        FittedBox(fit: BoxFit.scaleDown, child: Text('Profile', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Greeting & Subtitle Area
            Padding(
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
                    Text(
                      _currentTabIndex == 0
                          ? 'Review pending approvals, monitor events, and manage system access.'
                          : _currentTabIndex == 1
                              ? 'Monitor and manage all active campus-wide events.'
                              : _currentTabIndex == 2
                                  ? 'Manage registered university clubs and student societies.'
                                  : _currentTabIndex == 3
                                      ? 'Manage registered students and club leadership access roles.'
                                      : 'Manage administrator account settings and preferences.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
                  children: [
                    _buildUserFilterPill('All'),
                    _buildUserFilterPill('Students'),
                    _buildUserFilterPill('Presidents'),
                  ],
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
                  _buildUsersTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 0: Moderation View
  Widget _buildModerationTab() {
    final submissions = _filteredSubmissions;

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
                                child: Text(item['category'], style: const TextStyle(color: purple, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                          const SizedBox(height: 4),
                          Text('Organized by: ${item['organizer']}', style: const TextStyle(color: blue, fontSize: 11.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(item['description'], style: const TextStyle(color: kTextGrey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: blue),
                              const SizedBox(width: 4),
                              Text(item['date'], style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on, size: 14, color: blue),
                              const SizedBox(width: 4),
                              Expanded(child: Text(item['location'], style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(item, 'PENDING REVIEW'),
                                icon: const Icon(Icons.edit_outlined, size: 16, color: blue),
                                label: const Text('Change Decision / Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: blue)),
                                style: OutlinedButton.styleFrom(side: BorderSide(color: blue.withValues(alpha: 0.5), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              ),
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
                                child: Text(event['category'], style: const TextStyle(color: purple, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: event['timing'] == 'Upcoming' ? blue.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(event['timing'], style: TextStyle(color: event['timing'] == 'Upcoming' ? blue : Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(event['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                          const SizedBox(height: 4),
                          Text('Organized by: ${event['organizer']}', style: const TextStyle(fontSize: 11.5, color: blue, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: blue),
                              const SizedBox(width: 4),
                              Text(event['date'], style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on, size: 14, color: blue),
                              const SizedBox(width: 4),
                              Expanded(child: Text(event['location'], style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
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
                                    Text(club['category'], style: const TextStyle(color: purple, fontSize: 10, fontWeight: FontWeight.bold)),
                                    InkWell(
                                      onTap: () => _showChangeClubStatusDialog(club),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(status, style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
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

  // Tab 3: Users & Role Management View
  Widget _buildUsersTab() {
    final users = _filteredUsers;

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
                Icon(Icons.admin_panel_settings, color: blue, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Manage user access roles across Nexora student accounts.', style: TextStyle(color: navy, fontSize: 12.5, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          users.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text('No users found for this filter.', style: TextStyle(color: Colors.white70, fontSize: 13))))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final bool isPresident = user['role'] == 'Club President';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isPresident ? purple : blue,
                            child: Text(user['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: navy)),
                                const SizedBox(height: 2),
                                Text(user['email'], style: const TextStyle(color: kTextGrey, fontSize: 11.5)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: isPresident ? purple.withValues(alpha: 0.12) : blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(user['role'], style: TextStyle(color: isPresident ? purple : blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isPresident,
                            activeThumbColor: purple,
                            onChanged: (val) {
                              setState(() {
                                user['role'] = val ? 'Club President' : 'Student';
                                _systemNotifications.insert(0, 'Role updated for ${user['name']} to ${user['role']}.');
                              });
                            },
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

  // Tab 4: Profile View
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
                    onTap: _changeProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [purple, blue, cyan])),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: navy,
                        backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                        child: _profileImageFile == null ? Text(_adminInitial, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)) : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _changeProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_adminName, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.bold)),
              Text(_adminEmail, style: const TextStyle(color: kTextGrey, fontSize: 12.5)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: blue.withValues(alpha: 0.3))),
                child: Text('Admin ID: $_adminId', style: const TextStyle(color: blue, fontSize: 11, fontWeight: FontWeight.bold)),
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
        _profileActionTile(Icons.logout_rounded, 'Log Out', () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully.'), duration: Duration(seconds: 2)));
        }, isDestructive: true),
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
            Text(label, style: const TextStyle(color: navy, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildUserFilterPill(String category) {
    bool isSelected = _selectedUserFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedUserFilter = category),
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