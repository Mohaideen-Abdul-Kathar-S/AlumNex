import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_create_community_page.dart';
import 'package:alumnex/alumnex_create_group_page.dart';

import 'package:alumnex/alumnex_group_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexTabCommunityPage extends StatefulWidget {
  final dynamic rollno;

  const AlumnexTabCommunityPage({super.key, required this.rollno});
  Future<Map<String, List<Map<String, dynamic>>>> fetchGroups() async {
    print('Fetching groups for: $rollno');

    final response = await http.get(
      Uri.parse('$urI/get_groups/$rollno'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Groups fetched successfully: $data');

      // groups
      final List<Map<String, dynamic>> groups =
          (data['groups'] as List)
              .map(
                (group) => {
                  'id': group['id'],
                  'name': group['name'],
                  'type': group['type'],
                  'description': group['description'] ?? "",
                },
              )
              .toList();

      // communities
      final List<Map<String, dynamic>> communities =
          (data['communities'] as List)
              .map(
                (comm) => {
                  'id': comm['id'],
                  'name': comm['name'],
                  'type': comm['type'],
                  'description': comm['description'] ?? "",
                },
              )
              .toList();

      return {"groups": groups, "communities": communities};
    } else {
      print("error"+response.toString());
      throw Exception("Failed to load groups & communities");
    }
  }

  @override
  State<AlumnexTabCommunityPage> createState() =>
      _AlumnexTabCommunityPageState();
}

class _AlumnexTabCommunityPageState extends State<AlumnexTabCommunityPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  List<Map<String, String>> groups = [];

  List<Map<String, String>> communities = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: secondaryColor.withOpacity(0.05),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top row buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton("Create Group", Icons.group, () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AlumnexCreateGroupPage(rollno: widget.rollno),
                  ),
                );
              }),
              _buildActionButton("Create Community", Icons.people_outline, () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AlumnexCreateCommunityPage(rollno: widget.rollno),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          // Groups Section
          _buildSectionTitle("Groups"),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future:
                  AlumnexTabCommunityPage(rollno: widget.rollno).fetchGroups(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No groups or communities available.'),
                  );
                }

                final groups = snapshot.data!['groups'] ?? [];
                final communities = snapshot.data!['communities'] ?? [];

                return ListView(
                  children: [
                    if (groups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No groups available."),
                      )
                    else
                      ...groups.map(
                        (group) => _buildTile(
                          group['name'],
                          group['type'],
                          group['id'],
                        ),
                      ),

                    const SizedBox(height: 20),

                    _buildSectionTitle("Communities"),
                    if (communities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No communities available."),
                      )
                    else
                      ...communities.map(
                        (comm) =>
                            _buildTile(comm['name'], comm['type'], comm['id']),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTile(String name, String type, String groupId) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: Icon(
            type == 'Group' ? Icons.group : Icons.apartment,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        subtitle: Text(type),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: accentColor,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => AlumnexGroupChatPage(
                    sender: widget.rollno,
                    groupid: groupId,
                  ),
            ),
          );
        },
      ),
    );
  }
}
