import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_tab_meet_page.dart';
import 'package:flutter/material.dart';

class AlumnexPostdetailsPage extends StatelessWidget {
  final String rollno;
  final String roll;
  final dynamic post;

  const AlumnexPostdetailsPage({
    super.key,
    required this.rollno,
    required this.roll,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post['title'] ?? "Post Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Title
            Text(
              post['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ✅ Content
            Text(
              post['content'] ?? 'No content',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // ✅ Register link
            if (post['registerLink'] != null &&
    post['registerLink'].toString().isNotEmpty)
  GestureDetector(
    onTap: () async {
      // Use your existing launchURL method
      AlumnexTabMeetPage(rollno: rollno).launchURL(post['registerLink']);
    },
    child: Text(
      "Register Link: ${post['registerLink']}",
      style: const TextStyle(
        fontSize: 16,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    ),
  ),


            const SizedBox(height: 20),

            // ✅ Additional Dates
            if (post['additionalDates'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dates:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...List.generate(
                    post['additionalDates'].length,
                    (i) => Text(
                      "${post['additionalDates'][i]['label']} - ${post['additionalDates'][i]['date']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // ✅ Image (your buildPost function)
            post['postImageId'] != null
                ? Image.network(
                  '$urI/get-post-image/${post['postImageId']}',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(child: Text('Image Not Found')),
                      ),
                )
                : Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No Image')),
                ),
          ],
        ),
      ),
    );
  }
}
