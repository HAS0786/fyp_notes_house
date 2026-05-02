import 'package:flutter/material.dart';

class QuizReviewScreen extends StatelessWidget {
  final String? subject;
  final String? department;
  final int? semester;
  final String? university;
  final String? campus;
  final List questions;
  final Map<String, dynamic> selectedAnswers;
  final Map<String, dynamic> weakTopics;

  const QuizReviewScreen({
    super.key,
    this.subject,
    this.department,
    this.semester,
    this.university,
    this.campus,
    required this.questions,
    required this.selectedAnswers,
    required this.weakTopics,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAI = subject == "AI Generated Quiz";
    return Scaffold(
      appBar: AppBar(
        title: const Text("Review Answers"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (weakTopics.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weakTopics.entries.map((e) {
                  return Chip(
                    label: Text("${e.key} (${e.value})"),
                    backgroundColor: Colors.orange.shade100,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, i) {
                final q = questions[i];
                final correct =
                    int.tryParse(q['correct']?.toString() ?? '') ?? 0;

                final selected = selectedAnswers[i.toString()];

                final isCorrect = selected == correct;

                return Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Question ${i + 1}",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              q['question'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 10),

                            ...List.generate(q['options'].length, (index) {
                              final option = q['options'][index];

                              bool isCorrectOption = index == correct;
                              bool isSelected = selected == index;

                              Color bg = Colors.grey.shade100;
                              Color border = Colors.transparent;

                              if (isCorrectOption) {
                                bg = Colors.green.shade50;
                                border = Colors.green;
                              }

                              if (isSelected && !isCorrectOption) {
                                bg = Colors.red.shade50;
                                border = Colors.red;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey.shade300,
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(option)),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),

                            Text(
                              isCorrect ? "Correct ✅" : "Wrong ❌",
                              style: TextStyle(
                                color: isCorrect ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
