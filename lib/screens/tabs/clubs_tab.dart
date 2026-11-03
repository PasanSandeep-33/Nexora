import 'package:flutter/material.dart';
import '../../models/club_model.dart';

class ClubsTab extends StatelessWidget {
  final List<Club> clubs;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<Club> onToggleJoinClub;

  const ClubsTab({
    super.key,
    required this.clubs,
    required this.isLoading,
    required this.onRefresh,
    required this.onToggleJoinClub,
  });

  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  static const Color cyan = Color(0xFF19D9ED);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cyan,
      backgroundColor: navyCard,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          const Text(
            'Campus Clubs & Societies',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join official societies to receive private meetups and notifications.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ...clubs.map((club) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(club.name, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${club.memberCount} members', style: const TextStyle(color:Color(0xFF059669), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(club.description, style: const TextStyle(color: Colors.black, fontSize: 12)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: club.isJoined ? navyCard : blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onToggleJoinClub(club),
                      child: Text(
                        club.isJoined ? 'Joined ✓' : 'Join Club +',
                        style: TextStyle(
                          color: club.isJoined ? Colors.white70 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}