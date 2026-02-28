import 'dart:async';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_index_page.dart';

import 'package:flutter/material.dart';
import 'package:alumnex/alumnex_login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // After 1 second, navigate to Login Page
    Timer(const Duration(seconds: 3), () async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  userID = prefs.getString("userID") ?? "";
  userRoll = prefs.getString("userRoll") ?? "";

  if (userID.isEmpty && userRoll.isEmpty) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AlumnexLoginPage()),
    );
  } else {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AlumnexIndexPage(
          roll: userRoll,
          rollno: userID,
        ),
      ),
    );
  }
});

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004d52), // your primaryColor
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your App Logo here
              Image.asset(
                'assets/logo.jpg', // Make sure your logo is placed inside assets folder
                height: 320,
              ),
              const SizedBox(height: 20),
              const Text(
                'AlumNex',
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
