import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../login_screen.dart';
import '../models/event_model.dart';
import '../models/rsvp_model.dart';
import '../models/ticket_model.dart';
import '../models/club_model.dart';
import 'tabs/explore_tab.dart';
import 'tabs/my_passes_tab.dart';
import 'tabs/clubs_tab.dart';
import 'tabs/profile_tab.dart';

class StudentDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const StudentDashboardScreen({super.key, this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  File? _profileImage; // Selected student profile picture file

  // Exact Brand Color Palette
  static const Color navy = Color(0xFF050B25);
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  // static const Color purple = Color(0xFF8052F5);
  static const Color cyan = Color(0xFF19D9ED);

  final List<String> _categories = [
    'All',
    'Technology',
    'Cultural',
    'Sports',
    'Workshop',
    'Career',
  ];

  // In-Memory Frontend Mock Data (100% Backend-Free)
  late List<Event> _events;
  late List<Club> _clubs;
  late List<RsvpItem> _myRsvps;
  final Set<int> _checkedInRsvpIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _events = [
      Event(
        eventId: 101,
        title: 'Nexora Annual Hackathon 2026',
        description: 'A 24-hour university coding sprint where student teams build innovative AI and campus software solutions.',
        description: 'A 24-hour university coding sprint where student teams build innovative AI and campus software solutions.',
        category: 'Technology',
        eventDate: DateTime.now().add(const Duration(days: 3, hours: 4)),
        location: 'Innovation Center',
        capacity: 100,
        rsvpCount: 88,
        clubName: 'IEEE Computer Society',
      ),
      Event(
        eventId: 102,
        title: 'windaneeya Handawa',
        description: 'Live acoustic music, drama performances, under the campus amphitheatre lights.',
        description: 'Live acoustic music, drama performances, under the campus amphitheatre lights.',
        category: 'Cultural',
        eventDate: DateTime.now().add(const Duration(days: 6, hours: 8)),
        location: 'Prof.J.W.Dayananda Somasundara Audiitorium',
        capacity: 200,
        rsvpCount: 140,
        clubName: 'Art Sub Committee',
      ),
    ];

    _clubs = [
      Club(
        clubId: 1,
        clubName: 'IEEE Computer Society',
        category: 'Technology',
        presidentName: 'Kavindu Perera',
        description: 'Premier student branch for software engineers, competitive coders, and system hackers.',
        description: 'Premier student branch for software engineers, competitive coders, and system hackers.',
        memberCount: 342,
        isJoined: true,
      ),
    ];

    _myRsvps = [
      RsvpItem(
        rsvpId: 501,
        status: 'confirmed',
        registeredAt: DateTime.now().subtract(const Duration(days: 1)),
        event: _events[0],
        ticket: Ticket(
          ticketId: 701,
          qrCode: 'NEXORA-PASS-101-AC88',
          issuedAt: DateTime.now().subtract(const Duration(days: 1)),
          isCheckedIn: false,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _userName =>
      widget.user?['name'] ?? widget.user?['email'] ?? 'Amal De Silva';
  String get _userEmail =>
      widget.user?['email'] ?? 'amal.silva@campus.nexora.edu';
  String get _userName =>
      widget.user?['name'] ?? widget.user?['email'] ?? 'Amal De Silva';
  String get _userEmail =>
      widget.user?['email'] ?? 'amal.silva@campus.nexora.edu';

  List<Event> get _filteredEvents {
    return _events.where((event) {
      final matchesCat =
          _selectedCategory == 'All' ||
      final matchesCat =
          _selectedCategory == 'All' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
      final matchesSearch =
          query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.clubName.toLowerCase().contains(query);
      return matchesCat && matchesSearch;
    }).toList();
  }

  Map<String, dynamic> get _stats => {
    'total_rsvps': _myRsvps.length,
    'upcoming_events': _myRsvps.length,
    'attended_events': _checkedInRsvpIds.length + 1,
    'clubs_joined': _clubs.where((c) => c.isJoined).length,
  };
    'total_rsvps': _myRsvps.length,
    'upcoming_events': _myRsvps.length,
    'attended_events': _checkedInRsvpIds.length + 1,
    'clubs_joined': _clubs.where((c) => c.isJoined).length,
  };

  bool _isRsvpd(int eventId) {
    return _myRsvps.any((r) => r.event.eventId == eventId);
  }

  void _showFloatingSnackBar({
    required String message,
    Color backgroundColor = Colors.white,
    Color textColor = navy,
    IconData icon = Icons.info_outline,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  // Frontend RSVP Toggle
  void _handleRsvp(Event event) {
    if (_isRsvpd(event.eventId)) {
      final r = _myRsvps.firstWhere(
        (item) => item.event.eventId == event.eventId,
      );
      final r = _myRsvps.firstWhere(
        (item) => item.event.eventId == event.eventId,
      );
      _showQrTicketModal(r);
      return;
    }

    if (event.isFull) {
      _showFloatingSnackBar(
        message: 'This event has reached maximum capacity.',
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        icon: Icons.error_outline,
      );
      return;
    }

    final newRsvp = RsvpItem(
      rsvpId: DateTime.now().millisecondsSinceEpoch % 10000,
      status: 'confirmed',
      registeredAt: DateTime.now(),
      event: event,
      ticket: Ticket(
        ticketId: 200 + event.eventId,
        qrCode: 'NEXORA-PASS-${event.eventId}-AC88',
        issuedAt: DateTime.now(),
      ),
    );

    setState(() {
      event.rsvpCount += 1;
      _myRsvps.insert(0, newRsvp);
    });

    _showFloatingSnackBar(
      message: 'RSVP confirmed for ${event.title}!',
      backgroundColor: const Color(0xFF10B981),
      textColor: Colors.white,
      icon: Icons.check_circle_rounded,
      action: SnackBarAction(
        label: 'View Pass',
        textColor: Colors.white,
        onPressed: () => _showQrTicketModal(newRsvp),
      ),
    );
  }

  // Frontend Cancel RSVP
  Future<void> _handleCancelRsvp(RsvpItem rsvp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Cancel RSVP?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        title: const Text(
          'Cancel RSVP?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Release your admission ticket for ${rsvp.event.title}?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep Pass',
              style: TextStyle(color: Colors.white60),
            ),
            child: const Text(
              'Keep Pass',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel RSVP'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      rsvp.event.rsvpCount = (rsvp.event.rsvpCount - 1).clamp(0, 9999);
      _myRsvps.removeWhere((r) => r.rsvpId == rsvp.rsvpId);
    });

    _showFloatingSnackBar(
      message: 'RSVP cancelled. Spot released.',
      backgroundColor: Colors.orangeAccent.shade700,
      textColor: Colors.white,
      icon: Icons.info_outline,
    );
  }

  // ==================== IMAGE PICKER (DEVICE GALLERY / CAMERA) ====================
  Future<void> _pickProfileImage(ImageSource source) async {
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
          _profileImage = File(pickedFile.path);
        });
        if (mounted) {
          Navigator.pop(context);
          _showFloatingSnackBar(
            message: 'Profile picture updated successfully!',
            backgroundColor: const Color(0xFF10B981),
            textColor: Colors.white,
            icon: Icons.check_circle_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showFloatingSnackBar(
          message: 'Failed to pick image: $e',
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showImagePickerModal() {
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
              "Select a photo from your device storage to update your profile.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.1),
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
              subtitle: const Text(
                "Select an image file from device gallery",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              onTap: () => _pickProfileImage(ImageSource.gallery),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8052F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: const Color(0xFF8052F5),
                ),
              ),
              title: const Text(
                "Take a Photo",
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              subtitle: const Text(
                "Open camera and take a new photo",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              onTap: () => _pickProfileImage(ImageSource.camera),
            ),
            if (_profileImage != null) ...[
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  "Remove Current Photo",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _profileImage = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ==================== PRIVACY & POLICIES MODAL ====================
  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: blue, size: 24),
                SizedBox(width: 8),
                Text(
                  "Privacy & Student Policies",
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Nexora Student Code of Conduct, Pass Verification & Privacy Rules",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 18),
            _policySection(
              icon: Icons.lock_outline,
              iconColor: blue,
              title: "1. Student Data Confidentiality",
              description: "Your university student ID, academic email, and RSVP registrations are securely stored and only accessible to authorized campus event coordinators.",
            ),
            _policySection(
              icon: Icons.qr_code_2_rounded,
              iconColor: const Color(0xFF10B981),
              title: "2. Digital Event Passes & Attendance",
              description: "Each QR pass issued is uniquely tied to your Student ID. Passes are non-transferable, and attendance is directly logged for official extracurricular activity credits.",
            ),
            _policySection(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF8052F5),
              title: "3. Campus Club Membership",
              description: "Joining student clubs grants access to private workshops and voting in committee elections. You can leave or join clubs at any time through the portal.",
            ),
            _policySection(
              icon: Icons.rule_rounded,
              iconColor: Colors.orange,
              title: "4. Campus Event Regulations",
              description: "All attendees must adhere to university conduct bylaws at campus venues (auditoriums, labs, amphitheatre). Failure to comply may lead to pass revocation.",
            ),
            _policySection(
              icon: Icons.mail_outline_rounded,
              iconColor: cyan,
              title: "5. Student Affairs Inquiries",
              description: "For questions regarding event passes, club certifications, or data privacy, contact the Student Affairs Council at studentaffairs@nexora.edu.",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "I Understand & Agree",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _policySection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STUDENT EVENT NOTIFICATIONS MODAL ====================
  void _showStudentNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: blue, size: 22),
                SizedBox(width: 8),
                Text(
                  "Event Notifications & Reminders",
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Pass confirmations, starting reminders & club announcements for you.",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Notification 1: Upcoming Event Reminder (Linked to My Passes)
            _studentNotificationCard(
              icon: Icons.confirmation_number_rounded,
              iconColor: const Color(0xFF10B981),
              title: "Upcoming Event: Nexora Hackathon 2026",
              subtitle: "Starts in 3 days at Innovation Center. Bring your laptop and show your QR pass.",
              time: "Today • 10:00 AM",
              actionLabel: "View Pass",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(1); // My Passes Tab
              },
            ),

            // Notification 2: Club Announcement (Linked to Clubs)
            _studentNotificationCard(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF8052F5),
              title: "IEEE Computer Society: Orientation Alert",
              subtitle: "Pre-hackathon orientation session starts tomorrow at 4:00 PM.",
              time: "Yesterday • 16:30",
              actionLabel: "View Club",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(2); // Clubs Tab
              },
            ),

            // Notification 3: Venue & Stage Update (Linked to Explore)
            _studentNotificationCard(
              icon: Icons.celebration_rounded,
              iconColor: Colors.orange,
              title: "windaneeya Handawa: Stage Confirmation",
              subtitle: "Prof. J.W. Dayananda Auditorium doors open at 18:00. Free student entry.",
              time: "2 days ago",
              actionLabel: "Explore Event",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0); // Explore Tab
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _studentNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                    InkWell(
                      onTap: onAction,
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          color: blue,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // QR Digital Admission Pass Viewer
  void _showQrTicketModal(RsvpItem rsvp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final ticket = rsvp.ticket;
        final qrString =
            ticket?.qrCode ?? 'NEXORA-PASS-${rsvp.event.eventId}-AC88';
        final isCheckedIn =
            (ticket?.isCheckedIn ?? false) ||
            _checkedInRsvpIds.contains(rsvp.rsvpId);
        final qrString =
            ticket?.qrCode ?? 'NEXORA-PASS-${rsvp.event.eventId}-AC88';
        final isCheckedIn =
            (ticket?.isCheckedIn ?? false) ||
            _checkedInRsvpIds.contains(rsvp.rsvpId);
        final screenWidth = MediaQuery.of(ctx).size.width;
        final qrSize = (screenWidth * 0.44).clamp(140.0, 190.0);

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cyan.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: cyan.withOpacity(0.3),
                                ),
                                border: Border.all(
                                  color: cyan.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'DIGITAL ADMISSION PASS',
                                style: TextStyle(
                                  color: cyan,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rsvp.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Organized by: ${rsvp.event.clubName}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isCheckedIn
                              ? blue.withOpacity(0.2)
                              : const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCheckedIn ? blue : const Color(0xFF10B981),
                          ),
                        ),
                        child: Text(
                          isCheckedIn ? 'CHECKED IN' : 'VALID PASS',
                          style: TextStyle(
                            color: isCheckedIn ? cyan : const Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CustomPaint(
                          size: Size(qrSize, qrSize),
                          painter: _QrCodePainter(qrString),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          qrString,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: navyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoTile('Attendee', _userName),
                        Container(width: 1, height: 28, color: Colors.white12),
                        _infoTile(
                          'Date',
                          '${rsvp.event.eventDate.day}/${rsvp.event.eventDate.month}/${rsvp.event.eventDate.year}',
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        _infoTile('Venue', rsvp.event.location),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _checkedInRsvpIds.add(rsvp.rsvpId);
                              });
                              _showFloatingSnackBar(
                                message:
                                    'Entrance scan verified! Pass checked in.',
                                message:
                                    'Entrance scan verified! Pass checked in.',
                                backgroundColor: const Color(0xFF10B981),
                                textColor: Colors.white,
                                icon: Icons.verified_rounded,
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Simulate Scan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(
                                'Simulate Scan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cyan,
                              side: const BorderSide(color: cyan, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: qrString));
                              _showFloatingSnackBar(
                                message: 'Ticket code copied to clipboard!',
                                backgroundColor: navyCard,
                                textColor: Colors.white,
                                icon: Icons.copy_rounded,
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Copy Pass ID',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Text(
                                'Copy Pass ID',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar with Logo & Student Profile Pill
            _buildMobileAppHeader(),

            // Welcome Header (Prominently visible when app opens - matching President Dashboard)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              color: navy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, $_userName 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Explore campus events, manage your passes & clubs.",
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),

            // Responsive 4 Tabs Navigation Bar
            _buildResponsiveTabBar(),

            // 4 Modular Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Explore Events
                  ExploreTab(
                    events: _filteredEvents,
                    isLoading: false,
                    selectedCategory: _selectedCategory,
                    categories: _categories,
                    onCategorySelected: (cat) {
                      setState(() => _selectedCategory = cat);
                    },
                    onRsvp: _handleRsvp,
                    onRefresh: () async {},
                    isRsvpd: _isRsvpd,
                  ),

                  // Tab 2: My Passes & QR
                  MyPassesTab(
                    rsvps: _myRsvps,
                    onRefresh: () async {},
                    onCancelRsvp: _handleCancelRsvp,
                    onShowQrModal: _showQrTicketModal,
                  ),

                  // Tab 3: Campus Clubs
                  ClubsTab(
                    clubs: _clubs,
                    isLoading: false,
                    onRefresh: () async {},
                    onToggleJoinClub: (club) {
                      setState(() {
                        club.isJoined = !club.isJoined;
                      });
                      _showFloatingSnackBar(
                        message: club.isJoined
                            ? 'Joined ${club.clubName}!'
                            : 'Left ${club.clubName}.',
                        backgroundColor: club.isJoined
                            ? const Color(0xFF10B981)
                            : Colors.white,
                        backgroundColor: club.isJoined
                            ? const Color(0xFF10B981)
                            : Colors.white,
                        textColor: club.isJoined ? Colors.white : navy,
                        icon: club.isJoined
                            ? Icons.check_circle
                            : Icons.info_outline,
                        icon: club.isJoined
                            ? Icons.check_circle
                            : Icons.info_outline,
                      );
                    },
                  ),

                  // Tab 4: Student Profile (With Photo Upload & Privacy Policies)
                  ProfileTab(
                    userName: _userName,
                    userEmail: _userEmail,
                    rsvpCount: _myRsvps.length,
                    stats: _stats,
                    profileImage: _profileImage,
                    onUpdateProfilePhoto: _showImagePickerModal,
                    onOpenPrivacyPolicy: _showPrivacyPolicyModal,
                    onOpenNotifications: _showStudentNotificationsModal,
                    onNavigateToTab: (index) {
                      _tabController.animateTo(index);
                    },
                    onLogout: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    onShowSnackBar: ({required String message}) {
                      _showFloatingSnackBar(
                        message: message,
                        backgroundColor: Colors.white,
                        textColor: navy,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppHeader() {
    String initial = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A';

    return Container(
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
                  errorBuilder: (_, __, ___) => Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: navyCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cyan.withOpacity(0.5)),
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
                        'Student Portal',
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

              // Search Button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
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
                        _searchController.clear();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: navy,
                    size: 19,
                  ),
                  onPressed: () {
                    _showFloatingSnackBar(
                      message: 'No new campus announcements right now.',
                      backgroundColor: navyCard,
                      textColor: Colors.white,
                      icon: Icons.notifications_active_outlined,
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isSearchVisible) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              style: const TextStyle(
                color: navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search campus events, clubs, venues...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(Icons.search, color: blue, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                        icon: const Icon(
                          Icons.clear,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: blue, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: navy,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
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
        tabs: [
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.explore_rounded, size: 22),
                SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Explore',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                    'Explore',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: _myRsvps.isNotEmpty,
                  label: Text(
                    '${_myRsvps.length}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: blue,
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    size: 22,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'My Passes',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                    'My Passes',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.groups_rounded, size: 22),
                SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Clubs',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                    'Clubs',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person_rounded, size: 22),
                SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Profile',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  child: Text(
                    'Profile',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for realistic QR Code simulation
class _QrCodePainter extends CustomPainter {
  final String data;
  _QrCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF050B25)
      ..style = PaintingStyle.fill;

    final double cellSize = size.width / 21;

    void drawFinder(double x, double y) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, 7 * cellSize, 7 * cellSize),
        paint,
      );
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 1) * cellSize,
          (y + 1) * cellSize,
          5 * cellSize,
          5 * cellSize,
        ),
          (x + 1) * cellSize,
          (y + 1) * cellSize,
          5 * cellSize,
          5 * cellSize,
        ),
        whitePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 2) * cellSize,
          (y + 2) * cellSize,
          3 * cellSize,
          3 * cellSize,
        ),
          (x + 2) * cellSize,
          (y + 2) * cellSize,
          3 * cellSize,
          3 * cellSize,
        ),
        paint,
      );
    }

    drawFinder(0, 0);
    drawFinder(14, 0);
    drawFinder(0, 14);

    final int hash = data.hashCode.abs();
    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        if ((r < 8 && c < 8) || (r < 8 && c > 12) || (r > 12 && c < 8)) {
          continue;
        }
        if (((r * 31 + c * 17 + hash) % 3) == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

