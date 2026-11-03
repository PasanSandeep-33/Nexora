import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'screens/student_dashboard_screen.dart';
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
    bool isLoggedIn = false;
    Map<String, dynamic>? savedUser;

    try {
      // Step 1: Restore JWT session
      isLoggedIn = await ApiService.refreshSession();

      // Step 2: Get actual user profile
      if (isLoggedIn) {
        savedUser = await ApiService.getProfile();

        debugPrint('Auto login profile loaded: ${savedUser['full_name']}');
      }
    } catch (error) {
      debugPrint('Auto login failed: $error');
      isLoggedIn = false;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn && savedUser != null
            ? StudentDashboardScreen(user: savedUser)
            : const LoginPage(),
      ),
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
      body: SizedBox.expand(
        child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
      ),
    );
  }
}
