import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const OceanEmbedApp());
}

class OceanEmbedApp extends StatelessWidget {
  const OceanEmbedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OceanEmbed - AI Ocean Intelligence',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF147BEF),
          brightness: Brightness.light,
        ),
      ),
      home: const OceanEmbedSplashScreen(),
    );
  }
}