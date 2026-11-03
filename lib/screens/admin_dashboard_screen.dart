import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminDashboardScreen(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0; // 0: Moderation, 1: Events, 2: Clubs, 3: Profile
  
  String _selectedModerationFilter = 'All';
  String _selectedEventFilter = 'All';
  String _selectedClubFilter = 'All';

  String _searchQuery = '';
  String _adminInitial = 'N';
  String _adminName = 'Nadee';
  String _adminEmail = 'admin.nexora@campus.nexora.edu';
  File? _profileImageFile;

  // System notifications log
  final List<String> _systemNotifications = [
    'System initialized successfully with default security policies.',
    'New event submission received from IEEE Computer Society.',
    'Annual club roster audit completed.',
  ];

  // Mock event submissions for the Moderation tab
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
      'date': '28/10/2026 • 10:00',
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
      'date': '30/10/2026 • 16:30',
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

  List get _filteredSubmissions {
    var list = _allEvents;
    if (_selectedModerationFilter != 'All') {
      list = list.where((item) => item['status'] == _selectedModerationFilter.toUpperCase()).toList();
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
    if (_selectedEventFilter != 'All') {
      list = list.where((item) => item['timing'] == _selectedEventFilter).toList();
    }
    return list;
  }

  List get _filteredClubs {
    var list = _campusClubs;
    if (_selectedClubFilter != 'All') {
      list = list.where((club) => club['status'] == _selectedClubFilter).toList();
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
      ),
    );
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          backgroundColor: const Color(0xFF131B31),
          title: const Text('Search Submissions', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter title or organizer...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
            ),
            onChanged: (val) => tempQuery = val,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: const Color(0xFF0B1021)),
              onPressed: () {
                setState(() => _searchQuery = tempQuery);
                Navigator.pop(context);
              },
              child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImageFile = File(image.path);
        _systemNotifications.insert(0, 'Admin profile photo updated from gallery.');
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully!'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _changeProfilePicture() {
    String tempInit = _adminInitial;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131B31),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Change Profile Photo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFF0B1021)),
                    label: const Text('Upload Photo from Gallery', style: TextStyle(color: Color(0xFF0B1021), fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Or update initial letter:', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 8),
                  TextField(
                    maxLength: 1,
                    style: const TextStyle(color: Colors.white),
                    controller: TextEditingController(text: tempInit),
                    decoration: const InputDecoration(
                      hintText: 'Enter single letter',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        tempInit = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: const Color(0xFF0B1021)),
                  onPressed: () {
                    if (tempInit.isNotEmpty) {
                      setState(() {
                        _adminInitial = tempInit.toUpperCase();
                        _profileImageFile = null;
                        _systemNotifications.insert(0, 'Admin profile initial updated to "$_adminInitial".');
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSystemNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131B31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('System Notifications Log', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _systemNotifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.notifications, color: Color(0xFF00E5FF), size: 18),
                title: Text(_systemNotifications[index], style: const TextStyle(fontSize: 12, color: Colors.white70)),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: const Color(0xFF0B1021)),
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
        backgroundColor: const Color(0xFF131B31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: const Color(0xFF0B1021)),
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
      backgroundColor: const Color(0xFF0B1021),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B31),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/nexora_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text('N', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'NEXORA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '• Admin Portal',
                            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.search, color: Colors.black, size: 18),
                          onPressed: _openSearchDialog,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _currentTabIndex = 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0B1021)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                                ),
                                child: Center(
                                  child: _profileImageFile != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(_profileImageFile!, fit: BoxFit.cover),
                                        )
                                      : Text(
                                          _adminInitial,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Admin',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4-Tab Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTopTabItem(0, Icons.admin_panel_settings_outlined, 'Moderation'),
                  _buildTopTabItem(1, Icons.event_note_outlined, 'Events'),
                  _buildTopTabItem(2, Icons.group_outlined, 'Clubs'),
                  _buildTopTabItem(3, Icons.person_outline, 'Profile'),
                ],
              ),
            ),

            // Thick Divider line
            const Divider(color: Colors.white24, height: 1, thickness: 3),
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
                                  : 'Manage administrator account settings and preferences.',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Dynamic Filter Pills
            if (_currentTabIndex == 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    _buildModerationFilterPill('All'),
                    _buildModerationFilterPill('Pending Review'),
                    _buildModerationFilterPill('Approved'),
                    _buildModerationFilterPill('Rejected'),
                  ],
                ),
              ),
            ] else if (_currentTabIndex == 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    _buildClubFilterPill('All'),
                    _buildClubFilterPill('Active'),
                    _buildClubFilterPill('Pending Renewal'),
                    _buildClubFilterPill('Inactive'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSelectedTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabItem(int index, IconData icon, String label) {
    bool isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white60, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          if (isSelected)
            Container(
              height: 3,
              width: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildModerationTab();
      case 1:
        return _buildEventsTab();
      case 2:
        return _buildClubsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildModerationTab();
    }
  }

  // Tab 0: Moderation / Approvals View
  Widget _buildModerationTab() {
    final submissions = _filteredSubmissions;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Review campus event submissions requiring authorization.'
                        : 'Showing search results for "$_searchQuery"',
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Text('Clear', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          submissions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'No submissions found.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = submissions[index];
                    final String status = item['status'];
                    final bool isPending = status == 'PENDING REVIEW';

                    Color statusColor = Colors.orange;
                    if (status == 'APPROVED') statusColor = Colors.green;
                    if (status == 'REJECTED') statusColor = Colors.red;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['category'],
                                  style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'],
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1021)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Organized by: ${item['organizer']}',
                            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['description'],
                            style: const TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(item['date'], style: const TextStyle(color: Colors.black54, fontSize: 11)),
                              const Spacer(),
                              const Icon(Icons.location_on, size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(item['location'], style: const TextStyle(color: Colors.black54, fontSize: 11)),
                            ],
                          ),
                          const Divider(height: 20),
                          if (isPending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateStatus(item, 'APPROVED'),
                                      icon: const Icon(Icons.check, size: 14),
                                      label: const Text('Approve', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateStatus(item, 'REJECTED'),
                                      icon: const Icon(Icons.close, size: 14),
                                      label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 34,
                              child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(item, 'PENDING REVIEW'),
                                icon: const Icon(Icons.edit_outlined, size: 14, color: Colors.blueAccent),
                                label: const Text('Change Decision / Status', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: const [
                Icon(Icons.event_available, color: Colors.blueAccent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active approved campus events and attendee tracking.',
                    style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          events.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('No approved events found. Approve events in the Moderation tab!', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(event['category'], style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: event['timing'] == 'Upcoming' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event['timing'],
                                  style: TextStyle(
                                    color: event['timing'] == 'Upcoming' ? Colors.blue : Colors.grey[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(event['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1021))),
                          const SizedBox(height: 2),
                          Text('Organized by: ${event['organizer']}', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(event['registered'], style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(event['date'], style: const TextStyle(color: Colors.black54, fontSize: 11)),
                              const Spacer(),
                              const Icon(Icons.location_on, size: 12, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(event['location'], style: const TextStyle(color: Colors.black54, fontSize: 11)),
                            ],
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

  // Tab 2: Clubs View
  Widget _buildClubsTab() {
    final clubs = _filteredClubs;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: const [
                Icon(Icons.group_work, color: Colors.blueAccent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Registered university clubs, societies, and leadership rosters.',
                    style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          clubs.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('No clubs found for this filter status.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clubs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    final String status = club['status'];
                    
                    Color statusBgColor = Colors.green.withOpacity(0.1);
                    Color statusTextColor = Colors.green;
                    if (status == 'Pending Renewal') {
                      statusBgColor = Colors.orange.withOpacity(0.1);
                      statusTextColor = Colors.orange;
                    } else if (status == 'Inactive') {
                      statusBgColor = Colors.red.withOpacity(0.1);
                      statusTextColor = Colors.red;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: club['color'],
                            radius: 22,
                            child: Text(
                              club['initials'],
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      club['category'],
                                      style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  club['name'],
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1021)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  club['members'],
                                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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

  // Tab 3: Profile View (Styled matching the student dashboard)
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _changeProfilePicture,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0B1021), Color(0xFF131B31)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _profileImageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(40),
                                        child: Image.file(_profileImageFile!, fit: BoxFit.cover, width: 80, height: 80),
                                      )
                                    : Text(
                                        _adminInitial,
                                        style: const TextStyle(fontSize: 34, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00E5FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Color(0xFF0B1021), size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _adminName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1021)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _adminEmail,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Admin ID: NXR-ADMIN-2026-01',
                          style: TextStyle(color: Color(0xFF003366), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _ProfileStatBox(title: 'Moderated', count: '${_allEvents.length}')),
                    const SizedBox(width: 8),
                    Expanded(child: _ProfileStatBox(title: 'Clubs', count: '${_campusClubs.length}')),
                    const SizedBox(width: 8),
                    const Expanded(child: _ProfileStatBox(title: 'Users', count: '420')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildProfileMenuCard(Icons.person_outline, const Color(0xFF0B1021), 'Update Admin Profile', onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                String nameField = _adminName;
                String emailField = _adminEmail;
                return AlertDialog(
                  backgroundColor: const Color(0xFF131B31),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Update Admin Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white70)),
                        controller: TextEditingController(text: _adminName),
                        onChanged: (val) => nameField = val,
                      ),
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white70)),
                        controller: TextEditingController(text: _adminEmail),
                        onChanged: (val) => emailField = val,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: const Color(0xFF0B1021)),
                      onPressed: () {
                        setState(() {
                          _adminName = nameField;
                          _adminEmail = emailField;
                          _adminInitial = nameField.isNotEmpty ? nameField[0].toUpperCase() : _adminInitial;
                          _systemNotifications.insert(0, 'Admin profile details updated successfully.');
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            );
          }),
          _buildProfileMenuCard(Icons.security, const Color(0xFF0B1021), 'Access Control & Roles', onTap: () {
            _showProfileInfoDialog('Access Control & Roles', 'System Administrator has absolute root privileges across event moderation, user access control, and club accreditation settings.');
          }),
          _buildProfileMenuCard(Icons.notifications_outlined, const Color(0xFF0B1021), 'System Notifications', onTap: _showSystemNotificationsDialog),
          _buildProfileMenuCard(Icons.privacy_tip_outlined, const Color(0xFF0B1021), 'Security & Policies', onTap: () {
            _showProfileInfoDialog('Security & Policies', 'NEXORA secure authentication protocol v2.4 enforced with SSL encryption.');
          }),
          _buildProfileMenuCard(Icons.logout, Colors.red, 'Log Out', isLogout: true, onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully.'), duration: Duration(seconds: 2)),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildModerationFilterPill(String category) {
    bool isSelected = _selectedModerationFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedModerationFilter = category),
      selectedColor: const Color(0xFF00E5FF),
      backgroundColor: Colors.white.withOpacity(0.9),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B1021) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent),
      ),
    );
  }

  Widget _buildEventFilterPill(String category) {
    bool isSelected = _selectedEventFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedEventFilter = category),
      selectedColor: const Color(0xFF00E5FF),
      backgroundColor: Colors.white.withOpacity(0.9),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B1021) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent),
      ),
    );
  }

  Widget _buildClubFilterPill(String category) {
    bool isSelected = _selectedClubFilter == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedClubFilter = category),
      selectedColor: const Color(0xFF00E5FF),
      backgroundColor: Colors.white.withOpacity(0.9),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B1021) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent),
      ),
    );
  }

  Widget _buildProfileMenuCard(IconData icon, Color iconColor, String title, {bool isLogout = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileStatBox extends StatelessWidget {
  final String title;
  final String count;
  const _ProfileStatBox({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1021))),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}