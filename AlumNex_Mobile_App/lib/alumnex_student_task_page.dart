import 'dart:convert';
import 'dart:io';
import 'package:alumnex/alumn_global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexStudentTaskPage extends StatefulWidget {
  final String mentrollno;
  final String mentroll;
  final String rollno;
  final String roll;

  const AlumnexStudentTaskPage({
    super.key,
    required this.mentrollno,
    required this.mentroll,
    required this.rollno,
    required this.roll,
  });

  @override
  State<AlumnexStudentTaskPage> createState() => _AlumnexStudentTaskPageState();
}

class _AlumnexStudentTaskPageState extends State<AlumnexStudentTaskPage> {
  List<dynamic> tasks = [];
  bool isLoading = true;
  final String baseUrl = "$urI";

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get_tasks/${widget.rollno}"),
      );
      if (res.statusCode == 200) {
        setState(() {
          tasks = json.decode(res.body);
          isLoading = false;
        });
        print("outside task"+ tasks.toString());
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  Future<void> submitWork(String taskId, String work) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/submit_task/$taskId"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "student_id": widget.rollno,
          "content_type": "text",
          "content_text": work, // Student's answer (can enhance with input)
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Work submitted ✅")));
        fetchTasks();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to submit ❌")));
      }
    } catch (e) {
      print("Error submitting work: $e");
    }
  }

  void openTaskDetails(dynamic task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TaskDetailPage(
              task: task,
              studentId: widget.rollno,
              baseUrl: baseUrl,
              onSubmitted: fetchTasks,
            ),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Tasks for ${widget.roll}")),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return buildTaskCard(task); // ✅ Use helper
            },
          ),
  );
}

/// Separated card builder for clarity
Widget buildTaskCard(Map<String, dynamic> task) {
  final List<dynamic> evaluations = task['evaluated'] ?? [];
  final List<String> works = List<String>.from(task['works'] ?? []);
  final bool hasEvaluations = evaluations.isNotEmpty;

  if (hasEvaluations) {
    // Case 2: Evaluated task - non-clickable, show scores
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          task['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task['description']),
          const SizedBox(height: 6),
          const Text(
            "Scores:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          // ✅ Match works with evaluations using index
          for (int i = 0; i < evaluations.length; i++)
            Text(
              "Submission Name: ${i < works.length ? works[i] : 'Unknown'} → "
              "Score: ${evaluations[i]['score']}",
            ),
        ],
      ),
        enabled: false, // non-clickable
      ),
    );
  } else {
    // Case 1: Not evaluated - clickable
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          task['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            if (task['works'] != null && task['works'].isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                "Works:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...task['works'].map<Widget>(
                (work) => Text("- $work"),
              ),
            ]
          ],
        ),
        onTap: () => openTaskDetails(task), // goes to details page
      ),
    );
  }
}

}

class TaskDetailPage extends StatefulWidget {
  final dynamic task;
  final String studentId;
  final String baseUrl;
  final VoidCallback onSubmitted;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.studentId,
    required this.baseUrl,
    required this.onSubmitted,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  List<dynamic> submissions = [];

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${widget.baseUrl}/get_submissions/${widget.task['_id']}/${widget.studentId}",
        ),
      );
      if (res.statusCode == 200) {
        setState(() {
          submissions = json.decode(res.body);
        });
      }
    } catch (e) {
      print("Error fetching submissions: $e");
    }
  }

  bool isWorkSubmitted(dynamic task, String work) {
    print(task);
    if (task['turnIn'] == null) return false;

    for (var entry in task['turnIn']) {
      if (entry['work'] == work) {
        return true;
      }
    }
    return false;
  }

  /// Open dialog for choosing type of submission
  Future<void> openSubmissionDialog(String work) async {
    final textController = TextEditingController();
    final linkController = TextEditingController();
    File? selectedFile;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Submit for: $work"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: "Text Answer (Optional)",
                    ),
                  ),
                  TextField(
                    controller: linkController,
                    decoration: const InputDecoration(
                      labelText: "Link (Optional)",
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                      if (result != null) {
                        selectedFile = File(result.files.single.path!);
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload File/PDF"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? textAns =
                      textController.text.isNotEmpty
                          ? textController.text
                          : "No data";
                  String? linkAns =
                      linkController.text.isNotEmpty
                          ? linkController.text
                          : "No data";

                  await submitWork(
                    work,
                    studentId: widget.studentId,
                    taskId: widget.task['_id'],
                    contentText: textAns,
                    contentUrl: linkAns,
                    filePath: selectedFile?.path,
                  );

                  Navigator.pop(context);
                },
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  Future<void> submitWork(
    String work, {
    required String studentId,
    required String taskId,
    String? contentText,
    String? contentUrl,
    String? filePath,
  }) async {
    try {
      if (filePath != null) {
        // Multipart for file upload
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("${widget.baseUrl}/submit_task/$taskId"),
        );
        request.fields["student_id"] = studentId;
        request.fields["work"] = work;
        if (contentText != null) request.fields["content_text"] = contentText;
        if (contentUrl != null) request.fields["content_url"] = contentUrl;

        request.files.add(await http.MultipartFile.fromPath("file", filePath));

        var response = await request.send();
        if (response.statusCode == 200) fetchSubmissions();
      } else {
        // JSON (text/link only)
        var res = await http.post(
          Uri.parse("${widget.baseUrl}/submit_task/$taskId"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "student_id": studentId,
            "work": work,
            "content_text": contentText,
            "content_url": contentUrl,
          }),
        );
        if (res.statusCode == 200) fetchSubmissions();
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final works = List<String>.from(task['works'] ?? []);
    final refs = List<String>.from(task['attachments'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(task['title'])),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Title: ${task['title']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Description: ${task['description']}"),
              Text("Deadline: ${task['deadline']}"),
              const SizedBox(height: 10),
              const Text(
                "References:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var ref in refs)
                InkWell(
                  onTap: () {},
                  child: Text(ref, style: const TextStyle(color: Colors.blue)),
                ),
              const SizedBox(height: 10),
              const Text(
                "Works:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var work in works)
                Card(
                  child: ListTile(
                    title: Text(work),
                    trailing:
                        isWorkSubmitted(task, work)
                            ? const Text(
                              "✅ Submitted",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : ElevatedButton(
                              onPressed: () => openSubmissionDialog(work),
                              child: const Text("Turn In"),
                            ),
                  ),
                ),

              const SizedBox(height: 20),
              if (submissions.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // final submit = exit task
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Final Submit Task"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
