import 'package:flutter/material.dart';

class PresidentDashboard extends StatefulWidget {
  const PresidentDashboard({super.key});

  @override
  State<PresidentDashboard> createState() => _PresidentDashboardState();
}

class _PresidentDashboardState extends State<PresidentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Student Dashboard Matching Colors (Navy Blue Background + White Cards)
  static const Color kBgColor = Color(0xFF050B25); // Navy Blue Background
  static const Color kNavyCard = Color(0xFF0F1A4E); // Secondary Navy
  static const Color kWhiteCard = Colors.white; // White Card Color
  static const Color kBlue = Color(0xFF3478FF); // Primary Blue
  static const Color kPurple = Color(0xFF8052F5); // Accent Purple
  static const Color kCyan = Color(0xFF19D9ED); // Accent Cyan
  static const Color kTextGrey = Color(0xFF64748B);

  // Club President Profile Details
  String presidentName = "Raveen Perera";
  String presidentEmail = "raveen.p@campus.nexora.edu";
  String presidentClub = "IEEE Computer Society";
  String presidentId = "NXR-PRES-2026-01";

  // 1. Club Events List (Friend's CRUD Data)
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

  // Local demonstration participants; replace with backend data later.
  final List<Map<String, dynamic>> participants = [
    {
      "name": "Ashen Gamage",
      "studentId": "NXR-2026-CS88",
      "email": "ashen.gmge@campus.nexora.edu",
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

  // Form Controllers
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
                  decoration: const InputDecoration(labelText: "Event Title"),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                TextField(
                  controller: _venueController,
                  decoration: const InputDecoration(labelText: "Venue"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: kWhiteCard,
                  items: ["TECHNOLOGY", "CULTURAL", "SPORTS", "WORKSHOP"]
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Category"),
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
    if (clubEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Create an event before adding participants."),
        ),
      );
      return;
    }
    String selectedEvent = clubEvents.first["title"];

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
                  decoration: const InputDecoration(labelText: "Student Name"),
                ),
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: "Student ID"),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedEvent,
                  isExpanded: true,
                  items: clubEvents
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e["title"],
                          child: Text(
                            e["title"],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedEvent = val;
                  },
                  decoration: const InputDecoration(labelText: "Event"),
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
                          "NEXORA-TKT-${DateTime.now().millisecondsSinceEpoch.toString()}",
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kWhiteCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Edit President Profile",
            style: TextStyle(color: kBgColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: clubCtrl,
                decoration: const InputDecoration(labelText: "Club Name"),
              ),
            ],
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
                setState(() {
                  presidentName = nameCtrl.text;
                  presidentEmail = emailCtrl.text;
                  presidentClub = clubCtrl.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Reusable Club President Profile Picture (PP) Widget
  Widget _buildProfilePhoto({double radius = 18}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kPurple, kBlue, kCyan]),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: kBgColor,
        child: Icon(Icons.person, color: Colors.white, size: radius * 1.2),
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
                errorBuilder: (_, __, ___) => Container(
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
            onPressed: () {},
          ),
          // Clicking Profile Photo (PP) opens the separate Profile Tab (Tab index 2)
          GestureDetector(
            onTap: () {
              _tabController.animateTo(2);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: _buildProfilePhoto(radius: 16),
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
          _buildProfileTab(), // Tab 3: Club President Profile
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
          // Greeting Row with clickable Profile Photo (PP)
          Row(
            children: [
              GestureDetector(
                onTap: () => _tabController.animateTo(2),
                child: _buildProfilePhoto(radius: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $presidentName 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Manage your club's events and approvals.",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
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
                                  color: kPurple.withOpacity(0.12),
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

  // ==================== TAB 2: PARTICIPANTS TAB (NO SCAN BUTTON) ====================
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

          // Filter & Search Box (White Card)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: eventOptions.contains(_selectedEventFilter)
                      ? _selectedEventFilter
                      : "All Events",
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Filter by Event",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: eventOptions
                      .map(
                        (title) => DropdownMenuItem(
                          value: title,
                          child: Text(title, overflow: TextOverflow.ellipsis),
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
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Search student name or ID...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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

  // ==================== TAB 3: CLUB PRESIDENT PROFILE TAB ====================
  Widget _buildProfileTab() {
    int checkedInCount = participants
        .where((p) => p["checkedIn"] == true)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Main President Profile Card (White Card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildProfilePhoto(radius: 36),
                const SizedBox(height: 12),
                Text(
                  presidentName,
                  style: const TextStyle(
                    color: kBgColor,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  presidentEmail,
                  style: const TextStyle(color: kTextGrey, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Club: $presidentClub • ID: $presidentId",
                    style: const TextStyle(
                      color: kBlue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit, size: 16, color: kBlue),
                  label: const Text(
                    "Edit Profile",
                    style: TextStyle(color: kBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats Row (White Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem("Club Events", "${clubEvents.length}", kBlue),
                _buildMetricItem(
                  "Participants",
                  "${participants.length}",
                  kPurple,
                ),
                _buildMetricItem("Checked In", "$checkedInCount", Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions List (White Card)
          Container(
            decoration: BoxDecoration(
              color: kWhiteCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available, color: kBlue),
                  title: const Text(
                    "Go to Manage Events",
                    style: TextStyle(
                      color: kBgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _tabController.animateTo(0),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people, color: kPurple),
                  title: const Text(
                    "Go to Participants Roster",
                    style: TextStyle(
                      color: kBgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _tabController.animateTo(1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
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
