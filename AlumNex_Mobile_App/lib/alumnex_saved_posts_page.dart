import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_individual_chat_screen.dart';
import 'package:alumnex/alumnex_post_page.dart';
import 'package:alumnex/alumnex_view_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexSavedPostsPage extends StatefulWidget {
  final String rollno;
  
  final dynamic roll; // ✅ you forgot to store rollno

  const AlumnexSavedPostsPage({super.key, required this.rollno, required this.roll});

  @override
  State<AlumnexSavedPostsPage> createState() => _AlumnexSavedPostsPageState();
}
 

class _AlumnexSavedPostsPageState extends State<AlumnexSavedPostsPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);
    final ScrollController _scrollController = ScrollController();
     List<dynamic> connections = [];

  List<String> likedPosts = [];

  @override
  void initState() {
    super.initState();
    fetchSavedPosts(widget.rollno);
  }

  Future<void> fetchSavedPosts(String rollno) async {
    print("getSavedPosts called with rollno: $rollno");
    final response = await http.get(
      Uri.parse('$urI/getSavedPosts/$rollno'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      setState(() {
        likedPosts = decoded.map((e) => e.toString()).toList();
      });
      print("Saved Posts: $likedPosts");
    } else {
      throw Exception('Failed to load Saved Posts');
    }
  }

  Widget buildPollPost(dynamic post) {
    final List<dynamic> options = post['options'] ?? [];

    return FutureBuilder(
      future: DataBaseConnection().fetchPollResults(post['_id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(); // loading state
        }

        final pollData = snapshot.data!;
        final results = pollData['results'] as Map<String, dynamic>;
        final totalVotes = pollData['total_votes'];

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.blue[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['question']?.toString() ?? 'Poll Question',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ...options.map((option) {
                final voteInfo =
                    results[option] ?? {'count': 0, 'percentage': 0.0};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await http.post(
                            Uri.parse(
                              '$urI/submit_poll/${widget.rollno}',
                            ),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              'option': option,
                              'poll_id': post['_id'],
                            }),
                          );
                          setState(() {
                            DataBaseConnection().fetchPollResults(post["_id"]);
                          });
                        },
                        child: Text('$option (${voteInfo['count']} votes)'),
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (voteInfo['percentage'] / 100),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      SizedBox(height: 4),
                      Text('${voteInfo['percentage']}%'),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 12),
              Text(
                '${totalVotes} total votes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                post['reference']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
  void _sendMessages(String postid,String reciever) async {
  final text = widget.rollno + " sent post for you -> "+ postid;
  if (text.isEmpty) return;

  final message = {
    'sender': widget.rollno,
    'receiver':reciever,
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



// Fetch and open post details
Future<void> _openSharedPost(String postId) async {
  final res = await http.get(
    Uri.parse('$urI/get_post/$postId'),
  );

  if (res.statusCode == 200) {
    final post = jsonDecode(res.body);
    
                      final postType = post['postType'] ?? post['type'];
                      Widget postWidget;
                      if (postType == "Post") {
                        postWidget = buildPost(post);
                       } else if (postType == "Poll") {
                      postWidget = buildPollPost(post);
                      } 
                      else {
                        postWidget = SizedBox.shrink(); // unknown type
                      }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // so it scrolls if long
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Your Profile Row ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: FutureBuilder<String>(
                        future: DataBaseConnection()
                            .getProfileImageUrl(post['postId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Image.asset(
                              "assets/logo.jpg",
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            post['content'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AlumnexViewProfilePage(
                              temprollno: post['rollno'],
                              temproll: post['roll'],
                              rollno: widget.rollno,
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
                  child: postWidget, // <-- Your post widget
                ),
                SizedBox(height: 10),

                // --- Like, Comment, Share Row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // LIKE COLUMN
                    Column(
                      children: [
                        FutureBuilder<int>(
                          future: DataBaseConnection()
                              .getUserLikeState(post['_id'].toString(), widget.rollno),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Icon(Icons.thumb_up_alt_outlined);
                            }
                            int likeState = snapshot.data!;
                            return IconButton(
                              icon: Icon(
                                likeState == 1
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_alt_outlined,
                              ),
                              onPressed: () async {
                                await DataBaseConnection().update_likes({
                                  '_id': post['_id'],
                                  'rollno': widget.rollno,
                                });
                                setState(() {});
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
                              return Text('${snapshot.data?[0]} Likes');
                            }
                          },
                        ),
                      ],
                    ),

                    // COMMENT COLUMN
                    Column(
                      children: [
                        IconButton(
                          onPressed: () async {
                            Map<String, dynamic> comments =
                                await fetchComments(post['_id']);
                            TextEditingController _commentController =
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
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                    left: 16,
                                    right: 16,
                                    top: 10,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Comments",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      if (comments.isNotEmpty)
                                        ...comments.entries.map((entry) =>
                                            ListTile(
                                              leading: CircleAvatar(
                                                child: Text(entry.key[0]),
                                              ),
                                              title: Text(entry.key),
                                              subtitle: Text(entry.value),
                                            )),
                                      if (comments.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text("No comments yet."),
                                        ),
                                      Divider(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _commentController,
                                              decoration: InputDecoration(
                                                hintText: 'Add a comment...',
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 10),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.send),
                                            onPressed: () {
                                              String comment =
                                                  _commentController.text
                                                      .trim();
                                              if (comment.isNotEmpty) {
                                                submitComment(
                                                  post['_id'],
                                                  widget.rollno,
                                                  comment,
                                                );
                                                Navigator.pop(context);
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
                              return Text('${snapshot.data?[1]} Comments');
                            }
                          },
                        ),
                      ],
                    ),

                    // SHARE COLUMN
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Share Post",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 10),
                                      connections.isNotEmpty
                                          ? ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              itemCount: connections.length,
                                              itemBuilder: (context, index) {
                                                final user =
                                                    connections[index];
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundImage:
                                                        user['profile'] != null
                                                            ? NetworkImage(
                                                                user['profile'])
                                                            : AssetImage(
                                                                    'assets/default_profile.png')
                                                                as ImageProvider,
                                                  ),
                                                  title: Text(user['_id'] ??
                                                      'Unknown User'),
                                                  subtitle: Text(
                                                      user['roll'] ?? ''),
                                                  trailing: IconButton(
                                                    icon: Icon(Icons.send,
                                                        color: Colors.blue),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _sendMessages(
                                                        post['_id'],
                                                        user['_id'],
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            )
                                          : Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child:
                                                    Text("No connections found"),
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

                    // SAVE COLUMN
                    Column(
                      children: [
                        Icon(Icons.bookmark),
                        Text('Save'),
                      ],
                    ),
                  ],
                ),
                Divider(thickness: 1, color: Colors.grey[300]),
              ],
            ),
          ),
        );
      },
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load post")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Posts"),
        backgroundColor: primaryColor,
      ),
      body: likedPosts.isEmpty
          ? const Center(child: Text("No saved posts yet"))
          : ListView.builder(
              itemCount: likedPosts.length,
              itemBuilder: (context, index) {
                final postId = likedPosts[index];
                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text("Post ID: $postId"),
                  onTap: () => _openSharedPost(postId), // ✅ open bottomsheet
                );
              },
            ),
    );
  }
}
