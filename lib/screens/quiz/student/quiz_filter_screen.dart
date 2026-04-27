import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_list_screen.dart';

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

  // 🔥 SEMESTER FROM QUIZZES
  Stream<List<int>> getSemesters() {
    Query query = FirebaseFirestore.instance.collection('quizzes');

    if (university != null) {
      query = query.where('university', isEqualTo: university);
    }
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    if (campus != null) {
      query = query.where('location', isEqualTo: campus);
    }

    return query.snapshots().map((snapshot) {
      final values = snapshot.docs
          .map((doc) => doc['semester'])
          .where((e) => e != null)
          .cast<int>()
          .toSet()
          .toList()
        ..sort();
      return values;
    });
  }

  // 🔥 SUBJECT FROM QUIZZES
  Stream<List<String>> getSubjects() {
    Query query = FirebaseFirestore.instance.collection('quizzes');

    if (university != null) {
      query = query.where('university', isEqualTo: university);
    }
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    if (campus != null) {
      query = query.where('location', isEqualTo: campus);
    }

    return query.snapshots().map((snapshot) {
      final values = snapshot.docs
          .map((doc) => doc['subject'].toString())
          .toSet()
          .toList();
      return values;
    });
  }

  // 🔥 CAMPUS FROM QUIZZES
  Stream<List<String>> getCampuses() {
    Query query = FirebaseFirestore.instance.collection('quizzes');

    if (university != null) {
      query = query.where('university', isEqualTo: university);
    }

    return query.snapshots().map((snapshot) {
      final values = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['location'])
          .where((e) => e != null && e.toString().isNotEmpty)
          .map((e) => e.toString())
          .toSet()
          .toList();

      return values;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          // 🔹 UNIVERSITY (FROM COLLECTION)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('universities')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              return DropdownButtonFormField<String>(
                hint: const Text("Select University"),
                value: university,
                items:snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
                  final name = doc['name'].toString();

                  return DropdownMenuItem<String>(
                    value: name,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    university = v;
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

          // 🔹 CAMPUS
          StreamBuilder<List<String>>(
            stream: getCampuses(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              return DropdownButtonFormField<String>(
                hint: const Text("Select Campus"),
                value: campus,
                items: data.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    campus = v;
                    semester = null;
                    subject = null;
                  });
                },
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔹 DEPARTMENT (FROM COLLECTION)
          if (university != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .where('university', isEqualTo: university)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<String>(
                  hint: const Text("Select Department"),
                  value: department,
                  items:snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
                    final name = doc['name'].toString();
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      department = v;
                      semester = null;
                      subject = null;
                    });
                  },
                );
              },
            ),

          const SizedBox(height: 12),

          // 🔹 SEMESTER
          StreamBuilder<List<int>>(
            stream: getSemesters(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              return DropdownButtonFormField<int>(
                hint: const Text("Select Semester"),
                value: semester,
                items: data.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text("Semester $e"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => semester = v),
              );
            },
          ),

          const SizedBox(height: 12),

          // 🔹 SUBJECT
          StreamBuilder<List<String>>(
            stream: getSubjects(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              return DropdownButtonFormField<String>(
                hint: const Text("Select Subject"),
                value: subject,
                items: data.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (v) => setState(() => subject = v),
              );
            },
          ),

          const SizedBox(height: 20),

          // 🔹 SEARCH BUTTON (UNCHANGED)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: search,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Search Quiz"),
            ),
          ),
        ],
      ),
    );
  }
}