
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

    _timer = Timer(
      const Duration(seconds: 5),
      _checkLogin,
    );
  }

  Future<void> _checkLogin() async {
    bool isLoggedIn = false;

    try {
      // Restore login using saved refresh token
      isLoggedIn = await ApiService.refreshSession();
    } catch (error) {
      // Do not delete tokens on network failure
      debugPrint('Auto login failed: $error');
      isLoggedIn = false;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn
            ? const StudentDashboardScreen()
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
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
