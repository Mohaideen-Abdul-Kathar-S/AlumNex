import 'dart:convert';

import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_database_connection_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlumnexMentorRequestPage extends StatefulWidget {
  final dynamic rollno;

  const AlumnexMentorRequestPage({super.key, required this.rollno});

  @override
  State<AlumnexMentorRequestPage> createState() =>
      _AlumnexMentorRequestPageState();
}

class _AlumnexMentorRequestPageState extends State<AlumnexMentorRequestPage> {
  Future<void> respondToRequest(String id, String response) async {
    final res = await http.post(
      Uri.parse('$urI/respond_request'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id, "response": response}),
    );
    if (res.statusCode == 200) {
      print("request data : "+res.body);
      setState(() {}); // refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<MentorRequest>>(
        future: DataBaseConnection().fetchRequests(widget.rollno),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty)
            return Center(child: Text("No mentor requests"));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final request = snapshot.data![index];
              print("Status: '${request.status}'");

              return Card(
                color: secondaryColor.withOpacity(0.1),
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text("From: ${request.from}"),
                  subtitle: Text("Status: ${request.status}"),
                  trailing:
                      request.status.trim().toLowerCase() == 'pending'
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed:
                                    () => respondToRequest(
                                      request.id,
                                      "Accepted",
                                    ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed:
                                    () => respondToRequest(
                                      request.id,
                                      "Rejected",
                                    ),
                              ),
                            ],
                          )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MentorRequest {
  final String id;
  final String from;
  final String to;
  String status;

  MentorRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
  });

  factory MentorRequest.fromJson(Map<String, dynamic> json) {
    return MentorRequest(
      id: json['id'],
      from: json['from'],
      to: json['to'],
      status: json['status'],
    );
  }
}
