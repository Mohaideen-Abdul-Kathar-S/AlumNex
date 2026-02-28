import 'dart:async';
import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_individual_chat_screen.dart';
import 'package:alumnex/alumnex_tab_chats_page.dart';
import 'package:alumnex/alumnex_tab_community_page.dart';
import 'package:alumnex/alumnex_tab_meet_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexChatsPage extends StatefulWidget {
  final dynamic rollno;
  
  final dynamic roll;

  const AlumnexChatsPage({super.key,required this.rollno,required this.roll});

  @override
  State<AlumnexChatsPage> createState() => _AlumnexChatsPageState();
}

class _AlumnexChatsPageState extends State<AlumnexChatsPage> {
  late final dynamic rollno;
  
  String pageName = 'Chats';
    final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

    List<dynamic> _searchResults = [];
  Timer? _debounce;
  String? _errorMessage;


   @override
  void initState() {
    super.initState();
    
    rollno = widget.rollno;
    
  }

  Future<void> searchUsers(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
      _errorMessage = null;
    });
    return;
  }

  try {
    final res = await http.get(
      Uri.parse('$urI/search_users?q=$query'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _searchResults = data.take(4).toList();
        _errorMessage = null;
      });
    } else {
      setState(() {
        _searchResults = [];
        _errorMessage = "Failed to fetch users: ${res.statusCode}";
      });
    }
  } catch (e) {
    setState(() {
      _searchResults = [];
      _errorMessage = "Error occurred: $e";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
            Tab(
                  icon: Icon(Icons.chat_outlined, color: Colors.white,),
                  child: Text("Chats", style: TextStyle(color: Colors.white)),
              
                ),
              Tab(
                  icon: Icon(Icons.groups, color: Colors.white,),
                  child: Text("Communities", style: TextStyle(color: Colors.white)),
              
                ),
                Tab(
                  icon: Icon(Icons.video_chat_outlined, color: Colors.white,),
                  child: Text("Meets", style: TextStyle(color: Colors.white)),
              
                ),
          ],
          ),
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
        body: Stack(
  children: [
    TabBarView(
      children: [
        AlumnexTabChatsPage(rollno: rollno),
        AlumnexTabCommunityPage(rollno : rollno),
        AlumnexTabMeetPage(rollno: rollno,),
      ],
    ),

    // Search overlay
    if (_errorMessage != null || _searchResults.isNotEmpty)
      Container(
        padding: EdgeInsets.all(10),
        color: secondaryColor.withOpacity(0.95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              )
            else
              ..._searchResults.map((user) {
                return Card(
                  child: ListTile(
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
                                (context) => AlumnexIndividualChatScreen(
                                  sender: widget.rollno,
                                  roll: widget.roll,
                                  reciever: user['_id'],
                                ),
                          ),
                        );
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
  ],
),

        

      
      ),
    );
  }
}