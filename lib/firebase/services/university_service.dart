import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/university_model.dart';

class UniversityService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<UniversityModel>> getUniversities() {
    return _db.collection('universities').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => UniversityModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  static Future<void> addUniversity(String name, String location) async {
    await _db.collection('universities').add({
      'name': name,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
