import 'dart:convert';
import 'package:alumnex/alumn_global.dart';
import 'package:alumnex/alumnex_mentor_request_page.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class DataBaseConnection {
  Future<String> RegistrationPage(dynamic data) async {
    print("hello.hhghh");
    try {
      final res = await http.post(
        Uri.parse("$urI/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      return jsonDecode(res.body)['message'];
    } catch (e) {
      print(e);
    }
    print("success reg");
    return "success";
  }

  Future<int> LoginPage(dynamic data) async {
    try {
      final res = await http.post(
        Uri.parse("$urI/login"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        return 200;
      }
      print("error in login");
    } catch (e) {
      print(e);
    }
    return 401;
  }

  Future<int> updatepersonalinfo(dynamic data) async {
    try {
      final res = await http.post(
        Uri.parse("$urI/personalinfo"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        return 200;
      }
    } catch (e) {
      print(e);
    }
    return 401;
  }

  Future<dynamic> GetPersonInfo(dynamic data) async {
    try {
      final res = await http.post(
        Uri.parse("$urI/getPersonalInfo"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(data),
      );

      if (res.statusCode == 200) {
        return res;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> uploadProfileImage(File imageFile, String userId) async {
    print("profile image upload");
    var uri = Uri.parse('$urI/upload-profile');

    var request =
        http.MultipartRequest('POST', uri)
          ..fields['user_id'] = userId
          ..files.add(
            await http.MultipartFile.fromPath(
              'image', // This is the form field name
              imageFile.path,
              contentType: MediaType('image', 'jpeg'), // Correct spelling
            ),
          );

    var response = await request.send();

    if (response.statusCode == 200) {
      print('✅ Image Uploaded Successfully');
    } else {
      print('❌ Image Upload Failed');
    }
  }

  Future<String> uploadResume(File imageFile, String userId) async {
    var uri = Uri.parse('$urI2/upload-resume');



    var request =
        http.MultipartRequest('POST', uri)
          ..fields['user_id'] = userId
          ..files.add(
  await http.MultipartFile.fromPath(
    'file',  // must match FastAPI param name
    imageFile.path,
    contentType: MediaType('application', 'pdf'),
  ),
);


   var response = await request.send();
var respStr = await response.stream.bytesToString();

if (response.statusCode == 200) {
  print('✅ Resume Uploaded Successfully: $respStr');
  return 'Success';
} else {
  print('❌ Resume Upload Failed: ${response.statusCode}, $respStr');
  return 'Failed';
}

  }

  Future<void> uploadPost(Map<String, dynamic> postData) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$urI/upload_post/'),
    );

    request.fields['postId'] = postData['postId'];
    request.fields['postType'] = postData['postType'];
    request.fields['title'] = postData['title'];
    request.fields['content'] = postData['content'];
    request.fields['reference'] = postData['reference'];
    request.fields['rollno'] = 'yourRollNo'; // Replace with actual roll no.

    if (postData.containsKey('registerLink')) {
      request.fields['registerLink'] = postData['registerLink'];
    }

    if (postData.containsKey('additionalDates')) {
      request.fields['additionalDates'] = jsonEncode(
        postData['additionalDates'],
      );
    }

    request.files.add(
      await http.MultipartFile.fromPath('post', postData['post'].path),
    );

    var res = await request.send();

    if (res.statusCode == 201) {
      print('Post uploaded successfully');
    } else {
      print('Post upload failed: ${res.statusCode}');
    }
  }

  Future<int> update_likes(dynamic data) async {
    try {
      final res = await http.post(
        Uri.parse("$urI/put_like"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        return 1;
      }
      return 0;
    } catch (e) {
      print(e);
    }
    return 0;
  }

 Future<List<int>> getLikes(String id) async {
  try {
    final res = await http.post(
      Uri.parse("$urI/get_like"),
      headers: {"Content-type": "application/json"},
      body: jsonEncode({'_id': id}),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      int likeCount = decoded['like_count'] ?? 0;
      int commentsCount = decoded['comments_count'] ?? 0;
      return [likeCount, commentsCount]; // List with 2 integers
    } else {
      print("Failed to get likes: ${res.statusCode}");
      return [0, 0];
    }
  } catch (e) {
    print("Error: $e");
    return [0, 0];
  }
}

  Future<int> getUserLikeState(String postId, String rollno) async {
    try {
      final res = await http.post(
        Uri.parse("$urI/get_likestate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'_id': postId, 'rollno': rollno}),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['likeState']; // 1 or 0
      }
    } catch (e) {
      print("Error: $e");
    }
    return 0;
  }

  Future<String> getProfileImageUrl(String postId) async {
    try {
      String userId = postId.split('_')[0];
      print("post profile id  " + userId);

      // Just check if the image exists by pinging the endpoint
      final response = await http.get(
        Uri.parse('$urI/get-profile/$userId'),
      );

      if (response.statusCode == 200) {
        // Return the image URL directly
        return '$urI/get-profile/$userId';
      }
    } catch (e) {
      print("Error fetching profile image: $e");
    }
    return '';
  }

  Future<List<MentorRequest>> fetchRequests(String rollno) async {
    final response = await http.get(
      Uri.parse('$urI/get_requests/${rollno}'),
    );
    final List jsonData = jsonDecode(response.body);
    return jsonData.map((e) => MentorRequest.fromJson(e)).toList();
  }

  Future<int> Connect_with_frd(String rollno, String temprollno) async {
    try {
      final response = await http.post(
        Uri.parse('$urI/add_connection'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"rollno": rollno, "temprollno": temprollno}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']; // 1 if success
      } else {
        return 0;
      }
    } catch (e) {
      print("Error connecting with friend: $e");
      return 0;
    }
  }

  Future<int> check_Conn(String rollno, String temprollno) async {
    final response = await http.get(
      Uri.parse(
        "$urI/check_connection/$rollno/$temprollno",
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("connection val " + data["connected"]);
      return data["connected"];
    } else {
      return 0;
    }
  }

  Future<dynamic> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('$urI/get_detsils_leaderboard'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Failed to fetch leaderboard: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching leaderboard: $e");
      return null;
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


}
