class Club {
  final int clubId;
  final String clubName;
  final String description;
  final String category;
  final String presidentName;
  int memberCount;
  bool isJoined;

  Club({
    required this.clubId,
    required this.clubName,
    required this.description,
    this.category = 'General',
    this.presidentName = 'Club President',
    this.memberCount = 0,
    this.isJoined = false,
  });

  // Compatibility getter - club.name හෝ club.clubName දෙකටම වැඩ කරයි
  String get name => clubName;

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      clubId: json['club_id'] as int? ?? 0,
      clubName: json['club_name']?.toString() ?? 'Campus Club',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      presidentName: json['president_name']?.toString() ?? 'Club President',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'club_id': clubId,
      'club_name': clubName,
      'description': description,
      'category': category,
      'president_name': presidentName,
      'member_count': memberCount,
    };
  }
}