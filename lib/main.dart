import 'package:flutter/material.dart';

import 'splash_screen.dart';

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
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home:  SplashScreen(),
    );
  }
}
