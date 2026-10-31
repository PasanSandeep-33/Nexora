import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    home: PresidentDashboard(),
    debugShowCheckedModeBanner: false,
  ),
);

class PresidentDashboard extends StatefulWidget {
  const PresidentDashboard({super.key});

  @override
  State<PresidentDashboard> createState() => _PresidentDashboardState();
}

class _PresidentDashboardState extends State<PresidentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Student Dashboard Matching Colors (Navy Blue Background + White Cards)
  static const Color kBgColor = Color(0xFF050B25); // Deep Navy Background
  static const Color kNavyCard = Color(0xFF0F1A4E); // Secondary Navy
  static const Color kWhiteCard = Colors.white; // Clean White Card Color
  static const Color kBlue = Color(0xFF3478FF); // Primary Blue
  static const Color kPurple = Color(0xFF8052F5); // Accent Purple
  static const Color kCyan = Color(0xFF19D9ED); // Accent Cyan
  static const Color kTextGrey = Color(0xFF64748B);

  // Club President Profile Details
  String presidentName = "Raveen Perera";
  String presidentEmail = "raveen.p@campus.nexora.edu";
  String presidentClub = "IEEE Computer Society";
  String presidentId = "NXR-PRES-2026-01";
  File? profileImage; // Real image file selected from device gallery or camera

  // 1. Club Events List (CRUD Data)
  final List<Map<String, dynamic>> clubEvents = [
    {
      "id": "1",
      "category": "TECHNOLOGY",
      "title": "Nexora Annual Hackathon 2026",
      "organizer": "Organized by: IEEE Computer Society",
      "description": "A 24-hour university coding sprint where student teams build innovative AI and campus software solutions.",
      "date": "22/10/2026 • 23:54",
      "venue": "Innovation Center",
      "status": "APPROVED",
    },
    {
      "id": "2",
      "category": "CULTURAL",
      "title": "Windaneeya Handawa",
      "organizer": "Organized by: IEEE Computer Society",
      "description": "Live acoustic music, drama performances, under the campus amphitheatre lights.",
      "date": "26/10/2026 • 18:30",
      "venue": "Prof. J.W. Dayananda Amphitheatre",
      "status": "PENDING",
    },
  ];

  // 2. Registered Participants List (Scan Removed - Only Check In / Undo)
  final List<Map<String, dynamic>> participants = [
    {
      "name": "Alex Chen",
      "studentId": "NXR-2026-CS88",
      "email": "alex.chen@campus.nexora.edu",
      "eventTitle": "Nexora Annual Hackathon 2026",
      "ticket": "NEXORA-TKT-101-AC88",
      "checkedIn": true,
    },
    {
      "name": "Chaduni De Silva",
      "studentId": "NXR-2026-CS12",
      "email": "chaduni.d@campus.nexora.edu",
      "eventTitle": "Nexora Annual Hackathon 2026",
      "ticket": "NEXORA-TKT-101-CD12",
      "checkedIn": true,
    },
    {
      "name": "Kavindu Perera",
      "studentId": "NXR-2026-SE45",
      "email": "kavindu.p@campus.nexora.edu",
      "eventTitle": "Nexora Annual Hackathon 2026",
      "ticket": "NEXORA-TKT-101-KP45",
      "checkedIn": false,
    },
    {
      "name": "Amaya Wijesinghe",
      "studentId": "NXR-2026-DS19",
      "email": "amaya.w@campus.nexora.edu",
      "eventTitle": "Windaneeya Handawa",
      "ticket": "NEXORA-TKT-102-AW19",
      "checkedIn": false,
    },
  ];

  // Event Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  String _selectedCategory = "TECHNOLOGY";

  // Participants Filter State
  String _selectedEventFilter = "All Events";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // 3 Separate Tabs: 0 = Events, 1 = Participants, 2 = Profile
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  // ==================== CREATE / UPDATE EVENT DIALOG ====================
  void _showEventDialog({Map<String, dynamic>? existingEvent}) {
    if (existingEvent != null) {
      _titleController.text = existingEvent["title"];
      _descController.text = existingEvent["description"];
      _venueController.text = existingEvent["venue"];
      _selectedCategory = existingEvent["category"];
    } else {
      _titleController.clear();
      _descController.clear();
      _venueController.clear();
      _selectedCategory = "TECHNOLOGY";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kWhiteCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existingEvent == null ? "Create Club Event" : "Update Club Event",
            style: const TextStyle(
              color: kBgColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Event Title",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                TextField(
                  controller: _venueController,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Venue",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  dropdownColor: kWhiteCard,
                  style: const TextStyle(color: kBgColor),
                  items: ["TECHNOLOGY", "CULTURAL", "SPORTS", "WORKSHOP"]
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: const TextStyle(color: kBgColor),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: kTextGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    if (existingEvent == null) {
                      clubEvents.add({
                        "id": DateTime.now().toString(),
                        "category": _selectedCategory,
                        "title": _titleController.text,
                        "organizer": "Organized by: $presidentClub",
                        "description": _descController.text,
                        "date": "30/10/2026 • 10:00",
                        "venue": _venueController.text,
                        "status": "PENDING",
                      });
                    } else {
                      existingEvent["title"] = _titleController.text;
                      existingEvent["description"] = _descController.text;
                      existingEvent["venue"] = _venueController.text;
                      existingEvent["category"] = _selectedCategory;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(existingEvent == null ? "Publish" : "Save Changes"),
            ),
          ],
        );
      },
    );
  }

  // Delete Event Function
  void _deleteEvent(String id) {
    setState(() {
      clubEvents.removeWhere((event) => event["id"] == id);
    });
  }

  // ==================== ADD PARTICIPANT DIALOG ====================
  void _showAddParticipantDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController idCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    String selectedEvent = clubEvents.isNotEmpty
        ? clubEvents.first["title"]
        : "Nexora Annual Hackathon 2026";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kWhiteCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add Participant",
            style: TextStyle(color: kBgColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Student Name",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                TextField(
                  controller: idCtrl,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Student ID",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: kBgColor),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedEvent,
                  isExpanded: true,
                  dropdownColor: kWhiteCard,
                  style: const TextStyle(color: kBgColor),
                  items: clubEvents
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e["title"],
                          child: Text(
                            e["title"],
                            style: const TextStyle(color: kBgColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedEvent = val;
                  },
                  decoration: const InputDecoration(
                    labelText: "Event",
                    labelStyle: TextStyle(color: kTextGrey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: kTextGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    participants.insert(0, {
                      "name": nameCtrl.text,
                      "studentId": idCtrl.text.isEmpty
                          ? "NXR-2026-CS99"
                          : idCtrl.text,
                      "email": emailCtrl.text.isEmpty
                          ? "student@campus.nexora.edu"
                          : emailCtrl.text,
                      "eventTitle": selectedEvent,
                      "ticket":
                          "NEXORA-TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}",
                      "checkedIn": false,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // ==================== EDIT PRESIDENT PROFILE DIALOG ====================
  void _showEditProfileDialog() {
    final TextEditingController nameCtrl = TextEditingController(
      text: presidentName,
    );
    final TextEditingController emailCtrl = TextEditingController(
      text: presidentEmail,
    );
    final TextEditingController clubCtrl = TextEditingController(
      text: presidentClub,
    );
    final TextEditingController idCtrl = TextEditingController(
      text: presidentId,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kWhiteCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Edit President Profile",
            style: TextStyle(color: kBgColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: kBgColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: const TextStyle(color: kTextGrey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: kBgColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: "Official Email",
                    labelStyle: const TextStyle(color: kTextGrey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clubCtrl,
                  style: const TextStyle(color: kBgColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: "Club Name",
                    labelStyle: const TextStyle(color: kTextGrey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idCtrl,
                  style: const TextStyle(color: kBgColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: "President ID",
                    labelStyle: const TextStyle(color: kTextGrey),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: kTextGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    presidentName = nameCtrl.text.trim();
                    presidentEmail = emailCtrl.text.trim();
                    presidentClub = clubCtrl.text.trim();
                    presidentId = idCtrl.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile details updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }

  // ==================== SELECT PHOTO FROM GALLERY / CAMERA ====================
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
          profileImage = File(pickedFile.path);
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profile picture updated successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to pick image: $e"),
            backgroundColor: Colors.redAccent,
          ),
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
                color: kBgColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Select an image file from your device to update your photo.",
              style: TextStyle(color: kTextGrey, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: kBlue),
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(
                  color: kBgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              subtitle: const Text(
                "Select a photo from device storage",
                style: TextStyle(color: kTextGrey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: kTextGrey,
              ),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: kPurple),
              ),
              title: const Text(
                "Take a Photo",
                style: TextStyle(
                  color: kBgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              subtitle: const Text(
                "Open camera and take a new picture",
                style: TextStyle(color: kTextGrey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: kTextGrey,
              ),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            if (profileImage != null) ...[
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
                    profileImage = null;
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

  // ==================== NOTIFICATIONS CENTER MODAL ====================
  void _showNotificationsModal() {
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
                Icon(Icons.notifications_active, color: kBlue, size: 22),
                SizedBox(width: 8),
                Text(
                  "Event Notifications & Alerts",
                  style: TextStyle(
                    color: kBgColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              "Recent approval updates, student RSVPs, and university reminders.",
              style: TextStyle(color: kTextGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _notificationTile(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              title: "Event Approved: Nexora Hackathon 2026",
              subtitle: "Faculty Dean approved the proposal and Innovation Center venue.",
              time: "Today • 14:30",
              actionLabel: "View Event",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0);
              },
            ),
            _notificationTile(
              icon: Icons.hourglass_top,
              iconColor: Colors.orange,
              title: "Approval Pending: Windaneeya Handawa",
              subtitle:
                  "Submitted for amphitheatre audio and lighting clearance.",
              time: "Yesterday • 09:15",
              actionLabel: "Check Status",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(0);
              },
            ),
            _notificationTile(
              icon: Icons.person_add_alt_1,
              iconColor: kBlue,
              title: "New RSVPs on Nexora Hackathon",
              subtitle:
                  "Alex Chen and Chaduni De Silva registered for the event.",
              time: "2 days ago",
              actionLabel: "View Roster",
              onAction: () {
                Navigator.pop(ctx);
                _tabController.animateTo(1);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onAction,
    required String actionLabel,
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
                    color: kBgColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: kTextGrey, fontSize: 11.5),
                ),
                const SizedBox(height: 5),
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
                          color: kBlue,
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

  // Reusable Club President Profile Picture (PP) Widget (Gradient ring with initial letter or chosen avatar)
  Widget _buildProfilePhoto({double radius = 18}) {
    String initial = presidentName.isNotEmpty
        ? presidentName[0].toUpperCase()
        : 'R';

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kPurple, kBlue, kCyan]),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: kBgColor,
        backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
        child: profileImage == null
            ? Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor, // Navy Blue Background
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/nexora_icon.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: kNavyCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: kCyan, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NEXORA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  "Club President Portal",
                  style: TextStyle(color: kCyan, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: _showNotificationsModal,
          ),
          // Club President Name & Profile Photo Pill Displayed at Top Header
          GestureDetector(
            onTap: () {
              _tabController.animateTo(2); // Switches directly to Profile Tab
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kCyan.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfilePhoto(radius: 12),
                  const SizedBox(width: 7),
                  Text(
                    presidentName.split(' ').first,
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
        // 3 Separate Tabs Bar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kCyan,
          labelColor: kCyan,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: "Events"),
            Tab(icon: Icon(Icons.people), text: "Participants"),
            Tab(icon: Icon(Icons.person), text: "Profile"),
          ],
        ),
      ),

      // 3 Separate Tab Pages (Not everything on the same page)
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(), // Tab 1: Manage Club Events
          _buildParticipantsTab(), // Tab 2: Registered Participants
          _buildProfileTab(), // Tab 3: Club President Profile (Matches Student Dashboard)
        ],
      ),
    );
  }

  // ==================== TAB 1: EVENTS TAB ====================
  Widget _buildEventsTab() {
    int totalEvents = clubEvents.length;
    int pendingApprovals = clubEvents
        .where((e) => e["status"] == "PENDING")
        .length;
    int approvedEvents = clubEvents
        .where((e) => e["status"] == "APPROVED")
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header (Clean greeting without duplicate avatar)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $presidentName 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                "Manage your club's events and approvals.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Overview Counts Card (White Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem("Total Events", "$totalEvents", kBlue),
                _buildMetricItem("Pending", "$pendingApprovals", Colors.orange),
                _buildMetricItem("Approved", "$approvedEvents", Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Create New Club Event Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEventDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Create New Club Event",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            "Manage Club Events",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // White Event Cards List on Navy Blue Background
          clubEvents.isEmpty
              ? const Center(
                  child: Text(
                    "No events found for your club.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clubEvents.length,
                  itemBuilder: (context, index) {
                    final event = clubEvents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kWhiteCard, // White Event Card
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge + Status + Edit/Delete Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  event["category"],
                                  style: const TextStyle(
                                    color: kPurple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    event["status"],
                                    style: TextStyle(
                                      color: event["status"] == "APPROVED"
                                          ? Colors.green
                                          : Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: kBlue,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        _showEventDialog(existingEvent: event),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    onPressed: () => _deleteEvent(event["id"]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Event Title & Organizer
                          Text(
                            event["title"],
                            style: const TextStyle(
                              color: kBgColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event["organizer"],
                            style: const TextStyle(
                              color: kBlue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Description
                          Text(
                            event["description"],
                            style: const TextStyle(
                              color: kTextGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date, Venue & Button to View Participants in Tab 2
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 13,
                                color: kBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event["date"],
                                style: const TextStyle(
                                  color: kBgColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: kBlue,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event["venue"],
                                  style: const TextStyle(
                                    color: kBgColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedEventFilter = event["title"];
                                  });
                                  _tabController.animateTo(1);
                                },
                                icon: const Icon(Icons.people, size: 15),
                                label: const Text(
                                  "Participants",
                                  style: TextStyle(fontSize: 11),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: kBlue,
                                ),
                              ),
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

  // ==================== TAB 2: PARTICIPANTS TAB (CLEARLY VISIBLE FILTER & SEARCH) ====================
  Widget _buildParticipantsTab() {
    // Filter participants by event and search text
    final filteredList = participants.where((p) {
      final matchesEvent =
          _selectedEventFilter == "All Events" ||
          p["eventTitle"] == _selectedEventFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p["name"].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p["studentId"].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesEvent && matchesSearch;
    }).toList();

    final eventOptions = [
      "All Events",
      ...clubEvents.map((e) => e["title"].toString()),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Participant Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Registered Participants",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddParticipantDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text("Add RSVP"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter & Search Box (White Card with 100% VISIBLE dark text, borders, and blue icons)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Filter Dropdown (Dark navy text + visible border + blue icon)
                DropdownButtonFormField<String>(
                  initialValue: eventOptions.contains(_selectedEventFilter)
                      ? _selectedEventFilter
                      : "All Events",
                  isExpanded: true,
                  style: const TextStyle(
                    color: kBgColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: kWhiteCard,
                  icon: const Icon(Icons.arrow_drop_down, color: kBlue),
                  decoration: InputDecoration(
                    labelText: "Filter by Event",
                    labelStyle: const TextStyle(color: kTextGrey, fontSize: 12),
                    prefixIcon: const Icon(
                      Icons.filter_list,
                      color: kBlue,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                  items: eventOptions
                      .map(
                        (title) => DropdownMenuItem(
                          value: title,
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: kBgColor,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedEventFilter = val!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Search TextField (Dark navy text + visible border + blue search icon)
                TextField(
                  style: const TextStyle(
                    color: kBgColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search student name or ID...",
                    hintStyle: const TextStyle(color: kTextGrey, fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: kBlue,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Participants List (White Cards - Scan Button Removed)
          filteredList.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      "No participants found.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final p = filteredList[index];
                    final bool isCheckedIn = p["checkedIn"] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kWhiteCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p["name"],
                                  style: const TextStyle(
                                    color: kBgColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${p["studentId"]} • ${p["email"]}",
                                  style: const TextStyle(
                                    color: kTextGrey,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p["eventTitle"],
                                  style: const TextStyle(
                                    color: kBlue,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isCheckedIn
                                      ? "✓ Checked In"
                                      : "⏳ Pending Check-In",
                                  style: TextStyle(
                                    color: isCheckedIn
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Simple Check In / Undo Button (No Scan Button)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                p["checkedIn"] = !isCheckedIn;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCheckedIn
                                  ? Colors.grey.shade200
                                  : kBlue,
                              foregroundColor: isCheckedIn
                                  ? kBgColor
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(isCheckedIn ? "Undo" : "Check In"),
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

  // ==================== TAB 3: PROFILE TAB (EDIT PROFILE + PHOTO CHANGE ENABLED) ====================
  // ==================== PRIVACY & CAMPUS POLICIES MODAL ====================
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
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: ListView(
            controller: scrollController,
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
                  Icon(Icons.shield_outlined, color: kBlue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "Privacy & Campus Policies",
                    style: TextStyle(
                      color: kBgColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Nexora University Campus Management & Data Governance Rules",
                style: TextStyle(color: kTextGrey, fontSize: 12),
              ),
              const SizedBox(height: 18),
              _policySection(
                icon: Icons.lock_outline,
                iconColor: kBlue,
                title: "1. Attendee Data Privacy",
                description: "Student attendee details including Student IDs, emails, and ticket numbers are strictly confidential. Organizers are authorized to use attendee lists solely for verification and safety during campus events.",
              ),
              _policySection(
                icon: Icons.verified_user_outlined,
                iconColor: Colors.green,
                title: "2. Organizer Code of Conduct",
                description: "Club Presidents must ensure all proposed events adhere to University bylaws, campus safety regulations, and ethical guidelines before submitting for Dean approval.",
              ),
              _policySection(
                icon: Icons.event_seat_outlined,
                iconColor: kPurple,
                title: "3. Venue & Resource Usage",
                description: "Bookings for campus auditoriums, labs, and equipment must be confirmed 7 days prior. Organizers are responsible for maintaining venue integrity and vacating on schedule.",
              ),
              _policySection(
                icon: Icons.qr_code_scanner_outlined,
                iconColor: Colors.orange,
                title: "4. Attendance & Activity Credits",
                description: "Checked-in attendee rosters are directly synced with academic activity credits. Falsifying check-in records or proxy attendance is strictly prohibited under academic integrity policies.",
              ),
              _policySection(
                icon: Icons.contact_support_outlined,
                iconColor: kCyan,
                title: "5. Policy Contact & Support",
                description: "For inquiries regarding club bylaws, budget grants, or safety approvals, contact the Dean of Student Affairs at studentaffairs@nexora.edu.",
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
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
                    color: kBgColor,
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

  Widget _buildProfileTab() {
    int checkedInCount = participants
        .where((p) => p["checkedIn"] == true)
        .length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // 1. Digital President ID Card on Clean White Surface
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Circular Avatar with Gradient Ring + Camera Edit Badge (Click to Change Picture)
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _showImagePickerModal,
                    child: _buildProfilePhoto(radius: 36),
                  ),
                  GestureDetector(
                    onTap: _showImagePickerModal,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                presidentName,
                style: const TextStyle(
                  color: kBgColor,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                presidentEmail,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBlue.withOpacity(0.3)),
                ),
                child: Text(
                  'President ID: $presidentId',
                  style: const TextStyle(
                    color: kBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Edit Profile Button (Requested by User)
              OutlinedButton.icon(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit, size: 15, color: kBlue),
                label: const Text(
                  "Edit Profile Details",
                  style: TextStyle(
                    color: kBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Quick Stats Strip (3 Separate Clean White Cards)
        Row(
          children: [
            _statBox('Events', '${clubEvents.length}', kBlue),
            const SizedBox(width: 8),
            _statBox('Participants', '${participants.length}', kPurple),
            const SizedBox(width: 8),
            _statBox('Checked In', '$checkedInCount', const Color(0xFF059669)),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Profile Quick Action Tiles (Individual Clean White Cards with Arrows)
        _profileActionTile(
          Icons.camera_alt_outlined,
          'Change Profile Picture / Avatar',
          _showImagePickerModal,
        ),
        _profileActionTile(
          Icons.event_available_rounded,
          'Manage Club Events',
          () => _tabController.animateTo(0),
        ),
        _profileActionTile(
          Icons.groups_rounded,
          'View Participants Roster',
          () => _tabController.animateTo(1),
        ),
        _profileActionTile(
          Icons.notifications_active_outlined,
          'Event Notifications',
          _showNotificationsModal,
        ),
        _profileActionTile(
          Icons.shield_outlined,
          'Privacy & Policies',
          _showPrivacyPolicyModal,
        ),
        _profileActionTile(Icons.logout_rounded, 'Log Out', () {
          Navigator.pop(context);
        }, isDestructive: true),
      ],
    );
  }

  // Helper: Quick Stat Box Widget
  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: kBgColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Profile Action Tile Widget
  Widget _profileActionTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : kBlue,
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : kBgColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 13,
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: kBgColor,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
