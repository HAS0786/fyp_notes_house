import 'dart:convert';
import 'package:fyp_ui_design/config.dart';
import 'package:http/http.dart' as http;

class QuizFetchService {
  static Future<List<Map<String, dynamic>>> getQuizzes({
    required String university,
    required String department,
    required int semester,
    required String subject,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/get-quizzes?university=$university&department=$department&semester=$semester&subject=$subject",
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Fetch quizzes failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Fetch quizzes error: $e");
      return [];
    }
  }
}