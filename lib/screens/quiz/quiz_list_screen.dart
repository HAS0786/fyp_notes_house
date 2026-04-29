import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_screen.dart';

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

  String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .split(" ")
        .map((word) {
          return word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1);
        })
        .join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Quiz Found'),
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
                  "$university • $campus • $department • Semester $semester",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('university', isEqualTo: normalize(university))
                  .where('department', isEqualTo: normalize(department))
                  .where('subject', isEqualTo: normalize(subject))
                  .where('location', isEqualTo: normalize(campus))
                  .where('semester', isEqualTo: semester)
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

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              quizId: quizzes[i].id, // 🔥 important
                              quizData: questions,
                              isEditable: false,
                              subject: quiz['subject'],
                              department: quiz['department'],
                              semester: quiz['semester'],
                              university: quiz['university'],
                              campus: quiz['location'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 📘 Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.quiz,
                                color: Colors.lightBlue,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // 📄 Text info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz['subject'] ?? 'Quiz',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${questions.length} Questions',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ➡️ Arrow
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
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
