import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:alumnex/alumn_global.dart'; // for urI

class AlumnexEditPostPage extends StatefulWidget {
  final String postId; // required for edit

  const AlumnexEditPostPage({super.key, required this.postId});

  @override
  State<AlumnexEditPostPage> createState() => _AlumnexEditPostPageState();
}

class _AlumnexEditPostPageState extends State<AlumnexEditPostPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);

  File? _postImage;
  String? selectedPostType;
  List<Map<String, dynamic>> _additionalDates = [];

  // controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _registerLinkController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    try {
      final response =
          await http.get(Uri.parse('$urI/get_post/${widget.postId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          selectedPostType = data["postType"];
          _titleController.text = data["title"] ?? "";
          _contentController.text = data["content"] ?? "";
          _referenceController.text = data["reference"] ?? "";
          _registerLinkController.text = data["registerLink"] ?? "";

          if (data["additionalDates"] != null) {
            _additionalDates = List<Map<String, dynamic>>.from(
                data["additionalDates"].map((d) => {
                      "label": d["label"],
                      "date": DateTime.parse(d["date"]),
                    }));
          }

          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch post")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _postImage = File(picked.path);
      });
    }
  }

  Future<void> _updatePost() async {
    var request = http.MultipartRequest(
      'PUT', // <-- use PUT for update
      Uri.parse('$urI/update_post/${widget.postId}'),
    );

    Map<String, dynamic> postData = {
      "postType": selectedPostType,
      "title": _titleController.text,
      "content": _contentController.text,
      "reference": _referenceController.text,
    };

    if (selectedPostType != 'Post') {
      postData.addAll({
        "additionalDates": _additionalDates.map((d) {
          return {
            "label": d["label"],
            "date": (d["date"] as DateTime).toIso8601String(),
          };
        }).toList(),
        "registerLink": _registerLinkController.text,
      });
    }

    request.fields['post_data'] = json.encode(postData);

    if (_postImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'post_image',
        _postImage!.path,
      ));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post updated successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  Future<String?> _askLabel() async {
    TextEditingController _labelController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Date Purpose'),
          content: TextField(
            controller: _labelController,
            decoration: const InputDecoration(hintText: 'e.g., Start Date'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _labelController.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedPostType,
              hint: const Text("Select Post Type"),
              isExpanded: true,
              items: ['Post', 'Inside', 'Outside'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                setState(() => selectedPostType = val);
              },
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Content"),
            ),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: "Reference"),
            ),
            if (selectedPostType == "Inside" || selectedPostType == "Outside")
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      String? label = await _askLabel();
                      if (label != null && label.isNotEmpty) {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _additionalDates.add(
                                {"label": label, "date": picked});
                          });
                        }
                      }
                    },
                    child: const Text("Add Date"),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _additionalDates.map((d) {
                      return Chip(
                        label: Text(
                            "${d["label"]}: ${(d["date"] as DateTime).toLocal().toString().split(" ")[0]}"),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _registerLinkController,
                    decoration:
                        const InputDecoration(labelText: "Register Link"),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Change Image"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              onPressed: _updatePost,
              child: const Text("Update Post"),
            )
          ],
        ),
      ),
    );
  }
}
