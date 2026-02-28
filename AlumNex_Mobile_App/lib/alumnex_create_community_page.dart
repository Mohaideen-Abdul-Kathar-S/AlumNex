import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_tab_community_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexCreateCommunityPage extends StatefulWidget {
  final String rollno;

  const AlumnexCreateCommunityPage({super.key, required this.rollno});

  @override
  State<AlumnexCreateCommunityPage> createState() =>
      _AlumnexCreateCommunityPageState();
}

class _AlumnexCreateCommunityPageState
    extends State<AlumnexCreateCommunityPage> {
  final TextEditingController _communityNameController =
      TextEditingController();
  late Future<List<Map<String, dynamic>>> existingGroups;
  List<String> selectedGroups = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
     existingGroups = AlumnexTabCommunityPage(rollno: widget.rollno)
      .fetchGroups()
      .then((result) {
        // result is the whole JSON
        return List<Map<String, dynamic>>.from(result['groups']!);
      });
  }

void _createCommunity() async {
  String name = _communityNameController.text.trim();
  if (name.isEmpty || selectedGroups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Community name and at least one group required'),
      ),
    );
    return;
  }

  Map<String, dynamic> community = {
    "name": name,
    "groups": selectedGroups,
    "created_by": widget.rollno,
  };

  try {
    final response = await http.post(
      Uri.parse("$urI/create_community"), // 🔥 your Flask API
      headers: {"Content-Type": "application/json"},
      body: json.encode(community),
    );

    if (response.statusCode == 201) {
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ ${data['message']}")),
      );
    } else {
      var error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${error['error']}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⚠️ API call failed: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Community")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _communityNameController,
              decoration: const InputDecoration(labelText: 'Community Name'),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Groups to Add",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
           Expanded(
  child: FutureBuilder<List<Map<String, dynamic>>>(
    future: existingGroups,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text("No groups found"));
      }

      final groups = snapshot.data!;
      print(groups); // Debugging line to check fetched groups

      return ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          // assuming your group map has a "name" field
          String groupName = groups[index]["id"];
          bool isSelected = selectedGroups.contains(groupName);

          return CheckboxListTile(
            title: Text(groups[index]["name"] ?? "Unnamed Group"),
            value: isSelected,
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  selectedGroups.add(groupName);
                } else {
                  selectedGroups.remove(groupName);
                }
              });
            },
          );
        },
      );
    },
  ),
),
            ElevatedButton(
              onPressed: _createCommunity,
              child: const Text("Create Community"),
            ),
          ],
        ),
      ),
    );
  }
}
