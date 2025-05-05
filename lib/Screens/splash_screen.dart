import 'package:blorbmart2/Screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String appName = "Blorbmart";
  final String version = "v1.0.0";
  String displayedText = "";
  int currentIndex = 0;
  bool showCursor = true;
  late Timer _typingTimer;
  late Timer _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
    _startCursorAnimation();
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (currentIndex < appName.length) {
        setState(() {
          displayedText = appName.substring(0, currentIndex + 1);
          currentIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          // To navigate to SignupScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        });
      }
    });
  }

  void _startCursorAnimation() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        showCursor = !showCursor;
      });
    });
  }

  @override
  void dispose() {
    _typingTimer.cancel();
    _cursorTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463), // Deep blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  fontFamily:
                      'Poppins', // Use a nice font (make sure to include it in pubspec.yaml)
                  color: Colors.white,
                ),
                children: [
                  TextSpan(text: displayedText),
                  TextSpan(
                    text: showCursor ? "|" : " ",
                    style: const TextStyle(
                      color: Color(0xFF3E92CC), // Light blue cursor
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              version,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
