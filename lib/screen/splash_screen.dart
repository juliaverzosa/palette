import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_pallete/screen/welcome_screen.dart'; // Import your Welcome page

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // After 2 seconds, navigate to the welcome page
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()), // Replace with your welcome page
      );
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 114, 134),
      body: Center(
        child: Image.asset(
          'assets/palette_logo1.png', // Path to your logo image
          width: 200, // Adjust the width as necessary
          height: 200, // Adjust the height as necessary
        ),
      ),
    );
  }
}
