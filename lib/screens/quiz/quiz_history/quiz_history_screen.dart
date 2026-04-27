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

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Score: ${data['score']} / ${data['total']}"),
                  subtitle: Text(
                    "Accuracy: ${data['accuracy']}%\nTime: ${data['timeTaken']}s",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizReviewScreen(
                          questions: List.from(data['questions']),
                          selectedAnswers:
                          Map<int, int>.from(data['selectedAnswers']),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}