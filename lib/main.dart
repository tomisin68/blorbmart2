import 'package:flutter/material.dart';
import 'package:blorbmart2/Screens/splash_screen.dart';
// Import your home page file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name', // Change this to your app name
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(), // This now points directly to your HomePage
      debugShowCheckedModeBanner: false,
    );
  }
}
