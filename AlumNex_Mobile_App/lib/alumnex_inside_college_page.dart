import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_individual_chat_screen.dart';
import 'package:alumnex/alumnex_postdetails_page.dart';
import 'package:alumnex/alumnex_view_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexInsideCollegePage extends StatefulWidget {
  final String rollno;
  
  final String roll;

  const AlumnexInsideCollegePage({super.key, required this.rollno,required this.roll});

  @override
  State<AlumnexInsideCollegePage> createState() =>
      _AlumnexInsideCollegePageState();
}

class _AlumnexInsideCollegePageState extends State<AlumnexInsideCollegePage> {
  late final rollno;
  late Future<List<dynamic>> _postsFuture;
      List<dynamic> connections = [];

  ScrollController _scrollController = ScrollController();
    List<String> likedPosts = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    rollno = widget.rollno;
    _postsFuture = fetchPosts();
     fetchSavedPosts(rollno);
  }


 void _sendMessages(String postid, String reciever) async {
    final text = widget.rollno + " sent post for you -> " + postid;
    if (text.isEmpty) return;

    final message = {
      'sender': widget.rollno,
      'receiver': reciever,
      'text': text,
    };

    final response = await http.post(
      Uri.parse('$urI/send_message'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(message),
    );

    if (response.statusCode == 200) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }


    Future<void> fetchSavedPosts(String rollno) async {
    print("getSavedPosts called with rollno: $rollno");
    final response = await http.get(
      Uri.parse('$urI/getSavedPosts/$rollno'),
    );

    if (response.statusCode == 200) {
      print(response.body);
      final List<dynamic> decoded = jsonDecode(response.body);

    // Convert dynamic list to List<String>
    setState(() {
      likedPosts = decoded.map((e) => e.toString()).toList();
    });

      print("Saved Posts: $likedPosts");
    } else {
      throw Exception('Failed to load Saved Posts');
    }
  }

  Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('$urI/get_posts'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading posts.'));
          } else {
            final posts =
                snapshot.data!
                    .where((post) => post['postType'] == "Inside")
                    .toList();

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black38,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: FutureBuilder<String>(
                                  future: DataBaseConnection()
                                      .getProfileImageUrl(post['postId']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return SizedBox(
                                        height: 60,
                                        width: 60,
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError ||
                                        !snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Image.asset(
                                        "assets/logo.jpg", // Fallback if error or empty
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      return Image.network(
                                        snapshot.data!,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                  },
                                ),
                              ),

                              SizedBox(width: 10),
                              Expanded(
                                  child: GestureDetector(
    onTap: () {
        Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AlumnexPostdetailsPage(
            rollno: userID,  // or pass rollnoCont.text
            roll: userRoll,  // or dropdownValue
            post: post,
          ),
        ),
      );
    },
    child : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['rollno'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      post['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AlumnexViewProfilePage(
                                              temprollno: post['rollno'],
                                              temproll: post['roll'],
                                              rollno: rollno,
                                              roll: widget.roll,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.keyboard_double_arrow_right),
                                ),
                            ],
                          ),
                          
                          SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child:
                                post['postImageId'] != null
                                    ? Image.network(
                                      '$urI/get-post-image/${post['postImageId']}',
                                      height: 300,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                height: 300,
                                                color: Colors.grey[300],
                                                child: Center(
                                                  child: Text(
                                                    'Image Not Found',
                                                  ),
                                                ),
                                              ),
                                    )
                                    : Container(
                                      height: 300,
                                      color: Colors.grey[300],
                                      child: Center(child: Text('No Image')),
                                    ),
                          ),
                          SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    FutureBuilder<int>(
                                      future: DataBaseConnection()
                                          .getUserLikeState(
                                            post['_id'].toString(),
                                            rollno,
                                          ),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Icon(
                                            Icons.thumb_up_alt_outlined,
                                          );
                                        }
                                        int likeState = snapshot.data!;

                                        return IconButton(
                                          icon: Icon(
                                            likeState == 1
                                                ? Icons.thumb_up
                                                : Icons.thumb_up_alt_outlined,
                                          ),
                                          onPressed: () async {
                                            dynamic data = {
                                              '_id': post['_id'],
                                              'rollno': rollno,
                                            };
                                            await DataBaseConnection()
                                                .update_likes(data);
                                            // Call setState to refresh FutureBuilder after like toggling
                                            setState(() {
                                              //likeState = likeState == 1 ? 0 : 1;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                    FutureBuilder<List<int>>(
                                      future: DataBaseConnection().getLikes(
                                        post['_id'].toString(),
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Text("...");
                                        } else if (snapshot.hasError) {
                                          return Text("Error");
                                        } else {
                                          return Text(
                                            '${snapshot.data?[0]} Likes',
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        Map<String, dynamic> comments =
                                            await fetchComments(post['_id']);
                                        print(comments);

                                        TextEditingController
                                        _commentController =
                                            TextEditingController();

                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (context) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                                left: 16,
                                                right: 16,
                                                top: 10,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Comments",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),

                                                  // 🧠 COMMENT LIST (IF AVAILABLE)
                                                  if (comments.isNotEmpty)
                                                    ...comments.entries.map(
                                                      (entry) => ListTile(
                                                        leading: CircleAvatar(
                                                          child: Text(
                                                            entry.key[0],
                                                          ),
                                                        ),
                                                        title: Text(entry.key),
                                                        subtitle: Text(
                                                          entry.value,
                                                        ),
                                                      ),
                                                    ),
                                                  if (comments.isEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Text(
                                                        "No comments yet.",
                                                      ),
                                                    ),

                                                  Divider(),

                                                  // COMMENT INPUT
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              _commentController,
                                                          decoration: InputDecoration(
                                                            hintText:
                                                                'Add a comment...',
                                                            border:
                                                                OutlineInputBorder(),
                                                            contentPadding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.send),
                                                        onPressed: () {
                                                          String comment =
                                                              _commentController
                                                                  .text
                                                                  .trim();
                                                          if (comment
                                                              .isNotEmpty) {
                                                            submitComment(
                                                              post['_id'],
                                                              rollno,
                                                              comment,
                                                            );
                                                            Navigator.pop(
                                                              context,
                                                            ); // Close and refresh later
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 10),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },

                                      icon: Icon(Icons.comment),
                                    ),
                                    FutureBuilder<List<int>>(
                                      future: DataBaseConnection().getLikes(
                                        post['_id'].toString(),
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Text("...");
                                        } else if (snapshot.hasError) {
                                          return Text("Error");
                                        } else {
                                          return Text(
                                            '${snapshot.data?[1]} Commands',
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.share),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (context) {
                                            return Padding(
                                              padding: const EdgeInsets.all(
                                                16.0,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Share Post",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),

                                                  // List of connections
                                                  connections.isNotEmpty
                                                      ? ListView.builder(
                                                        shrinkWrap:
                                                            true, // Important for bottom sheet
                                                        physics:
                                                            NeverScrollableScrollPhysics(),
                                                        itemCount:
                                                            connections.length,
                                                        itemBuilder: (
                                                          context,
                                                          index,
                                                        ) {
                                                          final user =
                                                              connections[index];
                                                          return ListTile(
                                                            leading: CircleAvatar(
                                                              backgroundImage:
                                                                  user['profile'] !=
                                                                          null
                                                                      ? NetworkImage(
                                                                        user['profile'],
                                                                      )
                                                                      : AssetImage(
                                                                            'assets/default_profile.png',
                                                                          )
                                                                          as ImageProvider,
                                                            ),
                                                            title: Text(
                                                              user['_id'] ??
                                                                  'Unknown User',
                                                            ),
                                                            subtitle: Text(
                                                              user['roll'] ??
                                                                  '',
                                                            ),
                                                            trailing: IconButton(
                                                              icon: Icon(
                                                                Icons.send,
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                _sendMessages(
                                                                  post['_id'], // Pass post ID
                                                                  user['_id'], // Pass user ID
                                                                );
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      )
                                                      : Center(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "No connections found",
                                                          ),
                                                        ),
                                                      ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    Text('Share'),
                                  ],
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        likedPosts.contains(post['_id'])
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color:
                                            likedPosts.contains(post['_id'])
                                                ? Colors.blue
                                                : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final postId = post['_id'];
                                        final userId =
                                            rollno; // use your logged-in user's rollno
                                        print(
                                          "Toggling save for post: $postId by user: $userId",
                                        );
                                        final response = await http.get(
                                          Uri.parse(
                                            '$urI/saveposts/$userId/$postId',
                                          ),
                                        );

                                        if (response.statusCode == 200) {
                                          print(likedPosts);
                                          setState(() {
                                            if (likedPosts.contains(postId)) {
                                              likedPosts.remove(
                                                postId,
                                              ); // toggle locally
                                            } else {
                                              likedPosts.add(postId);
                                            }
                                          });
                                          print(likedPosts);
                                        } else {
                                          print(
                                            "Error saving post: ${response.body}",
                                          );
                                        }
                                      },
                                    ),
                                    Text(
                                      likedPosts.contains(post['_id'])
                                          ? "Saved"
                                          : "Save",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
