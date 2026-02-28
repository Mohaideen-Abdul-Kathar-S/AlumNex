import 'dart:io';
import 'package:alumnex/alumn_global.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AlumnexResumePage extends StatefulWidget {
  final String rollno;

  const AlumnexResumePage({super.key, required this.rollno});

  @override
  State<AlumnexResumePage> createState() => _AlumnexResumePageState();
}

class _AlumnexResumePageState extends State<AlumnexResumePage> {
  File? _resumeFile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchResume();
  }

  Future<void> _fetchResume() async {
    final url = Uri.parse('$urI/get-resume/${widget.rollno}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/resume_${widget.rollno}.pdf');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        _resumeFile = file;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      print('❌ Resume not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Resume')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _resumeFile != null
              ? SfPdfViewer.file(_resumeFile!)   // ✅ Show PDF
              : const Center(
                  child: Text(
                    'Resume not found',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
    );
  }
}
