import 'dart:async';
import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexCreateGroupPage extends StatefulWidget {
  final dynamic rollno;

  const AlumnexCreateGroupPage({super.key, required this.rollno});

  @override
  State<AlumnexCreateGroupPage> createState() => _AlumnexCreateGroupPageState();
}

class _AlumnexCreateGroupPageState extends State<AlumnexCreateGroupPage> {
  final TextEditingController _groupTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
TextEditingController searchController = TextEditingController();
    List<dynamic> _searchResults = [];
  Timer? _debounce;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final res = await http.get(
      Uri.parse('$urI/search_users?q=$query'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => _searchResults = data.take(4).toList());
      print(_searchResults);
    } else {
      print("Failed to fetch users");
    }
  }
  List<dynamic> _selectedMembers = [];

void _submitGroup() async {
  final title = _groupTitleController.text.trim();
  final description = _descriptionController.text.trim();

  if (title.isEmpty || _selectedMembers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all required fields')),
    );
    
    return;
  }

  // Prepare the payload
  final payload = {
    "title": title,
    "description": description,
    "members": _selectedMembers,
    "created_by": widget.rollno,// Replace with actual user ID
  };

  try {
    final response = await http.post(
      Uri.parse('$urI/create_group'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData["message"])),
      );
      Navigator.pop(context);
    } else {
      final error = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error["error"] ?? "Failed to create group")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}


  @override
  void dispose() {
    _debounce?.cancel();
    _groupTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor.withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 6,
        toolbarHeight: 100,
        title: Text(
          "Create Group",
          style: TextStyle(
            color: accentColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            width: 250,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      hintText: "Search by Roll No",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Group Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 16),
                    _buildTextField("Group Title", _groupTitleController),
                    const SizedBox(height: 12),
                    _buildTextField("Description (optional)", _descriptionController, maxLines: 3),
                    const SizedBox(height: 12),
                    if (_selectedMembers.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("Added Members", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      Wrap(
                        spacing: 8,
                        children: _selectedMembers.map((rollNo) {
  return Chip(
    label: Text(rollNo),
    backgroundColor: accentColor.withOpacity(0.8),
    deleteIconColor: Colors.white,
    labelStyle: const TextStyle(color: Colors.white),
    onDeleted: () {
      setState(() {
        _selectedMembers.remove(rollNo);
      });
    },
  );
}).toList(),

                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _submitGroup,
                        icon: const Icon(Icons.group_add),
                        label: const Text("Create Group"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_searchResults.isNotEmpty) ...[
  const SizedBox(height: 20),
  Text(
    "Search Results",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: accentColor, // Use the accent color for better contrast
    ),
  ),
  const SizedBox(height: 10),
  Container(
    decoration: BoxDecoration(
      color: secondaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final member = _searchResults[index];
        final alreadyAdded = _selectedMembers.contains(member['_id']);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              member['_id'],
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: alreadyAdded
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: Icon(Icons.add_circle_outline, color: accentColor),
                    onPressed: () {
                      if (!alreadyAdded) {
                        setState(() {
                          _selectedMembers.add(member['_id']);

                        });
                      }
                    },
                  ),
          ),
        );
      },
    ),
  ),
],

          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        filled: true,
        fillColor: secondaryColor.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
