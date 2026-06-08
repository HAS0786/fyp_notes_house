// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class NoteFetchService {
//   static Future<List<Map<String, dynamic>>> getNotes({
//     required String university,
//     required String department,
//     required int semester,
//     required String category,
//   }) async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('notes')
//           .where('university', isEqualTo: university)
//           .where('department', isEqualTo: department)
//           .where('semester', isEqualTo: semester)
//           .where('category', isEqualTo: category)
//           .orderBy('createdAt', descending: true)
//           .get();
//
//       return querySnapshot.docs.map((doc) {
//         final data = doc.data();
//         data['id'] = doc.id;
//         return data;
//       }).toList();
//     } catch (e) {
//       print(' Fetch notes error: $e');
//       return [];
//     }
//   }
// }

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
        "$baseUrl/get-notes?university=$university&department=$department&semester=$semester&subject=&category=$category",
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("Fetch notes failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print(' Fetch notes error: $e');
      return [];
    }
  }
}
