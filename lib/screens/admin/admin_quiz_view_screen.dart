import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/teacherdraft/quiz_viewer_screen.dart';

class AdminQuizViewScreen extends StatelessWidget {
  const AdminQuizViewScreen({super.key});

  Widget buildInfoRow(
      IconData icon,
      String text,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuizCard(
      BuildContext context,
      DocumentSnapshot doc,
      ) {
    final quiz =
    doc.data() as Map<String, dynamic>;

    final questions =
        quiz['questions'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          /// TITLE
          Text(
            quiz['subject'] ??
                'Untitled Quiz',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          buildInfoRow(
            Icons.school,
            quiz['university'] ??
                'Unknown University',
          ),

          buildInfoRow(
            Icons.location_on,
            quiz['location'] ??
                'Unknown Location',
          ),

          buildInfoRow(
            Icons.domain,
            quiz['department'] ??
                'Unknown Department',
          ),

          buildInfoRow(
            Icons.menu_book,
            "Semester ${quiz['semester'] ?? 'N/A'}",
          ),

          buildInfoRow(
            Icons.quiz,
            "${questions.length} Questions",
          ),

          const SizedBox(height: 12),

          /// VIEW QUIZ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.lightBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuizViewerScreen(
                          questions: questions,
                        ),
                  ),
                );
              },

              icon: const Icon(
                Icons.visibility,
              ),

              label: const Text(
                "View Quiz",
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F8FC),

      appBar: AppBar(
        title: const Text(
          "All Quizzes",
        ),
        backgroundColor:
        Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("quizzes")
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Unable to load quizzes.",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          final quizzes =
              snapshot.data?.docs ?? [];

          if (quizzes.isEmpty) {
            return const Center(
              child: Text(
                "No quizzes available.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),

            itemCount: quizzes.length,

            itemBuilder:
                (context, index) {
              return buildQuizCard(
                context,
                quizzes[index],
              );
            },
          );
        },
      ),
    );
  }
}