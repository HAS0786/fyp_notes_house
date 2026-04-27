import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthRoleService {
  static Future<void> syncUserToLocal({
    required User user,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      throw Exception('User record not found');
    }

    final data = doc.data()!;

    await prefs.setString('user_role', data['role'] ?? '');
    await prefs.setString('user_name', data['name'] ?? '');
    await prefs.setString('user_uni', data['university'] ?? '');
  }
}
