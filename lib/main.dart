import 'package:flutter/material.dart';
import 'package:nexora/screens/student_dashboard_screen.dart';

import 'splash_screen.dart';

import 'package:nexora/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030620),
        primaryColor: const Color(0xFF3478FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3478FF),
          secondary: Color(0xFF19D9ED),
          surface: Color(0xFF0A1138),
        ),

        useMaterial3: true,
      ),
      home: SplashScreen(),
    
    );
  }
}
