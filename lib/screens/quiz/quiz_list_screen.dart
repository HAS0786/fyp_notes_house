import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatelessWidget {
  final String university;
  final String department;
  final int semester;
  final String subject;
  final String campus;

  const QuizListScreen({
    super.key,
    required this.university,
    required this.department,
    required this.campus,
    required this.semester,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('$department • Semester $semester'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Browse Quizzes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "$department • Semester $semester",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('university', isEqualTo: university)
                  .where('department', isEqualTo: department)
                  .where('semester', isEqualTo: semester)
                  .where('subject', isEqualTo: subject)
                  .where('location', isEqualTo: campus)
                  .where('isPublic', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("Something went wrong"));
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No quizzes available'));
                }

                final quizzes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: quizzes.length,
                  itemBuilder: (_, i) {
                    final quiz =
                        quizzes[i].data() as Map<String, dynamic>? ?? {};
                    final questions =
                        (quiz['questions'] ?? []) as List<dynamic>;

                    return ListTile(
                      title: Text(quiz['subject'] ?? 'Quiz'),
                      subtitle: Text('${questions.length} Questions'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
