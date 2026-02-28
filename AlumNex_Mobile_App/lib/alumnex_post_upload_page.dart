import 'dart:convert';
import 'dart:io';

import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AlumnexPostUploadPage extends StatefulWidget {
  final String rollno;
  
  final String roll;

  const AlumnexPostUploadPage({super.key, required this.rollno,required this.roll});

  @override
  _AlumnexPostUploadPageState createState() => _AlumnexPostUploadPageState();
}

class _AlumnexPostUploadPageState extends State<AlumnexPostUploadPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
  File? _postImage;
  String? selectedPostType;
  List<Map<String, dynamic>> _additionalDates = [];

  // Controllers for input fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _registerLinkController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _referenceController.dispose();
    _registerLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(Function(DateTime) onDatePicked) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDatePicked(picked);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedImage != null) {
      setState(() {
        _postImage = File(pickedImage.path); // just set the UI
      });
    }
  }



void _uploadPost() async {
  // Create your post data here
  String postId =
      "${widget.rollno}_post_${DateTime.now().millisecondsSinceEpoch}";
  Map<String, dynamic> postData = {
    'rollno':widget.rollno,
    'roll':widget.roll,
    "postId": postId,
    "postType": selectedPostType,
    "title": _titleController.text,
    "content": _contentController.text,
    "reference": _referenceController.text,
  };

  if (selectedPostType != 'Post') {
    postData.addAll({
      "additionalDates": _additionalDates.map(
        (d) => {
          "label": d['label'],
          "date": (d['date'] as DateTime).toIso8601String(),
        },
      ).toList(),
      "registerLink": _registerLinkController.text,
    });
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$urI/upload_post'), // Adjust your server IP
  );

  request.fields['user_id'] = widget.rollno;
  request.fields['post_data'] = json.encode(postData); // send postData as JSON string

  if (_postImage != null) {
    request.files.add(
      await http.MultipartFile.fromPath('post_image', _postImage!.path),
    );
  }

  var response = await request.send();

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post Uploaded Successfully!')),
    );
    Navigator.pop(context); // Close the upload page
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post Upload Failed')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Post Type'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedPostType,
              hint: const Text('Select Post Type'),
              isExpanded: true,
              items:
                  ['Post', 'Inside', 'Outside'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPostType = value;
                });
              },
            ),
            const SizedBox(height: 16),

            if (selectedPostType != null) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (selectedPostType == 'Inside' ||
                selectedPostType == 'Outside') ...[
              const SizedBox(height: 10),
              const Text('Add Dates'),
              ElevatedButton(
                onPressed: () async {
                  String? label = await _askLabel();
                  if (label != null && label.isNotEmpty) {
                    _pickDate((date) {
                      setState(() {
                        _additionalDates.add({'label': label, 'date': date});
                      });
                    });
                  }
                },
                child: const Text('Add Date'),
              ),

              Wrap(
                spacing: 8,
                children:
                    _additionalDates.map((entry) {
                      return Chip(
                        label: Text(
                          '${entry['label']}: ${entry['date'].toString().split(' ')[0]}',
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 10),
              TextField(
                controller: _registerLinkController,
                decoration: const InputDecoration(labelText: 'Register Link'),
              ),
              
            ],
            const SizedBox(height: 20),
            Text("Upload Image (optional)"),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: _pickImage,
              ),
            if (selectedPostType != null)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: _uploadPost,
                  child: const Text('Upload Post'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
