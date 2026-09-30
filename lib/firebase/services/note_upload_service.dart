import 'package:fyp_ui_design/config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class NoteUploadService {
  static const int maxFileSize = 10 * 1024 * 1024;

  // ============================================================
  // GET TEACHER NAME FROM FIRESTORE
  // ============================================================
  static Future<String> _getTeacherName(String teacherId) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(teacherId)
        .get();

    return snap.data()?['name'] ?? 'Unknown Teacher';
  }

  // ============================================================
  // UPLOAD NOTE
  // ============================================================
  static Future<dynamic> uploadNote({
    required String fileName,
    required List<int> fileBytes,
    required String title,
    required String university,
    required String location,
    required String department,
    required int semester,
    required String resourceType,
    required String subject,
    String? noteId,
  }) async {
    try {
      // ========================================================
      // CHECK FILE SIZE
      // ========================================================
      final fileSize = fileBytes.length;

      if (fileSize > maxFileSize) {
        return {
          "success": false,
          "error": "File size must be 10 MB or less.",
        };
      }

      // ========================================================
      // GET CURRENT USER
      // ========================================================
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return {
          "success": false,
          "error": "User not logged in.",
        };
      }

      final teacherId = user.uid;

      // ========================================================
      // GET TEACHER NAME
      // ========================================================
      final teacherName = await _getTeacherName(teacherId);

      // ========================================================
      // GET FIREBASE ID TOKEN
      // ========================================================
      final token = await user.getIdToken();

      // ========================================================
      // CREATE MULTIPART REQUEST
      // ========================================================
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/upload-note"),
      );

      // ========================================================
      // AUTHORIZATION HEADER
      // ========================================================
      request.headers['Authorization'] = 'Bearer $token';

      // ========================================================
      // ATTACH FILE USING BYTES
      //
      // This works on:
      // Android
      // Web / Chrome
      // ========================================================
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          fileBytes,
          filename: path.basename(fileName),
        ),
      );

      // ========================================================
      // ATTACH FORM FIELDS
      // ========================================================
      request.fields.addAll({
        "title": title.trim(),
        "university": university.trim(),
        "location": location.trim(),
        "department": department.trim(),
        "semester": semester.toString(),
        "category": resourceType.trim(),
        "subject": subject.trim(),
        "teacherName": teacherName,
        if (noteId != null) "noteId": noteId,
      });

      // ========================================================
      // SEND REQUEST
      // ========================================================
      final response = await request.send().timeout(
        const Duration(minutes: 2),
      );

      // ========================================================
      // READ RESPONSE
      // ========================================================
      final responseBody = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: $responseBody");

      // ========================================================
      // CONVERT RESPONSE TO JSON
      // ========================================================
      final data = jsonDecode(responseBody);

      return data;
    } catch (e) {
      print("Note upload error: $e");
      return {
        "success": false,
        "error": "Unstable Internet Connection. Please try again.",
      };
    }
  }
}

