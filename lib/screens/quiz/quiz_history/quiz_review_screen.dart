import 'package:flutter/material.dart';

class QuizReviewScreen extends StatelessWidget {
  final List questions;
  final Map<int, int> selectedAnswers;

  const QuizReviewScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Answers"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (_, i) {
          final q = Map<String, dynamic>.from(questions[i]);
          final options = q['options'];

          final int correctIndex =
          int.parse(q['correct'].toString());

          final int? selectedIndex = selectedAnswers[i];

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    "Q${i + 1}: ${q['question']}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Options
                  ...options.asMap().entries.map((e) {
                    final isCorrect = e.key == correctIndex;
                    final isSelected = e.key == selectedIndex;

                    Color color = Colors.grey.shade200;

                    if (isCorrect) {
                      color = Colors.green.shade200;
                    } else if (isSelected && !isCorrect) {
                      color = Colors.red.shade200;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.value),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}