class Event {
  final int eventId;
  final String title;
  final String description;
  final String category;
  final DateTime eventDate;
  final String location;
  final int capacity;
  int rsvpCount;
  final String clubName;

  Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.location,
    required this.capacity,
    this.rsvpCount = 0,
    this.clubName = 'Campus Club',
  });

  // Compatibility getter
  int get id => eventId;

  bool get isFull => capacity > 0 && rsvpCount >= capacity;
  int get availableSpots => capacity > rsvpCount ? capacity - rsvpCount : 0;
  double get capacityPercentage =>
      capacity > 0 ? (rsvpCount / capacity).clamp(0.0, 1.0) : 0.0;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      location: json['location']?.toString() ?? 'Main Campus',
      capacity: (json['capacity'] as num?)?.toInt() ?? 50,
      rsvpCount: (json['rsvp_count'] as num?)?.toInt() ?? 0,
      clubName: json['club_name']?.toString() ?? 'Campus Club',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'title': title,
      'description': description,
      'category': category,
      'event_date': eventDate.toIso8601String(),
      'location': location,
      'capacity': capacity,
      'rsvp_count': rsvpCount,
      'club_name': clubName,
    };
  }
}
