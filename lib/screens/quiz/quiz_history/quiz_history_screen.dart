import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'quiz_review_screen.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz History"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_attempts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('attemptedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final attempts = snapshot.data!.docs;

          if (attempts.isEmpty) {
            return const Center(child: Text("No attempts yet"));
          }

          return ListView.builder(
            itemCount: attempts.length,
            itemBuilder: (_, i) {
              final data = attempts[i].data() as Map<String, dynamic>;

              final timestamp = data['attemptedAt'] as Timestamp?;
              final dateTime = timestamp?.toDate();

              String formattedDate = "";
              if (dateTime != null) {
                formattedDate =
                "${dateTime.day}/${dateTime.month}/${dateTime.year} • ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
              }

// 🔹 meta fields (safe read)
              final subject = data['subject'] ?? 'Quiz';
              final dept = data['department'] ?? '';
              final sem = data['semester']?.toString() ?? '';
              final uni = data['university'] ?? '';
              final campus = data['location'] ?? '';

              final acc = data['accuracy'] ?? 0;
              Color accColor =
              acc >= 75 ? Colors.green : acc >= 50 ? Colors.orange : Colors.red;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>QuizReviewScreen(
                        subject: data['subject'],
                        department: data['department'],
                        semester: data['semester'],
                        university: data['university'],
                        campus: data['location'],

                        weakTopics: Map<String, dynamic>.from(data['weakTopics'] ?? {}),
                        questions: List<Map<String, dynamic>>.from(data['questions']),
                        selectedAnswers: Map<String, dynamic>.from(data['selectedAnswers']),
                      )
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 🔹 LEFT ICON (better than timer)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.lightBlue), // 📘 book icon
                      ),

                      const SizedBox(width: 12),

                      // 🔹 TEXT INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 📘 Subject (main title)
                            Text(
                              subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 4),
                            Text(
                              "Quiz Attempt",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),

                            //  Date
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 🔹 RIGHT SIDE (score badge + arrow)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 🎯 Score
                          Text(
                            "${data['score']}/${data['total']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // 📊 Accuracy badge
                          Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$acc%",
                              style: TextStyle(
                                color: accColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
