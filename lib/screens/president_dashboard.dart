import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      home: PresidentDashboard(),
      debugShowCheckedModeBanner: false,
    ));

class PresidentDashboard extends StatefulWidget {
  const PresidentDashboard({super.key});

  @override
  State<PresidentDashboard> createState() => _PresidentDashboardState();
}

class _PresidentDashboardState extends State<PresidentDashboard> {
  // Nexora Theme Colors
  static const Color kBgColor = Color(0xFF0D1117);
  static const Color kCardColor = Color(0xFF161B22);
  static const Color kTealAccent = Color(0xFF00E5FF);
  static const Color kTextWhite = Colors.white;
  static const Color kTextGrey = Colors.grey;

  // List of events organized by this president's assigned club
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
      "date": "26/10/2026 • 3:54",
      "venue": "Prof. J.W. Dayananda...",
      "status": "PENDING",
    },
  ];

  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  String _selectedCategory = "TECHNOLOGY";

  // Popup Dialog to Add or Edit Event
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
          backgroundColor: kCardColor,
          title: Text(
            existingEvent == null ? "Create Club Event" : "Update Club Event",
            style: const TextStyle(color: kTextWhite),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: kTextWhite),
                  decoration: const InputDecoration(labelText: "Event Title", labelStyle: TextStyle(color: kTextGrey)),
                ),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: kTextWhite),
                  decoration: const InputDecoration(labelText: "Description", labelStyle: TextStyle(color: kTextGrey)),
                ),
                TextField(
                  controller: _venueController,
                  style: const TextStyle(color: kTextWhite),
                  decoration: const InputDecoration(labelText: "Venue", labelStyle: TextStyle(color: kTextGrey)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: kCardColor,
                  style: const TextStyle(color: kTextWhite),
                  items: ["TECHNOLOGY", "CULTURAL", "SPORTS", "WORKSHOP"]
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                    });
                  },
                  decoration: const InputDecoration(labelText: "Category", labelStyle: TextStyle(color: kTextGrey)),
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
              style: ElevatedButton.styleFrom(backgroundColor: kTealAccent, foregroundColor: Colors.black),
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    if (existingEvent == null) {
                      // Add New Event
                      clubEvents.add({
                        "id": DateTime.now().toString(),
                        "category": _selectedCategory,
                        "title": _titleController.text,
                        "organizer": "Organized by: Assigned Club",
                        "description": _descController.text,
                        "date": "30/10/2026 • 10:00",
                        "venue": _venueController.text,
                        "status": "PENDING",
                      });
                    } else {
                      // Update Existing Event
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

  @override
  Widget build(BuildContext context) {
    int totalEvents = clubEvents.length;
    int pendingApprovals = clubEvents.where((e) => e["status"] == "PENDING").length;
    int approvedEvents = clubEvents.where((e) => e["status"] == "APPROVED").length;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/nexora_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("NEXORA", style: TextStyle(color: kTextWhite, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                Text("Club President Portal", style: TextStyle(color: kTealAccent, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: kTextWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Subtitle
            const Text(
              "Welcome, President 👋",
              style: TextStyle(color: kTextWhite, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here is the overview and management panel for your club's events.",
              style: TextStyle(color: kTextGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Key Metric Counts Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kTealAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem("Total Events", "$totalEvents", kTealAccent),
                  _buildMetricItem("Pending", "$pendingApprovals", Colors.orangeAccent),
                  _buildMetricItem("Approved", "$approvedEvents", Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Button to Add Event
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEventDialog(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text("Create New Club Event", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Manage Club Events",
              style: TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Event List tailored for Club President
            clubEvents.isEmpty
                ? const Center(child: Text("No events found for your club.", style: TextStyle(color: kTextGrey)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: clubEvents.length,
                    itemBuilder: (context, index) {
                      final event = clubEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kTealAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event["category"],
                                    style: const TextStyle(color: kTealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      event["status"],
                                      style: TextStyle(
                                        color: event["status"] == "APPROVED" ? Colors.greenAccent : Colors.orangeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Update / Edit Button
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: kTealAccent, size: 18),
                                      onPressed: () => _showEventDialog(existingEvent: event),
                                    ),
                                    // Delete Button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () => _deleteEvent(event["id"]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event["title"],
                              style: const TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event["organizer"],
                              style: const TextStyle(color: kTealAccent, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event["description"],
                              style: const TextStyle(color: kTextGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: kTextGrey),
                                const SizedBox(width: 4),
                                Text(event["date"], style: const TextStyle(color: kTextGrey, fontSize: 11)),
                                const SizedBox(width: 16),
                                const Icon(Icons.location_on, size: 12, color: kTextGrey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(event["venue"], style: const TextStyle(color: kTextGrey, fontSize: 11), overflow: TextOverflow.ellipsis),
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
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: kTextGrey, fontSize: 11)),
      ],
    );
  }
}