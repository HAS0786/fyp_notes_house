import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_list_screen.dart';
import 'package:path/path.dart' as p;
class QuizFilterScreen extends StatefulWidget {
  const QuizFilterScreen({super.key});

  @override
  State<QuizFilterScreen> createState() => _QuizFilterScreenState();
}

class _QuizFilterScreenState extends State<QuizFilterScreen> {
  String? university;
  String? campus;
  String? department;
  String? subject;
  int? semester;

  /// 🔹 UNIVERSITY STREAM
  Stream<List<String>> universitiesStream() {
    return FirebaseFirestore.instance
        .collection('universities')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => doc['name'].toString())
        .toSet()
        .toList());
  }

  /// 🔹 CAMPUS (DEPENDENT ON UNIVERSITY)
  Stream<List<String>> locationsStream() {
    if (university == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('universities')
        .where('name', isEqualTo: normalize(university!))
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => doc['location'].toString())
        .toSet()
        .toList());
  }

  /// 🔹 DEPARTMENT (DEPENDENT ON UNIVERSITY + CAMPUS)
  Stream<List<String>> departmentsStream() {
    if (university == null || campus == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('departments')
        .where('university', isEqualTo: normalize(university!))
        .where('location', isEqualTo:normalize(campus!))
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => doc['name'].toString())
        .toSet()
        .toList());
  }

  /// 🔹 SEMESTER (FROM QUIZZES)
  Stream<List<int>> semestersStream() {
    Query query = FirebaseFirestore.instance.collection('quizzes');

    if (university != null) {
      query = query.where('university',
          isEqualTo: normalize(university!));
    }
    if (campus != null) {
      query = query.where('location',
          isEqualTo: normalize(campus!));
    }
    if (department != null) {
      query = query.where('department',
          isEqualTo: normalize(department!));
    }

    return query.snapshots().map((snapshot) {
      print("Docs count: ${snapshot.docs.length}"); // DEBUG

      return snapshot.docs
          .map((doc) => doc['semester'])
          .where((e) => e != null)
          .cast<int>()
          .toSet()
          .toList()
        ..sort();
    });
  }
  /// 🔹 SUBJECT (FROM QUIZZES)
  Stream<List<String>> subjectsStream() {
    Query query = FirebaseFirestore.instance.collection('quizzes');

    if (university != null) {
      query = query.where('university', isEqualTo: normalize(university!));
    }
    if (campus != null) {
      query = query.where('location', isEqualTo: normalize(campus!));
    }
    if (department != null) {
      query = query.where('department', isEqualTo: normalize(department!));
    }
    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => doc['subject'].toString())
          .toSet()
          .toList();
    });
  }

  /// 🔍 SEARCH
  void search() {
    if (university == null ||
        campus == null ||
        department == null ||
        semester == null ||
        subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all fields")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizListScreen(
          university: university!,
          department: department!,
          semester: semester!,
          subject: subject!,
          campus: campus!,
        ),
      ),
    );
  }

  String normalize(String text) {
    return text.trim().toLowerCase().split(" ").map((word) {
      return word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1);
    }).join(" ");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 QUIZ INFO CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Quiz Information",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    /// 🔹 UNIVERSITY
                    StreamBuilder<List<String>>(
                      stream: universitiesStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        return DropdownButtonFormField<String>(
                          value: data.contains(university) ? university : null,
                          hint: const Text("Select University"),
                          items: data.map((e) {
                            return DropdownMenuItem(
                                value: e, child: Text(e));
                          }).toList(),
                            onChanged: (v) {
                              setState(() {
                                university = normalize(v!);
                                campus = null;
                                department = null;
                                subject = null;
                                semester = null;
                              });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 CAMPUS
                    StreamBuilder<List<String>>(
                      stream: locationsStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        return DropdownButtonFormField<String>(
                          value: data.contains(campus) ? campus : null,
                          hint: const Text("Select Campus"),
                          items: data.map((e) {
                            return DropdownMenuItem(
                                value: e, child: Text(e));
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              campus = normalize(v!);
                              department = null;
                              subject = null;
                              semester = null;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 DEPARTMENT
                    StreamBuilder<List<String>>(
                      stream: departmentsStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        return DropdownButtonFormField<String>(
                          value: data.contains(department)
                              ? department
                              : null,
                          hint: const Text("Select Department"),
                          items: data.map((e) {
                            return DropdownMenuItem(
                                value: e, child: Text(e));
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              department = normalize(v!);
                              subject = null;
                              semester = null;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 SEMESTER
                    StreamBuilder<List<int>>(
                      stream: semestersStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        return DropdownButtonFormField<int>(
                          value:
                          data.contains(semester) ? semester : null,
                          hint: const Text("Select Semester"),
                          items: data.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text("Semester $e"),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              semester = v;
                              subject = null;
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 SUBJECT
                    StreamBuilder<List<String>>(
                      stream: subjectsStream(),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? [];

                        return DropdownButtonFormField<String>(
                          value: data.contains(subject) ? subject : null,
                          hint: const Text("Select Subject"),
                          items: data.map((e) {
                            return DropdownMenuItem(
                                value: e, child: Text(e));
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              subject = normalize(v!);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔍 SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: search,
                child: const Text("Search Quiz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}