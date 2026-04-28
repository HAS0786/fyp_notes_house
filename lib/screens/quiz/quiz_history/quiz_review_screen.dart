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

          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[

              Text(
              subject ?? "Quiz",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

        const SizedBox(height: 6),

        if (isAI) ...[
    // 🤖 AI MODE → FILE NAME ONLY
    Text(
    department ?? "File",
    style: TextStyle(color: Colors.grey.shade700),
    ),
    ] else ...[
    // 👨‍🏫 TEACHER MODE → FULL INFO

    if (department != null && semester != null)
    Text(
    "$department • Semester $semester",
    style: TextStyle(color: Colors.grey.shade700),
    ),

    if (university != null || campus != null)
    Text(
    "${university ?? ''} ${campus != null ? '• $campus' : ''}",
    style: TextStyle(
    fontSize: 12,
    color: Colors.grey.shade500,
    ),
    ),
    ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, i) {
                final q = questions[i];
                final correct = int.tryParse(q['correct']?.toString() ?? '') ?? 0;

                final selected = selectedAnswers[i.toString()];

                final isCorrect = selected == correct;

                return Column(
                  children: [

                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      color: isCorrect ? Colors.green[50] : Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Weak Areas:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            Wrap(
                              children: weakTopics.entries.map((e) {
                                return Chip(
                                  label: Text("${e.key} (${e.value})"),
                                  backgroundColor: Colors.red.shade100,
                                );
                              }).toList(),
                            ),

                            Text(
                              "Q${i + 1}: ${q['question']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 10),

                            ...List.generate(q['options'].length, (index) {
                              final option = q['options'][index];

                              Color color = Colors.grey.shade200;

                              if (index == correct) {
                                color = Colors.green.shade200;
                              }

                              if (selected == index && selected != correct) {
                                color = Colors.red.shade200;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(option),
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
      )
    );
  }
}