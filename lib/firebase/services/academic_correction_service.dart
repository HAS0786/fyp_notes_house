import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicCorrectionService {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // RENAME UNIVERSITY
  // ============================================================

  static Future<void> renameUniversity({
    required String oldName,
    required String newName,
  }) async {
    final oldValue = oldName.trim();
    final newValue = newName.trim();

    if (oldValue.isEmpty || newValue.isEmpty) {
      throw Exception("University name cannot be empty.");
    }

    if (oldValue == newValue) {
      throw Exception("No changes were made.");
    }

    // ----------------------------------------------------------
    // Find old university
    // ----------------------------------------------------------

    final oldQuery = await _db
        .collection('universities')
        .where('name', isEqualTo: oldValue)
        .limit(1)
        .get();

    if (oldQuery.docs.isEmpty) {
      throw Exception(
        "University '$oldValue' was not found.",
      );
    }

    final oldDoc = oldQuery.docs.first;

    // ----------------------------------------------------------
    // Check duplicate
    // ----------------------------------------------------------

    final duplicateQuery = await _db
        .collection('universities')
        .where('name', isEqualTo: newValue)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty &&
        duplicateQuery.docs.first.id != oldDoc.id) {
      throw Exception(
        "University '$newValue' already exists.",
      );
    }

    // ----------------------------------------------------------
    // Create new university document
    // ----------------------------------------------------------

    final newDocId = newValue.toLowerCase();

    final universityData =
    Map<String, dynamic>.from(oldDoc.data());

    universityData['name'] = newValue;

    await _db
        .collection('universities')
        .doc(newDocId)
        .set(universityData);

    // ----------------------------------------------------------
    // Update departments
    // ----------------------------------------------------------

    await _updateField(
      collection: 'departments',
      field: 'university',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Update notes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'notes',
      field: 'university',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Update quizzes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'quizzes',
      field: 'university',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Delete old university document
    // ----------------------------------------------------------

    if (oldDoc.id != newDocId) {
      await _db
          .collection('universities')
          .doc(oldDoc.id)
          .delete();
    }
  }

  // ============================================================
  // RENAME DEPARTMENT
  // ============================================================

  static Future<void> renameDepartment({
    required String oldName,
    required String newName,
    required String university,
    required String location,
  }) async {
    final oldValue = oldName.trim();
    final newValue = newName.trim();

    if (oldValue.isEmpty || newValue.isEmpty) {
      throw Exception("Department name cannot be empty.");
    }

    if (oldValue == newValue) {
      throw Exception("No changes were made.");
    }

    // ----------------------------------------------------------
    // Find department
    // ----------------------------------------------------------

    final oldQuery = await _db
        .collection('departments')
        .where('name', isEqualTo: oldValue)
        .where('university', isEqualTo: university)
        .where('location', isEqualTo: location)
        .limit(1)
        .get();

    if (oldQuery.docs.isEmpty) {
      throw Exception(
        "Department '$oldValue' was not found.",
      );
    }

    final oldDoc = oldQuery.docs.first;

    // ----------------------------------------------------------
    // Check duplicate department
    // ----------------------------------------------------------

    final duplicateQuery = await _db
        .collection('departments')
        .where('name', isEqualTo: newValue)
        .where('university', isEqualTo: university)
        .where('location', isEqualTo: location)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty &&
        duplicateQuery.docs.first.id != oldDoc.id) {
      throw Exception(
        "Department '$newValue' already exists "
            "for this university and location.",
      );
    }

    // ----------------------------------------------------------
    // New document ID
    // ----------------------------------------------------------

    final newDocId =
    '${university}_${location}_$newValue'
        .toLowerCase();

    final departmentData =
    Map<String, dynamic>.from(oldDoc.data());

    departmentData['name'] = newValue;

    await _db
        .collection('departments')
        .doc(newDocId)
        .set(departmentData);

    // ----------------------------------------------------------
    // Update courses
    // ----------------------------------------------------------

    await _updateField(
      collection: 'courses',
      field: 'department',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Update notes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'notes',
      field: 'department',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Update quizzes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'quizzes',
      field: 'department',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Delete old document
    // ----------------------------------------------------------

    if (oldDoc.id != newDocId) {
      await _db
          .collection('departments')
          .doc(oldDoc.id)
          .delete();
    }
  }

  // ============================================================
  // RENAME COURSE / SUBJECT
  // ============================================================

  static Future<void> renameCourse({
    required String oldName,
    required String newName,
    required String department,
  }) async {
    final oldValue = oldName.trim();
    final newValue = newName.trim();

    if (oldValue.isEmpty || newValue.isEmpty) {
      throw Exception("Course name cannot be empty.");
    }

    if (oldValue == newValue) {
      throw Exception("No changes were made.");
    }

    // ----------------------------------------------------------
    // Find course
    // ----------------------------------------------------------

    final oldQuery = await _db
        .collection('courses')
        .where('name', isEqualTo: oldValue)
        .where('department', isEqualTo: department)
        .limit(1)
        .get();

    if (oldQuery.docs.isEmpty) {
      throw Exception(
        "Course '$oldValue' was not found.",
      );
    }

    final oldDoc = oldQuery.docs.first;

    // ----------------------------------------------------------
    // Duplicate check
    // ----------------------------------------------------------

    final duplicateQuery = await _db
        .collection('courses')
        .where('name', isEqualTo: newValue)
        .where('department', isEqualTo: department)
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty &&
        duplicateQuery.docs.first.id != oldDoc.id) {
      throw Exception(
        "Course '$newValue' already exists "
            "in this department.",
      );
    }

    // ----------------------------------------------------------
    // New ID
    // ----------------------------------------------------------

    final newDocId =
    '${department}_$newValue'
        .toLowerCase();

    final courseData =
    Map<String, dynamic>.from(oldDoc.data());

    courseData['name'] = newValue;

    await _db
        .collection('courses')
        .doc(newDocId)
        .set(courseData);

    // ----------------------------------------------------------
    // Update Notes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'notes',
      field: 'subject',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Update Quizzes
    // ----------------------------------------------------------

    await _updateField(
      collection: 'quizzes',
      field: 'subject',
      oldValue: oldValue,
      newValue: newValue,
    );

    // ----------------------------------------------------------
    // Delete old document
    // ----------------------------------------------------------

    if (oldDoc.id != newDocId) {
      await _db
          .collection('courses')
          .doc(oldDoc.id)
          .delete();
    }
  }

  // ============================================================
  // UPDATE FIELD HELPER
  // ============================================================

  static Future<void> _updateField({
    required String collection,
    required String field,
    required String oldValue,
    required String newValue,
  }) async {

    final snapshot = await _db
        .collection(collection)
        .where(
      field,
      isEqualTo: oldValue,
    )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    // Firestore batch supports up to 500 writes.
    const batchLimit = 450;

    for (
    int start = 0;
    start < snapshot.docs.length;
    start += batchLimit
    ) {

      final batch = _db.batch();

      final end =
      (start + batchLimit)
          .clamp(
        0,
        snapshot.docs.length,
      );

      final docs =
      snapshot.docs.sublist(
        start,
        end,
      );

      for (final doc in docs) {

        batch.update(
          doc.reference,
          {
            field: newValue,
          },
        );
      }

      await batch.commit();
    }
  }
}