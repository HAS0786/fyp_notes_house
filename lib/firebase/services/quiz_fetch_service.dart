import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizFetchService {
  // static const String baseUrl = "http://192.168.100.13:3000";
  static const String baseUrl = "http://10.99.151.209:3000";

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