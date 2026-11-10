import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 5), _checkLogin);
  }

  Future<void> _checkLogin() async {
    Widget destination = const LoginPage();

    try {
      // Restore the saved session. This succeeds only when a refresh token
      // is available and the backend accepts it.
      final isLoggedIn = await ApiService.refreshSession().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );

      if (isLoggedIn) {
        // Always ask the backend for the authenticated user's current role.
        final savedUser = await ApiService.getProfile().timeout(
          const Duration(seconds: 15),
        );
        final role = savedUser['role']?.toString().trim().toLowerCase();

        debugPrint(
          'Auto-login profile loaded: '
          '${savedUser['full_name']} (role: $role)',
        );

        if (role == 'admin') {
          destination = const AdminDashboardScreen();
        } else if (role == 'student') {
          destination = StudentDashboardScreen(user: savedUser);
        } else {
          // Do not guess a dashboard when the backend returns an unknown role.
          debugPrint('Auto-login rejected: unsupported user role "$role".');
          await ApiService.logout();
        }
      }
    } catch (error) {
      debugPrint('Auto login failed: $error');

      // Remove an invalid or expired local session so the app does not keep
      // trying to restore it on every launch.
      try {
        await ApiService.logout();
      } catch (logoutError) {
        debugPrint('Unable to clear invalid local session: $logoutError');
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B25),
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
          // If the splash asset is missing or cannot be decoded, show a
          // visible Nexora fallback instead of a black screen.
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Splash image failed to load: $error');
            return const ColoredBox(
              color: Color(0xFF050B25),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFF19D9ED),
                      size: 76,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'NEXORA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Event Management, Simplified',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 28),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Color(0xFF19D9ED),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
