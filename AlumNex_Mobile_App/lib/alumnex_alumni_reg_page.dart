import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
 // Make sure login.dart exists and has LoginPage

class AlumnexAlumniRegPage extends StatefulWidget {
  const AlumnexAlumniRegPage({super.key});

  @override
  State<AlumnexAlumniRegPage> createState() => _AlumnexAlumniRegPageState();
}

class _AlumnexAlumniRegPageState extends State<AlumnexAlumniRegPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  final _formKey = GlobalKey<FormState>();
  String baseUrl = "$urI/api"; // (for Android emulator)
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _contactOption = "email"; // default selected
  bool _otpSent = false;

Future<bool> sendOtp(String rollNo, String method) async {
  final response = await http.post(
    Uri.parse("$urI/api/send_otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"rollno": rollNo, "method": method}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["success"] == true;
  }
  return false;
}

Future<bool> verifyOtp(String rollNo,String password, String otp) async {
  final response = await http.post(
    Uri.parse("$urI/api/verify_otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"rollno": rollNo,"password":password, "otp": otp}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["success"] == true;
  }
  return false;
}
 



Future<Map<String, dynamic>?> fetchContact(String rollNo) async {
  final response = await http.post(
    Uri.parse("$baseUrl/get_contact"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"rollno": rollNo}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return null;
}

void _onSendOtp() async {
  String rollNo = _rollNoController.text.trim();

  if (rollNo.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter Roll Number")),
    );
    return;
  }

  final data = await fetchContact(rollNo);

  if (data == null || data["success"] == false) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Roll number not found")),
    );
    return;
  }

  // Pick phone/email based on option
  String target = _contactOption == "email"
      ? data["email"]
      : data["phoneno"];

  // Call your OTP service here
  await sendOtp(rollNo, _contactOption); // pass rollNo + "email"/"phone"


  setState(() {
    _otpSent = true;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("OTP sent to $target")),
  );
}

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
bool validOtp = await verifyOtp(_rollNoController.text,_passwordController.text, _otpController.text);

      if (!validOtp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP")),
        );
        return;
      }
 

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AlumnexLoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text("Alumni Registration"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _rollNoController,
                    decoration: const InputDecoration(labelText: "Roll No"),
                    validator: (val) =>
                        val!.isEmpty ? "Enter Roll Number" : null,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password"),
                    validator: (val) =>
                        val!.length < 6 ? "Min 6 characters" : null,
                  ),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: "Confirm Password"),
                    validator: (val) =>
                        val != _passwordController.text ? "Password mismatch" : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          activeColor: accentColor,
                          title: const Text("Email"),
                          value: "email",
                          groupValue: _contactOption,
                          onChanged: (val) {
                            setState(() => _contactOption = val!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          activeColor: accentColor,
                          title: const Text("Phone"),
                          value: "phone",
                          groupValue: _contactOption,
                          onChanged: (val) {
                            setState(() => _contactOption = val!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_otpSent)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _onSendOtp,
                      child: const Text("Send OTP"),
                    ),
                  if (_otpSent) ...[
                    TextFormField(
                      controller: _otpController,
                      decoration: const InputDecoration(labelText: "Enter OTP"),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _onRegister,
                      child: const Text("Register"),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
