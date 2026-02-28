import 'dart:convert';


import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:flutter/material.dart';

class AlumnexViewSidesheetsPage extends StatefulWidget {
  final dynamic roll;
  
  final dynamic trollno;

  const AlumnexViewSidesheetsPage({super.key,required this.roll,required this.trollno});

  @override
  State<AlumnexViewSidesheetsPage> createState() =>
      _AlumnexViewSidesheetsPageState();
}

class _AlumnexViewSidesheetsPageState extends State<AlumnexViewSidesheetsPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  bool isEdit = false;
  final Map<String, TextEditingController> controllers = {};
  late final roll;
  Map<String, dynamic>? personFields; // 👈 make nullable

  @override
  void initState() {
    super.initState();
    roll = widget.roll;
    _loadPersonFields();
  }

  Future<void> _loadPersonFields() async {
    final response = await DataBaseConnection().GetPersonInfo({"rollno": widget.trollno});
    
    // Decode depending on what your API returns
    final result = response is Map ? response : jsonDecode(response.body);

    if (mounted) {
      setState(() {
        personFields = result;

        if (personFields?["fields"] != null) {
          personFields!["fields"].forEach((key, value) {
            if (value is String) {
              controllers[key] = TextEditingController(text: value);
            } else if (value is List) {
              for (int i = 0; i < value.length; i++) {
                controllers["$key$i"] = TextEditingController(text: value[i]);
              }
            }
          });
        }
      });
    }
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          color: accentColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String key, {bool editable = true}) {
    final value = personFields?["fields"][key];

    if (value is List) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            if (isEdit && editable)
              Column(
                children: [
                  for (int i = 0; i < value.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller:
                                controllers["$key$i"] ??= TextEditingController(
                                  text: value[i],
                                ),
                            onChanged: (val) => personFields?["fields"][key][i] = val,
                            decoration: const InputDecoration(isDense: true),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () {
                            setState(() {
                              personFields?["fields"][key].removeAt(i);
                              controllers.remove("$key$i");
                            });
                          },
                        ),
                      ],
                    ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        personFields?["fields"][key].add("");
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add"),
                  ),
                ],
              )
            else
              Text(value.join(", "), style: TextStyle(color: Colors.grey[800])),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "$label:",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child:
                  isEdit && editable && controllers.containsKey(key)
                      ? TextField(
                        controller: controllers[key],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                        ),
                      )
                      : Text(
                        value.toString(),
                        style: TextStyle(color: Colors.grey[800]),
                      ),
            ),
          ],
        ),
      );
    }
  }

 

   @override
  Widget build(BuildContext context) {
    if (personFields == null) {
      return const Center(child: CircularProgressIndicator()); // 👈 wait for data
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: secondaryColor,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hi!!!, it's ${personFields?['fields']['Full Name']}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildSectionTitle("BASIC INFORMATION"),
                _buildInfoRow("Gender", "Gender"),
                _buildInfoRow("Email ID", "Email"),
                _buildInfoRow("Phone Number", "Phone Number"),
                _buildInfoRow("Location", "Location"),

                _buildSectionTitle("ACADEMIC DETAILS"),
                _buildInfoRow(
                  "Programme & Branch",
                  "Program Branch",
                  editable: false,
                ),
                _buildInfoRow("Current Year", "year", editable: false),
                _buildInfoRow("Batch", "Batch", editable: false),
                _buildInfoRow("Roll Number", "_id", editable: false),

                _buildSectionTitle("CAREER INTERESTS"),
                _buildInfoRow("Domain", "Domain"),
                _buildInfoRow("Preferred Roles", "Preferred Role"),
                _buildInfoRow("Higher Studies", "Higher Studies"),
                _buildInfoRow("Target Companies", "Dream Company"),

                _buildSectionTitle("SKILLS & ACHIEVEMENTS"),
                _buildInfoRow("Technical Skills", "Technical Skills"),
                _buildInfoRow("Certifications", "Certification"),
                _buildInfoRow("Projects", "Projects"),
                _buildInfoRow("Clubs/Leadership", "Clubs"),

                if (roll == "Alumni") ...[
                  _buildSectionTitle("CAREER INFORMATION"),
                  _buildInfoRow("Current Job Title", "Current Job"),
                  _buildInfoRow("Company", "Company"),
                  _buildInfoRow("Years of Experieance", "Experience Year"),
                  _buildInfoRow("Worked In", "Working In"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
