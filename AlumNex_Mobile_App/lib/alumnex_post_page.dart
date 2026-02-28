import 'dart:async';
import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_postdetails_page.dart';
import 'package:alumnex/alumnex_view_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexPostPage extends StatefulWidget {
  final String rollno;

  final String roll;

  const AlumnexPostPage({super.key, required this.rollno, required this.roll});

  @override
  State<AlumnexPostPage> createState() => _AlumnexPostPageState();
}

Widget buildPost(dynamic post) {
  return post['postImageId'] != null
      ? Image.network(
        '$urI/get-post-image/${post['postImageId']}',
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              height: 300,
              color: Colors.grey[300],
              child: Center(child: Text('Image Not Found')),
            ),
      )
      : Container(
        height: 300,
        color: Colors.grey[300],
        child: Center(child: Text('No Image')),
      );
}

class _AlumnexPostPageState extends State<AlumnexPostPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  String pageName = 'Posts';
  late Future<List<dynamic>> _postsFuture;
  late String rollno;
  //TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  Timer? _debounce;
  List<ChatMessage> messages = [];
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();

  List<dynamic> connections = [];
  bool isLoading = true;
  final String apiUrl = '$urI';
  List<String> likedPosts = [];
  List<dynamic> alumniList = [];
  @override
  void initState() {
    super.initState();
    rollno = widget.rollno;
    fetchConnections();
    _postsFuture = fetchPosts();
    fetchSavedPosts(rollno);
     fetchAlumni();
  }

    Future<void> fetchAlumni() async {
    try {
      final url = Uri.parse("$urI/api/alumni"); // change to your backend URL
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          alumniList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠️ Error: $e");
      setState(() => isLoading = false);
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

  void _sendMessages(String postid, String reciever) async {
    final text = widget.rollno + " sent post for you -> " + postid;
    if (text.isEmpty) return;

    final message = {
      'sender': widget.rollno,
      'receiver': reciever,
      'text': text,
    };

    final response = await http.post(
      Uri.parse('$apiUrl/send_message'),
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

  Future<void> fetchConnections() async {
    final res = await http.get(
      Uri.parse('$urI/get_connections/${widget.rollno}'),
    );

    if (res.statusCode == 200) {
      List ids = jsonDecode(res.body);
      List<dynamic> tempUsers = [];

      for (var id in ids) {
        final userRes = await http.get(
          Uri.parse('$urI/get_user/$id'),
        );

        if (userRes.statusCode == 200) {
          final userData = jsonDecode(userRes.body);
          tempUsers.add(userData);
        }
      }

      setState(() {
        connections = tempUsers;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print("Error fetching connections");
    }
  }

  Future<void> sendMessage(String message) async {
    print("In calling sec $message");

    final url = Uri.parse('$urI/aura_assistant');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "query": message,
        "context": {
          "id": rollno,
          // "name": "Mohaideen",
          // "branch": "CSD",
          // "year": "3rd Year",
          // "interests": ["Cloud Computing", "AI"]
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aiReply = data['response'] ?? 'No response from AI.';

      setState(() {
        messages.add(ChatMessage(text: aiReply, isUser: false));
      });

      // Scroll to bottom after short delay to ensure UI has updated
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      print('AI Response: $aiReply');
    } else {
      setState(() {
        messages.add(
          ChatMessage(
            text: 'Error: ${response.statusCode}\n${response.body}',
            isUser: false,
          ),
        );
      });
      print('Error: ${response.body}');
    }
  }

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

  Future<Map<String, dynamic>> fetchPollResults(String pollId) async {
    final response = await http.get(
      Uri.parse('$urI/poll_results/$pollId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load poll results');
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

  Future<void> submitComment(
    String postId,
    String rollno,
    String comment,
  ) async {
    final url = Uri.parse('$urI/submit_comment');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "postId": postId, // Mongo _id as String
        "rollno": rollno,
        "comment": comment,
      }),
    );

    if (response.statusCode == 200) {
      print("Comment submitted!");
    } else {
      print("Failed to submit comment");
    }
  }

  Widget _buildChatBotScreen() {
    return Container(
      height: 700, // Set the height for the mini screen
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Chatbot header (can be a simple title or avatar)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Aura Assistant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          Divider(),
          // Chat messages or UI goes here
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // ✅ Add controller here
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Align(
                    alignment:
                        message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            message.isUser
                                ? Colors.blue[100]
                                : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message.text),
                    ),
                  ),
                );
              },
            ),
          ),

          // Text field for user to type message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        messages.add(ChatMessage(text: text, isUser: true));
                      });

                      _controller.clear();

                      // Scroll to bottom after user message
                      Future.delayed(Duration(milliseconds: 100), () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });

                      // Await sending message (important!)
                      await sendMessage(text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchComments(String postId) async {
    final url = Uri.parse('$urI/get_comments/$postId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {};
    }
  }

  Widget buildPollPost(dynamic post) {
    final List<dynamic> options = post['options'] ?? [];

    return FutureBuilder(
      future: fetchPollResults(post['_id']),
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
                            fetchPollResults(post["_id"]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageName,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 5,
        toolbarHeight: 100,
        shadowColor: accentColor,
        backgroundColor: primaryColor,
        foregroundColor: accentColor,
        actions: [
          Container(
            width: 250,
            height: 40,
            margin: EdgeInsets.only(top: 30, bottom: 30),
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: accentColor),
                SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search here...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    onChanged: (value) {
                      // Add search logic here

                      print('Searching for: $value');

                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(Duration(milliseconds: 300), () {
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

      body: Column(
        children: [
          _searchResults.isEmpty
              ? SizedBox.shrink()
              : Container(
                padding: EdgeInsets.all(10),
                color: secondaryColor.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _searchResults.map((user) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              "$urI/get-profile/${user['_id']}",
                            ),
                            backgroundColor: Colors.grey[300],
                          ),
                          title: Text(
                            user['_id'],
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Roll: ${user['roll']}",
                            style: TextStyle(color: secondaryColor),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => AlumnexViewProfilePage(
                                      temprollno: user['_id'],
                                      temproll: user['roll'],
                                      rollno: rollno,
                                      roll: widget.roll,
                                    ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                ),
              ),
              Container(
                child: alumniList.isEmpty
              ? const Center(child: Text("No Alumni Found"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: alumniList.map((alumni) {
                   
                      final fields = alumni['fields'] ?? {};
                      final fullName =
                          (fields['Full Name'] != null && fields['Full Name'] != "Nill")
                              ? fields['Full Name']
                              : alumni['_id'];
                        final displayName = (fullName.length > 13)
    ? fullName.substring(0, 8) + "..."
    : fullName;

                      return Container(
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: Column(
                          children: [
                             GestureDetector(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlumnexViewProfilePage(
          temprollno: alumni['_id'],
          temproll: alumni['roll'],
          rollno: rollno,
          roll: widget.roll,
        ),
      ),
    );
  },
  child: CircleAvatar(
    radius: 30,
    backgroundImage: NetworkImage(
      "$urI/get-profile/${alumni['_id']}",
    ),
    backgroundColor: Colors.white,
  ),
),
                            const SizedBox(height: 8),
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading posts. ${snapshot.error}'),
                  );
                } else {
                  print("All posts fetched: ${snapshot.data}");

                  final posts =
                      snapshot.data!
                          .where(
                            (post) =>
                                (post['postType'] == "Post" ||
                                    post['type'] == "Post") ||
                                (post['postType'] == "Poll" ||
                                    post['type'] == "Poll"),
                          )
                          .toList();

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postType = post['postType'] ?? post['type'];

                      print("typr of the post is " + postType);
                      Widget postWidget;

                      if (postType == "Post") {
                        postWidget = buildPost(post);
                      } else if (postType == "Poll") {
                        postWidget = buildPollPost(post);
                      } else {
                        postWidget = SizedBox.shrink(); // unknown type
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post['rollno'] ?? '23CDR101',
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
                              child: postWidget,
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
                            Divider(thickness: 1, color: Colors.grey[300]),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the mini chatbot screen (bottom sheet)
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return _buildChatBotScreen();
            },
          );
        },
        child: Icon(Icons.chat),
        backgroundColor: accentColor,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
