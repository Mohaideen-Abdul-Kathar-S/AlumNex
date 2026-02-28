import 'dart:async';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:alumnex/alumnex_post_page.dart';
import 'package:alumnex/alumnex_view_profile_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AlumnexIndividualChatScreen extends StatefulWidget {
  final dynamic sender;
  final dynamic reciever;
  
  final dynamic roll;

  const AlumnexIndividualChatScreen({
    super.key,
    required this.sender,
    required this.roll,
    required this.reciever,
  });

  @override
  State<AlumnexIndividualChatScreen> createState() =>
      _AlumnexIndividualChatScreenState();
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

class _AlumnexIndividualChatScreenState
    extends State<AlumnexIndividualChatScreen> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];

final String apiUrl = '$urI';

  List<dynamic> connections = [];
  bool isLoading = true;
late final Timer _timer;
@override
void initState() {
  super.initState();
  _loadMessages();
  _timer = Timer.periodic(Duration(seconds: 5), (timer) => _loadMessages());
}

@override
void dispose() {
  _timer.cancel();
  super.dispose();
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
                              '$urI/submit_poll/${widget.sender}',
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
  final text = widget.sender + " sent post for you -> "+ postid;
  if (text.isEmpty) return;

  final message = {
    'sender': widget.sender,
    'receiver':reciever,
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

void _loadMessages() async {
  final uri = Uri.parse('$apiUrl/get_messages?user1=${widget.sender}&user2=${widget.reciever}');
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    setState(() {
      _messages = data.map((e) => {
        'sender': e['sender'],
        'text': e['text'],
        'timestamp': DateTime.parse(e['timestamp']),
      }).toList();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }
}

void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  final message = {
    'sender': widget.sender,
    'receiver': widget.reciever,
    'text': text,
  };

  final response = await http.post(
    Uri.parse('$apiUrl/send_message'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(message),
  );

  if (response.statusCode == 200) {
    setState(() {
      _messages.add({
        'sender': widget.sender,
        'text': text,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();

    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}


Widget _buildMessage(Map<String, dynamic> msg) {
  bool isSender = msg['sender'] == widget.sender;
  String text = msg['text'];

  // Pattern: "xyz sent post for you -> POSTID"
  RegExp postPattern = RegExp(r".*sent post for you -> (\w+)");
  Match? match = postPattern.firstMatch(text);

  bool isPostLink = match != null;
  String? postId = isPostLink ? match.group(1) : null;

  return Align(
    alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isSender ? accentColor : secondaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(isSender ? 14 : 0),
          bottomRight: Radius.circular(isSender ? 0 : 14),
        ),
      ),
      child: isPostLink
          ? InkWell(
              onTap: () {
                openSharedPost(postId!);
              },
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.yellowAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          : Text(
              text,
              style: TextStyle(color: Colors.white),
            ),
    ),
  );
}



// Fetch and open post details
Future<void> openSharedPost(String postId) async {
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
                              rollno: widget.sender,
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
                              .getUserLikeState(post['_id'].toString(), widget.sender),
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
                                  'rollno': widget.sender,
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
                                                  widget.sender,
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



  // Widget _buildMessage(Map<String, dynamic> msg) {
  //   bool isSender = msg['sender'] == widget.sender;

  //   return Align(
  //     alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
  //     child: Container(
  //       margin: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
  //       padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
  //       constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
  //       decoration: BoxDecoration(
  //         // ignore: deprecated_member_use
  //         color: isSender ? accentColor : secondaryColor.withOpacity(0.8),
  //         borderRadius: BorderRadius.only(
  //           topLeft: Radius.circular(14),
  //           topRight: Radius.circular(14),
  //           bottomLeft: Radius.circular(isSender ? 14 : 0),
  //           bottomRight: Radius.circular(isSender ? 0 : 14),
  //         ),
  //       ),
  //       child: Text(
  //         msg['text'],
  //         style: TextStyle(color: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: accentColor,
              child: Text(
                widget.reciever.toString().substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reciever.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: secondaryColor,
              border: Border(top: BorderSide(color: accentColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: accentColor,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: accentColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


