import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<NoteModel>> getNotes({
    required String universityId,
    required String departmentId,
    required int semester,
    required String courseId,
  }) {
    return _db
        .collection('universities')
        .doc(universityId)
        .collection('departments')
        .doc(departmentId)
        .collection('semesters')
        .doc('semester_$semester')
        .collection('courses')
        .doc(courseId)
        .collection('notes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => NoteModel.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }
}
