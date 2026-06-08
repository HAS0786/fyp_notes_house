import 'dart:io';
import 'package:fyp_ui_design/config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';


class NoteUploadService {
    static Future<String> generateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  /// 🔹 Fetch teacher name from Firestore
  static Future<String> _getTeacherName(String teacherId) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(teacherId)
        .get();

    return snap.data()?['name'] ?? 'Unknown Teacher';
  }

  static Future<dynamic> uploadNote({
    required File file,
    required String title,
    required String university,
    required String location,
    required String department,
    required int semester,
    required String resourceType,
    required String subject,
    required String fileId, String? noteId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {"success": false};

      final teacherId = user.uid;
      final teacherName = await _getTeacherName(teacherId);

      // 🔥 GET TOKEN (CRITICAL)
      final token = await user.getIdToken();

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload-note"),
      );

      // 🔥 ADD AUTH HEADER (MOST IMPORTANT FIX)
      request.headers['Authorization'] = 'Bearer $token';

      // 📎 Attach File
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: basename(file.path),
        ),
      );

      // 📄 Attach Fields
      request.fields.addAll({
        "title": title.trim(),
        "university": university.trim(),
        "location": location.trim(),
        "department": department.trim(),
        "semester": semester.toString(),
        "category": resourceType.trim(),
        "subject": subject.trim(),
        "teacherName": teacherName,
        "fileId": fileId,
        if (noteId != null) "noteId": noteId,
      });

      // 🚀 SEND REQUEST
      final response = await request.send();

      // 🔍 DEBUG (VERY IMPORTANT)
      final responseBody = await response.stream.bytesToString();
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: $responseBody");

      // return response.statusCode == 200;
      final data = jsonDecode(responseBody);

      return data;
    } catch (e) {
      print("Note upload error: $e");
      return {"success": false};
    }
  }
}