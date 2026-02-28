import 'dart:async';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/splash_sceen.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Needed for async in main

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String studentId = prefs.getString("user") ?? "1";

  // Start the daily progress update scheduler
  scheduleDailyProgressUpdate(studentId);

  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: SplashScreen(),
    );
  }
}

/// ✅ Keep this function outside the widget
void scheduleDailyProgressUpdate(String studentId) {
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final now = DateTime.now();
    if (now.hour == 23 && now.minute == 55) {
      final url = Uri.parse(
        "$urI/api/student/$studentId/progress/today",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("✅ Progress updated successfully at 11:55 PM");
      } else {
        print("❌ Failed to update progress: ${response.body}");
      }
    }
  });
}
