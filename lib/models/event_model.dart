class Event {
  final int eventId;
  final String title;
  final String description;
  final String category;
  final DateTime eventDate;
  final String location;
  final int capacity;

  Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.location,
    required this.capacity,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      eventDate: DateTime.parse(json['event_date']),
      location: json['location'] ?? '',
      capacity: json['capacity'] as int,
    );
  }
}
