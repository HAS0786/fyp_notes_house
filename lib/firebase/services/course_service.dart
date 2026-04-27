import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<CourseModel>> getCourses({
    required String universityId,
    required String departmentId,
    required int semester,
  }) {
    return _db
        .collection('universities')
        .doc(universityId)
        .collection('departments')
        .doc(departmentId)
        .collection('semesters')
        .doc('semester_$semester')
        .collection('courses')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  static Future<void> addCourse({
    required String universityId,
    required String departmentId,
    required int semester,
    required String name,
  }) async {
    await _db
        .collection('universities')
        .doc(universityId)
        .collection('departments')
        .doc(departmentId)
        .collection('semesters')
        .doc('semester_$semester')
        .collection('courses')
        .add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
