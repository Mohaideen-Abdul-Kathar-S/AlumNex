import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_individual_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexTabChatsPage extends StatefulWidget {
  final dynamic rollno;

  const AlumnexTabChatsPage({super.key, required this.rollno});

  @override
  State<AlumnexTabChatsPage> createState() => _AlumnexTabChatsPageState();
}

class _AlumnexTabChatsPageState extends State<AlumnexTabChatsPage> {
  final Color primaryColor = const Color(0xFF004d52);
  final Color accentColor = const Color(0xFFe27c43);
  final Color secondaryColor = const Color(0xFF224146);

  List<dynamic> connections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConnections();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor.withOpacity(0.05),

      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: accentColor))
              : connections.isEmpty
              ? Center(
                child: Text(
                  "No connections found",
                  style: TextStyle(color: secondaryColor),
                ),
              )
              : ListView.builder(
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  var user = connections[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          "$urI/get-profile/${user['_id']}",
                        ),
                        backgroundColor: secondaryColor,
                      ),
                      title: Text(
                        user['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      subtitle: Text(
                        user['_id'],
                        style: TextStyle(color: secondaryColor),
                      ),
                      trailing: Icon(Icons.message, color: accentColor),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => AlumnexIndividualChatScreen(
                                  sender: widget.rollno,
                                  roll: widget.rollno,
                                  reciever: user['_id'],
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
