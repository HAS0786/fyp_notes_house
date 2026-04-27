import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/department_model.dart';

class DepartmentService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<DepartmentModel>> getDepartments(String universityId) {
    return _db
        .collection('universities')
        .doc(universityId)
        .collection('departments')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => DepartmentModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  static Future<void> addDepartment(
      String universityId, String name) async {
    await _db
        .collection('universities')
        .doc(universityId)
        .collection('departments')
        .add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
