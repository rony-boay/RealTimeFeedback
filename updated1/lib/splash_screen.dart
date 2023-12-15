import 'package:flutter/material.dart';
import 'package:updated1/button_page.dart'; // Import your ButtonPage

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      // After 3 seconds, navigate to the ButtonPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ButtonPage()),
      );
    });

    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/smiley1.png", fit: BoxFit.cover, width: double.infinity,
          height: double.infinity,
          // Customize your splash screen content here
        ),
      ),
    );
  }
}
