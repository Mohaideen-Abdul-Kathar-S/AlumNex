import 'package:alumnex/alumnex_alumni_reg_page.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_login_page.dart';
import 'package:flutter/material.dart';
import 'alumnex_idcard_reg_page.dart';

class AlumnexRegPage extends StatefulWidget {
  final Map<String, dynamic>? prefilledData; // ✅ add this

  const AlumnexRegPage({super.key, this.prefilledData});

  @override
  State<AlumnexRegPage> createState() => _AlumnexRegPageState();
}

class _AlumnexRegPageState extends State<AlumnexRegPage> {
  String? selectedRole = "Select Role";
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
  final TextEditingController rollnoCont = TextEditingController();
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();
  final TextEditingController conPasswordCont = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rollnoCont.text = widget.prefilledData?['Student Roll No'] ?? "";
    
    determineRole();
  }
// default

void determineRole() {
  selectedRole = isAlumniRole() ? "Alumni" : "Student";
}

bool isAlumniRole() {
  String batch = widget.prefilledData?['Student Batch'] ?? "";
  List<String> years = batch.split(" - ");
  int? endYear = years.length > 1 ? int.tryParse(years[1]) : null;

  int currentYear = DateTime.now().year;

  // Alumni if batch already passed out
  return endYear != null && endYear < currentYear;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AlumNex'),
        shadowColor: accentColor,
        toolbarHeight: 100,
        backgroundColor: primaryColor,
        elevation: 3,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: accentColor,
          fontSize: 24,
        ),
        foregroundColor: accentColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D52), Color(0xFF224146)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Register Page',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelStyle: TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    value: selectedRole,
                    dropdownColor: Colors.white,
                    items:
                        ['Select Role', 'Student', 'Alumni'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  buildTextField("Enter Roll No", rollnoCont),
                  const SizedBox(height: 15),
                  buildTextField("Enter Email Id", emailCont),
                  const SizedBox(height: 15),
                  buildTextField("Enter Password", passwordCont, obscure: true),
                  const SizedBox(height: 15),
                  buildTextField(
                    "Confirm Password",
                    conPasswordCont,
                    obscure: true,
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Color.fromARGB(255, 255, 255, 255),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlumnexLoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE27C43),
                          foregroundColor: Colors.white,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          print(
                            "ID card data" + widget.prefilledData.toString(),
                          );
                          if (passwordCont.text == conPasswordCont.text) {
                            if (rollnoCont.text ==
                                    widget.prefilledData?['Student Roll No'] &&
                                ("KONGU ENGINEERING COLLEGE" ==
                                        widget.prefilledData?['College Name'] ||
                                    "Kongu Engineering College" ==
                                        widget
                                            .prefilledData?['College Name'])) {
                              // Parse "2023 - 2027"
                              String batch =
                                  widget.prefilledData?['Student Batch'] ?? "";
                              List<String> years = batch.split(" - ");
                              int? endYear =
                                  years.length > 1
                                      ? int.tryParse(years[1])
                                      : null;

                              // Current year
                              int currentYear = DateTime.now().year;

                              // Validation: Alumni means batch already passed out
                              bool isAlumni =
                                  endYear != null && endYear < currentYear;
                                  
                              dynamic data = {
                                "roll": isAlumni ? "Alumni" : "Student",
                                "_id": rollnoCont.text,
                                "password": passwordCont.text,
                                "profile": "Path",
                                "name":
                                    widget.prefilledData?['Student Name'] ??
                                    "Nill",
                                "Gender": "Nill",
                                "email": emailCont.text,
                                "phoneno": "Nill",
                                "location": "Nill",
                                "programbranch": "Nill",
                                "Batch":
                                    widget.prefilledData?['Student Batch'] ??
                                    "Nill",
                                "preferredroll": "Nill",
                                "Higherstudies": "Nill",
                                "Dreamcompany": "Nill",
                                "TechSkills": "Nill",
                                "certificaion": "Nill",
                                "projects": "Nill",
                                "clubs": "Nill",
                                "mentoredby": "Nill",
                                "domain": "Nill",
                                "currentjob": "Nill",
                                "company": "Nill",
                                "yoe": "Nill",
                                "workedin": "Nill",
                                "mentoring": [],
                              };

                              String res = await DataBaseConnection()
                                  .RegistrationPage(data);
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(res)));

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlumnexLoginPage(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Roll number or College Name is Invalid",
                                  ),
                                ),
                              );
                              if (widget.prefilledData?['Student Roll No'] ==
                                      null ||
                                  widget.prefilledData?['College Name']==null ||
                                  widget.prefilledData?['Student Batch'] ==
                                      null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlumnexIdCardPage(),
                                  ),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password isn\'t match'),
                              ),
                            );
                          }
                        },
                        child: Text(
                          (widget.prefilledData?['Student Roll No'] == null ||
                                  widget.prefilledData?['College Name']==null ||
                                  widget.prefilledData?['Student Batch'] ==
                                      null)
                              ? "Upload ID Card"
                              : "Register",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),GestureDetector(
  child: const Text(
    "If you are alumni and don't have ID Card, Then click me!",
    style: TextStyle(
      color: Color.fromARGB(255, 219, 197, 197),
    ),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlumnexAlumniRegPage()),
    );
  },
),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController cont, {
    bool obscure = false,
  }) {
    return TextField(
      controller: cont,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
