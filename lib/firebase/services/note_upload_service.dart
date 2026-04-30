import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class NoteUploadService {
  // static const String baseUrl = "http://192.168.100.13:3000";
  static const String baseUrl = "http://10.99.151.209:3000";

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

  static Future<bool> uploadNote({
    required File file,
    required String title,
    required String university,
    required String location,
    required String department,
    required int semester,
    required String resourceType,
    required String subject,
    required String fileId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

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
      });

      // 🚀 SEND REQUEST
      final response = await request.send();

      // 🔍 DEBUG (VERY IMPORTANT)
      final responseBody = await response.stream.bytesToString();
      print("STATUS: ${response.statusCode}");
      print("RESPONSE: $responseBody");

      return response.statusCode == 200;
    } catch (e) {
      print("Note upload error: $e");
      return false;
    }
  }
}