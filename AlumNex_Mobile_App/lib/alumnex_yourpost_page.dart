import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_edit_post_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexYourpostPage extends StatefulWidget {
  final String rollno;

  const AlumnexYourpostPage({super.key, required this.rollno});

  @override
  State<AlumnexYourpostPage> createState() => _AlumnexYourpostPageState();
}

class _AlumnexYourpostPageState extends State<AlumnexYourpostPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  List posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      // 👉 Replace with your laptop IP
      final response = await http.get(
        Uri.parse("$urI/get_post_by_userid/${widget.rollno}"),
      );

      if (response.statusCode == 200) {
        setState(() {
          posts = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No posts found")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching posts: $e")),
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse("$urI/delete_post_by_userid_postid/${widget.rollno}/$postId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          posts.removeWhere((post) => post["_id"] == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Post deleted")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete post")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Your Posts"),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text("No posts available"))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        tileColor: Colors.white,
                        title: Text(
                          post["title"] ?? "No Title",
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          post["content"] ?? "No Content",
                          style: TextStyle(color: secondaryColor),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deletePost(post["_id"]),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: accentColor),
                              onPressed: () {
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlumnexEditPostPage(postId: post["_id"]),
                                  ),
                                );
                              },
                            ),
                          ],
                        ) 
                        
                      ),
                    );
                  },
                ),
    );
  }
}
