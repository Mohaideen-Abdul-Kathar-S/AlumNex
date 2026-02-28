import 'dart:convert';
import 'dart:io';
import 'package:alumnex/alumn_global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'alumnex_reg_page.dart';

class AlumnexIdCardPage extends StatefulWidget {
  const AlumnexIdCardPage({super.key});

  @override
  State<AlumnexIdCardPage> createState() => _AlumnexIdCardPageState();
}

class _AlumnexIdCardPageState extends State<AlumnexIdCardPage> {
  bool loading = false;
  Map<String, dynamic>? parsedData;

Future<void> pickAndUploadFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ["pdf", "jpg", "jpeg", "png"], // ✅ Support PDF + Images
  );

  if (result != null) {
    File file = File(result.files.single.path!);
    setState(() => loading = true);

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$urI2/parse_id_card"), // 🔹 backend API
    );
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = jsonDecode(resStr);

      setState(() {
        parsedData = data["data"];
        loading = false;
      });

      // Navigate to registration page with parsed data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AlumnexRegPage(prefilledData: parsedData),
        ),
      );
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to parse ID card")),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload ID Card")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: pickAndUploadFile,
                child: const Text("Upload Student ID Card"),
              ),
      ),
    );
  }
}
