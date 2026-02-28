import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexGlobalChatPage extends StatefulWidget {
  final String rollno;

  const AlumnexGlobalChatPage({super.key,required this.rollno});

  @override
  State<AlumnexGlobalChatPage> createState() => _AlumnexGlobalChatPageState();
}

class _AlumnexGlobalChatPageState extends State<AlumnexGlobalChatPage> {
  String postType = 'Chat';
  String restriction = 'No restriction';

  final TextEditingController titleController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  List<TextEditingController> pollOptionControllers = [TextEditingController()];

  void addPollOptionField() {
    setState(() {
      pollOptionControllers.add(TextEditingController());
    });
  }

  // Submit Post to backend
  Future<void> submitPost() async {
    final title = titleController.text.trim();
    final question = questionController.text.trim();
    final reference = referenceController.text.trim();
    final options =
        pollOptionControllers
            .map((c) => c.text.trim())
            .where((o) => o.isNotEmpty)
            .toList();

    if (postType == 'Poll' && options.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Add at least 2 poll options")));
      return;
    }
    String postId =
      "${widget.rollno}_post_${DateTime.now().millisecondsSinceEpoch}";

    final postData = {
      'rollno': widget.rollno,
      'postId':postId,
      'type': postType,
      'title': title,
      'question': question,
      'reference': reference,
      'restriction': restriction,
      'options': postType == 'Poll' ? options : [],
    };

    final response = await http.post(
      Uri.parse('$urI/create_post/${widget.rollno}'), // Flask API endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode(postData),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Post Submitted")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting post")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Global Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: postType,
              items:
                  ['Chat', 'Poll']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() => postType = val!);
              },
              decoration: InputDecoration(labelText: 'Post Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: questionController,
              decoration: InputDecoration(labelText: 'Question'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: referenceController,
              decoration: InputDecoration(labelText: 'Reference'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: restriction,
              items:
                  ['No restriction', 'Alumni', 'Student']
                      .map(
                        (res) => DropdownMenuItem(value: res, child: Text(res)),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() => restriction = val!);
              },
              decoration: InputDecoration(labelText: 'Restriction'),
            ),
            if (postType == 'Poll') ...[
              const SizedBox(height: 20),
              const Text(
                'Poll Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...pollOptionControllers
                  .asMap()
                  .entries
                  .map(
                    (entry) => TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: 'Option ${entry.key + 1}',
                      ),
                    ),
                  )
                  .toList(),
              TextButton.icon(
                onPressed: addPollOptionField,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Submit Post'),
              onPressed: () {
                submitPost();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
