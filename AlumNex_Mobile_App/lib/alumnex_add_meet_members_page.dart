import 'dart:async';
import 'dart:io';

import 'package:alumnex/alumn_global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlumnexAddMeetMembersPage extends StatefulWidget {
  final dynamic rollno;
  final dynamic meetId;

  const AlumnexAddMeetMembersPage({
    super.key,
    required this.rollno,
    required this.meetId,
  });

  static const base = 'http://10.149.248.153:5000';

  // ---- Upload template PDF ----
  static Future<Map<String, dynamic>> uploadTemplate(File pdfFile) async {
    var request = http.MultipartRequest("POST", Uri.parse("$urI/template"));
    request.files.add(await http.MultipartFile.fromPath("file", pdfFile.path));
    var res = await request.send();
    if (res.statusCode == 200) {
      var body = await res.stream.bytesToString();
      return json.decode(body);
    }
    throw Exception('Template upload failed: ${res.statusCode}');
  }

  // ---- Upload host signature ----
  static Future<Map<String, dynamic>> uploadSignature(
    String hostId,
    File sigFile,
  ) async {
    var request = http.MultipartRequest("POST", Uri.parse("$urI/signature"));
    request.fields["host_id"] = hostId;
    request.files.add(await http.MultipartFile.fromPath("file", sigFile.path));
    var res = await request.send();
    if (res.statusCode == 200) {
      var body = await res.stream.bytesToString();
      return json.decode(body);
    }
    throw Exception('Signature upload failed: ${res.statusCode}');
  }

  // ---- Distribute certificates ----
  static Future<Map<String, dynamic>> distributeCertificates(
    String meetId,
  ) async {
    final res = await http.post(
      Uri.parse('$urI/distribute_certificates'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'meet_id': meetId}),
    );
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception('Failed: ${res.statusCode} ${res.body}');
  }

  @override
  State<AlumnexAddMeetMembersPage> createState() =>
      _AlumnexAddMeetMembersPageState();
}

class _AlumnexAddMeetMembersPageState extends State<AlumnexAddMeetMembersPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
  Map<String, dynamic>? meetingData;
  TextEditingController searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchMeetingDetails();
  }

  File? templateFile;
  File? signatureFile;

  Future<void> pickTemplate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
    );
    if (result != null) {
      setState(() {
        templateFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> pickSignature() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        signatureFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> generateAllCertificates(
    String meetId,
    String hostId,
    File templateFile,
    File signatureFile,
  ) async {
    // 1. Upload template (only once per app unless changed)
    await AlumnexAddMeetMembersPage.uploadTemplate(templateFile);

    // 2. Upload host signature (per alumni/host)
    await AlumnexAddMeetMembersPage.uploadSignature(hostId, signatureFile);

    // 3. Now distribute certificates for all members in the meeting
    final result = await AlumnexAddMeetMembersPage.distributeCertificates(
      meetId,
    );

    print("Certificates generated: ${result['generated_count']}");
  }

  Future<void> fetchMeetingDetails() async {
    final response = await http.get(
      Uri.parse('$urI/meeting_detail/${widget.meetId}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        meetingData = json.decode(response.body);
      });
    } else {
      print("Failed to fetch meeting data");
    }
  }

  Future<void> searchStudent(String query) async {
    final response = await http.get(
      Uri.parse('$urI/students/search?query=$query'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body);
      });
    } else {
      print("Search failed");
    }
  }

  Future<void> addMember(String studentRoll) async {
    final response = await http.post(
      Uri.parse('$urI/meeting/${widget.meetId}/add_member'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rollno': studentRoll}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Member added successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add member")));
    }
  }

  Future<void> addGroupMembers(String groupType) async {
    final response = await http.post(
      Uri.parse('$urI/meeting/${widget.meetId}/add_group'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'group': groupType}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Group members added")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to add group members")));
    }
  }

  Future<void> _removeMember(String meetingId, String memberId) async {
    final response = await http.delete(
      Uri.parse('$urI/remove_member/$meetingId/$memberId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        meetingData!['members'].remove(memberId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member removed successfully")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to remove member")));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final res = await http.get(Uri.parse('$urI/search_users?q=$query'));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => _searchResults = data.take(4).toList());
      print(_searchResults);
    } else {
      print("Failed to fetch users");
    }
  }

  Future<void> _addMemberToMeeting(String studentId) async {
    final response = await http.post(
      Uri.parse('$urI/add_member_meet'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"meet_id": widget.meetId, "student_id": studentId}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData["message"] ?? "Success")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add member")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Members to Meet",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 5,
        toolbarHeight: 100,
        shadowColor: accentColor,
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        actions: [
          Container(
            width: 250,
            height: 40,
            margin: EdgeInsets.only(top: 30, bottom: 30),
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: accentColor),
                SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search & Add Student',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    onChanged: (value) {
                      // Add search logic here
                      print('Searching for: $value');

                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(Duration(milliseconds: 300), () {
                        searchUsers(value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            meetingData == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._searchResults.map((student) {
                        return ListTile(
                          title: Text(
                            "${student['_id']} (${student['rollno']})",
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              _addMemberToMeeting(student['_id']);
                              setState(() {
                                fetchMeetingDetails();
                              });
                            },
                            child: const Text("Add"),
                          ),
                        );
                      }),

                      // 📝 Meeting Title
                      Text(
                        meetingData!['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 📅 Date and Time
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text("Date: ${meetingData!['date']}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Time: ${meetingData!['start_time']} - ${meetingData!['end_time']}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 🌐 Platform
                      Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text("Platform: ${meetingData!['platform']}"),
                        ],
                      ),

                      // 🔗 Link
                      Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              meetingData!['link'],
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1.5),

                      // 👨‍🏫 Host ID
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text("Host ID: ${meetingData!['host_id']}"),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                238,
                                147,
                                140,
                              ),
                            ),
                            onPressed: () async {
                              final response = await http.delete(
                                Uri.parse(
                                  '$urI/delete_meeting/${meetingData!['_id']}',
                                ),
                              );

                              if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Meeting deleted successfully",
                                    ),
                                  ),
                                );
                                Navigator.pop(
                                  context,
                                  true,
                                ); // send back a signal
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to delete meeting"),
                                  ),
                                );
                              }
                            },
                            child: const Text("Delete Meet"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 👥 Members
                      const Text(
                        "Members Added:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      (meetingData!['members'] != null &&
                              meetingData!['members'].isNotEmpty)
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              meetingData!['members'].length,
                              (index) {
                                final member = meetingData!['members'][index];
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(member),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await _removeMember(
                                          meetingData!['_id'],
                                          member,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                          : const Text(
                            "No members added yet.",
                            style: TextStyle(color: Colors.redAccent),
                          ),

                      const Divider(),
                      // 🔍 Search and Add Member

                      // 👥 Add Group/Community Members
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Members Section
                          const Text(
                            "Add Members",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton(
                                onPressed: () => addGroupMembers("community"),
                                child: const Text("Add Community Members"),
                              ),
                              ElevatedButton(
                                onPressed: () => addGroupMembers("mentoring"),
                                child: const Text("Add Mentoring Members"),
                              ),
                              ElevatedButton(
                                onPressed: () => addGroupMembers("connection"),
                                child: const Text("Add Connection Members"),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 20,
                          ), // spacing between sections
                          // Certification Section
                          const Text(
                            "Certification",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton(
                                onPressed: pickTemplate,
                                child: const Text("Pick Certificate Template"),
                              ),
                              ElevatedButton(
                                onPressed: pickSignature,
                                child: const Text("Pick Signature"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (templateFile != null &&
                                      signatureFile != null) {
                                    await generateAllCertificates(
                                      meetingData!['_id'],
                                      meetingData!['host_id'],
                                      templateFile!,
                                      signatureFile!,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please pick both template and signature",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text("Generate All Certificates"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
