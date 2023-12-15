import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Customize the app bar of the loading screen if needed
        backgroundColor: Color.fromARGB(255, 252, 226, 120),
      ),
      body: Center(
        child: CircularProgressIndicator(), // Loading indicator
      ),
    );
    
  }
}
