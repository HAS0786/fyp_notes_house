import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizService {
  static const String
  _baseUrl = "http://192.168.100.13:3000";
  // _baseUrl = "http://10.99.151.209:3000";

  static Future<bool> createQuiz({
    required String university,
    required String location,
    required String department,
    required int semester,
    required String subject,
    required List<Map<String, dynamic>> questions, required String type,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final teacherId = user.uid;
      final token = await user.getIdToken();

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(teacherId)
          .get();

      final teacherName =
          snap.data()?['name'] ?? 'Unknown Teacher';

      final response = await http.post(
        Uri.parse("$_baseUrl/upload-quiz"),
        headers: {"Content-Type": "application/json","Authorization": "Bearer $token",},
        body: jsonEncode({
          "university": university,
          "location": location,
          "department": department,
          "semester": semester,
          "subject": subject,
          "teacherId": teacherId,
          "teacherName": teacherName,
          "questions": questions,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Quiz upload error: $e");
      return false;
    }
  }
}
