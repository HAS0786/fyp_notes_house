import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp_ui_design/config.dart';

class NoteFetchService {
  static Future<List<Map<String, dynamic>>> getNotes({
    required String university,
    required String department,
    required int semester,
    required String category,
  }) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/get-notes"
            "?university=${Uri.encodeComponent(university)}"
            "&department=${Uri.encodeComponent(department)}"
            "&semester=$semester"
            "&category=${Uri.encodeComponent(category)}",
      );

      print("GET NOTES URL: $uri");

      final response = await http.get(uri);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Fetch notes failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Fetch notes error: $e");
      return [];
    }
  }
}