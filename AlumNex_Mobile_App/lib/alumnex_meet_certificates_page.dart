import 'dart:convert';
import 'dart:io';
import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AlumnexMeetCertificatesPage extends StatefulWidget {
  final String rollno;

  const AlumnexMeetCertificatesPage({super.key, required this.rollno});

  @override
  State<AlumnexMeetCertificatesPage> createState() =>
      _AlumnexMeetCertificatesPageState();
}

class _AlumnexMeetCertificatesPageState
    extends State<AlumnexMeetCertificatesPage> {
  List<dynamic> certificates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCertificates();
  }


Future<void> getCertificate(String meetId, String studentId) async {
  final url = Uri.parse("$urI/certificate_file/$meetId/$studentId");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/certificate_${studentId}_$meetId.pdf");
    await file.writeAsBytes(bytes);

    print("✅ Certificate downloaded: ${file.path}");
    OpenFile.open(file.path); // requires open_filex package
  } else {
    print("❌ Error: ${response.body}");
  }
}


  Future<void> fetchCertificates() async {
    try {
      // API endpoint (replace with your server URL)
      final url =
          Uri.parse("$urI/get_certificates/${widget.rollno}");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          certificates = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load certificates")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
Future<String> fetchMeetingTitle(String meetId) async {
  final response = await http.get(
    Uri.parse("$urI/get_meeting_name?meet_id=$meetId"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['title'] ?? "Unknown Meeting";
  } else {
    return "Unknown Meeting";
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Certificates")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : certificates.isEmpty
              ? const Center(child: Text("No certificates found"))
              : ListView.builder(
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final cert = certificates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
  leading: const Icon(
    Icons.workspace_premium,
    color: Colors.blue,
  ),
  title: FutureBuilder<String>(
    future: fetchMeetingTitle(cert['meet_id']),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text("Loading...");
      } else if (snapshot.hasError) {
        return const Text("Error loading title");
      } else {
        return Text("Meet Title: ${snapshot.data}");
      }
    },
  ),
                        subtitle: Text(
                            "Updated: ${cert['updated_at'] ?? 'Unknown'}"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Handle click → open certificate
                          getCertificate(cert['meet_id'], widget.rollno);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

 
