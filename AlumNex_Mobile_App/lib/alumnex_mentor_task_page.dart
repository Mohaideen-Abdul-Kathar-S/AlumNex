import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MentorTaskPage extends StatefulWidget {
  final String mentrollno;

  final String rollno;

  const MentorTaskPage({
    super.key,
    required this.mentrollno,
    required this.rollno,
  });

  @override
  State<MentorTaskPage> createState() => _MentorTaskPageState();
}

class _MentorTaskPageState extends State<MentorTaskPage> {
  List<dynamic> tasks = [];
  bool isLoading = true;

  final String baseUrl = urI; // from alumn_global.dart

  // 🎨 Color theme (better visibility)
  final Color primaryColor = const Color(0xFF00695C); // teal dark
  final Color accentColor = const Color(0xFFFF7043); // orange accent
  final Color secondaryColor = const Color(0xFF004D40); // dark greenish
  final Color bgColor = const Color(0xFFF1F8F6); // light tealish background

  @override
  void initState() {
    super.initState();
    fetchMentorTasks();
  }

  /// Fetch tasks assigned by this mentor
  Future<void> fetchMentorTasks() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get_tasks_by_mentor/${widget.mentrollno}"),
      );
      print("Mentor tasks response: ${res.statusCode} ${res.body}");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          if (data is List) {
            tasks = data;
          } else if (data is Map && data.containsKey("tasks")) {
            tasks = data["tasks"];
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching mentor tasks: $e");
      setState(() => isLoading = false);
    }
  }

  /// Assign new task popup
  void _openCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final deadlineController = TextEditingController();
    final references = <String>[]; // store links/file paths
    final workControllers = <TextEditingController>[
      TextEditingController(),
    ]; // at least 1 work

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    "Assign New Task",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: "Title *",
                          ),
                        ),
                        // Description
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                            labelText: "Description",
                          ),
                        ),
                        // Deadline picker
                        TextField(
                          controller: deadlineController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Deadline",
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                            );
                            if (picked != null) {
                              deadlineController.text =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // References
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "References",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (var i = 0; i < references.length; i++)
                          ListTile(
                            title: Text(references[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => references.removeAt(i));
                              },
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () async {
                            // Example: just add a URL or file path for now
                            final refController = TextEditingController();
                            await showDialog(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("Add Reference"),
                                    content: TextField(
                                      controller: refController,
                                      decoration: const InputDecoration(
                                        hintText: "Enter link or file path",
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (refController.text.isNotEmpty) {
                                            setState(
                                              () => references.add(
                                                refController.text,
                                              ),
                                            );
                                          }
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Add"),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Reference"),
                        ),

                        const Divider(),

                        // Works
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Works (Questions)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (var i = 0; i < workControllers.length; i++)
                          TextField(
                            controller: workControllers[i],
                            decoration: InputDecoration(
                              labelText: "Work ${i + 1} ${i == 0 ? '*' : ''}",
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () {
                            setState(
                              () =>
                                  workControllers.add(TextEditingController()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Work"),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: secondaryColor),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (titleController.text.trim().isEmpty ||
                            workControllers[0].text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Title and Work 1 are mandatory ❌"),
                            ),
                          );
                          return;
                        }

                        final works =
                            workControllers
                                .map((c) => c.text.trim())
                                .where((w) => w.isNotEmpty)
                                .toList();

                        await _createTask(
                          titleController.text,
                          descController.text,
                          deadlineController.text,
                          widget.rollno,
                          references,
                          works,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Assign",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  /// API: Assign new task
  Future<void> _createTask(
    String title,
    String desc,
    String deadline,
    String studentId,
    List<String> references,
    List<String> works,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/create_task"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "mentor_id": widget.mentrollno,
          "title": title,
          "description": desc,
          "deadline": deadline,
          "student_id": studentId,
          "attachments": references,
          "works": works, // 👈 each work is one question
        }),
      );

      print("Create task response: ${res.statusCode} ${res.body}");
      if (res.statusCode == 200) {
        fetchMentorTasks();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Task assigned ✅")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to assign task ❌")),
        );
      }
    } catch (e) {
      print("Error creating task: $e");
    }
  }

  /// Navigate to Submissions Page
  void _openSubmissions(String taskId, String taskTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MentorSubmissionListPage(
              taskId: taskId,
              taskTitle: taskTitle,
              baseUrl: baseUrl,
              mentrollno: widget.mentrollno,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Mentor Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task, color: Colors.white),
            onPressed: _openCreateTaskDialog,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
              ? const Center(
                child: Text(
                  "No tasks assigned yet.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              )
              : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: accentColor,
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Deadline: ${task['deadline']}",
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task['description'],
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            () => _openSubmissions(task['_id'], task['title']),
                        child: const Text(
                          "Submissions",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class MentorSubmissionListPage extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String baseUrl;
  final String mentrollno;

  const MentorSubmissionListPage({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.baseUrl,
    required this.mentrollno,
  });

  @override
  State<MentorSubmissionListPage> createState() =>
      _MentorSubmissionListPageState();
}

class _MentorSubmissionListPageState extends State<MentorSubmissionListPage> {
  List<dynamic> submissions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubmissions();
  }

  Future<void> fetchSubmissions() async {
    final res = await http.get(
      Uri.parse("${widget.baseUrl}/get_submissions/${widget.taskId}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        submissions = json.decode(res.body);
        isLoading = false;
      });
      print("sone some "+submissions.toString());
    }
  }

 Future<void> evaluateSubmission(String submissionId, int score, String feedback) async {
  final res = await http.put(
    Uri.parse("${widget.baseUrl}/evaluate_submission/$submissionId"),
    headers: {"Content-Type": "application/json"},
    body: json.encode({
      "score": score,
      "evaluated_by": widget.mentrollno,
      "feedback": feedback
    }),
  );

  if (res.statusCode == 200) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Score submitted ✅")));
    fetchSubmissions();
  } else {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
  }
}

  Future<void> _openEvaluationDialog(String submissionId) async {
    try {
      // 1. Fetch submission details from API
      
      

      final scoreController = TextEditingController();
      final FeedbackController = TextEditingController();

      // 2. Show submission + score entry
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Evaluate Submission",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                   

                    

                    const SizedBox(height: 12),
                    TextField(
                      controller: scoreController,
                      decoration: const InputDecoration(labelText: "Score"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: FeedbackController,
                      decoration: const InputDecoration(labelText: "feedback"),
                      keyboardType: TextInputType.text,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    evaluateSubmission(
                      submissionId,
                      int.parse(scoreController.text),
                      FeedbackController.text.isNotEmpty
                          ? FeedbackController.text
                          : "No feedback provided",
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      print("Error fetching submission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        title: Text(
          "Submissions: ${widget.taskTitle}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : submissions.isEmpty
              ? const Center(
                child: Text(
                  "No submissions yet.",
                  style: TextStyle(fontSize: 16),
                ),
              )
              : 
ListView.builder(
  itemCount: submissions.length,
  itemBuilder: (context, index) {
    final sub = submissions[index];
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student ID
            _buildFieldBox("Student", sub['student_id'] ?? "N/A"),

            // Work
            _buildFieldBox("Work", sub['work'] ?? "N/A"),

            // Content
            _buildFieldBox("Content", sub['content_text'] ?? "No content"),

            // File / PDF View
           // Theory File (using file_id)
// Theory File (using file_id)
if (sub['file_id'] != null && sub['file_id'] != "Nill") 
  ElevatedButton.icon(
  icon: const Icon(Icons.menu_book, color: Colors.white),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () async {
    final Uri url = Uri.parse("$urI/get_file/${sub['file_id']}"); // ✅ your API endpoint

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // opens in browser / PDF viewer
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open file")),
      );
    }
  },
  label: const Text("View Theory File", style: TextStyle(color: Colors.white)),
),

// Practical File (using content_url)
if (sub['content_url'] != null && sub['content_url'] != "Nill") 
  ElevatedButton.icon(
    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: () async {
      final Uri url = Uri.parse(sub['content_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    },
    label: const Text("View Practical File", style: TextStyle(color: Colors.white)),
  ),


            // Submitted At
            _buildFieldBox("Submitted At", sub['submitted_at'] ?? "N/A"),

            const SizedBox(height: 6),

            // If already evaluated
            if (sub['score'] != null) ...[
              _buildFieldBox("✅ Score", sub['score'].toString()),
              if (sub['feedback'] != null) _buildFieldBox("Feedback", sub['feedback']),
              _buildFieldBox("Evaluated By", sub['evaluated_by'] ?? "N/A"),
              _buildFieldBox("Evaluated At", sub['evaluated_at'] ?? "N/A"),
            ],

            const SizedBox(height: 10),

            // Evaluate button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _openEvaluationDialog(sub['_id']),
                child: const Text(
                  "Evaluate",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
),
    );
  }
}


// Reusable function for field box
Widget _buildFieldBox(String title, String value) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey.shade100,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}