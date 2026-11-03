import 'dart:io';

import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  final String userName;
  final String userEmail;
  final int rsvpCount;
  final Map<String, dynamic> stats;
  final ValueChanged<int> onNavigateToTab;
  final VoidCallback onLogout;
  final void Function({required String message}) onShowSnackBar;
  final File? profileImage;
  final VoidCallback? onUpdateProfilePhoto;
  final VoidCallback? onOpenPrivacyPolicy;
  final VoidCallback?
  onOpenNotifications; // 👉 මෙන්න මේ parameter එක එක්විය යුතුය

  const ProfileTab({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.rsvpCount,
    required this.stats,
    required this.onNavigateToTab,
    required this.onLogout,
    required this.onShowSnackBar,
    this.profileImage,
    this.onUpdateProfilePhoto,
    this.onOpenPrivacyPolicy,
    this.onOpenNotifications,
  });

  static const Color navy = Color(0xFF050B25);
  static const Color navyCard = Color(0xFF0F1A4E);
  static const Color blue = Color(0xFF3478FF);
  static const Color purple = Color(0xFF8052F5);
  static const Color cyan = Color(0xFF19D9ED);

  @override
  Widget build(BuildContext context) {
    String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // Digital Student Card with Clickable Profile Picture
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
              // Avatar with Gradient Ring + Camera Edit Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: onUpdateProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [purple, blue, cyan]),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: navy,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : null,
                        child: profileImage == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onUpdateProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: blue,
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
                userName,
                style: const TextStyle(
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userEmail,
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
                  border: Border.all(color: blue.withOpacity(0.3)),
                ),
                child: const Text(
                  'Student ID: NXR-2026-CS88',
                  style: TextStyle(
                    color: blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Stats Strip
        Row(
          children: [
            _statBox('Passes', '$rsvpCount', blue),
            const SizedBox(width: 8),
            _statBox('Clubs', '${stats['clubs_joined'] ?? 0}', purple),
            const SizedBox(width: 8),
            _statBox(
              'Attended',
              '${stats['attended_events'] ?? 0}',
              const Color(0xFF059669),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Action Tiles
        _profileActionTile(
          Icons.camera_alt_outlined,
          'Update Profile Picture',
          onUpdateProfilePhoto ?? () {},
        ),
        _profileActionTile(
          Icons.qr_code_2_rounded,
          'View My Event Passes',
          () => onNavigateToTab(1),
        ),
        _profileActionTile(
          Icons.groups_rounded,
          'Browse Campus Clubs',
          () => onNavigateToTab(2),
        ),
        _profileActionTile(
          Icons.notifications_active_outlined,
          'Event Notifications',
          onOpenNotifications ??
              () {
                onShowSnackBar(message: 'All event reminders are active.');
              },
        ),
        _profileActionTile(
          Icons.shield_outlined,
          'Privacy & Policies',
          onOpenPrivacyPolicy ??
              () {
                onShowSnackBar(
                  message: 'Student data protected by university directory.',
                );
              },
        ),
        _profileActionTile(
          Icons.logout_rounded,
          'Log Out',
          onLogout,
          isDestructive: true,
        ),
      ],
    );
  }

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
                color: navy,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          color: isDestructive ? Colors.redAccent : blue,
          size: 21,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : navy,
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
}
