import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/quiz/result_performance/quiz_performance_analysis_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int accuracy;
  final List questions;
  final Map<int, int> selectedAnswers;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.accuracy,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final bool passed = accuracy >= 50;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Quiz Result'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            Icon(
              passed ? Icons.emoji_events_outlined : Icons.error_outline,
              size: 90,
              color: passed ? Colors.amber.shade400 : Colors.orange,
            ),

            const SizedBox(height: 12),

            Text(
              passed ? 'Quiz Completed' : 'Needs Improvement',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              passed
                  ? 'You have successfully completed the quiz.'
                  : 'Review the material and try again.',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 32),

            //  Accuracy
            SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 140,
                          width: 140,
                          child: CircularProgressIndicator(
                            value: accuracy / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            color: passed ? Colors.green : Colors.orange,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$accuracy%',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Accuracy',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$accuracy%',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Accuracy'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            //  Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _infoCard(
                    Icons.star,
                    'Score',
                    '$score / $total',
                    Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  _infoCard(
                    Icons.check_circle,
                    'Status',
                    passed ? 'Passed' : 'Failed',
                    passed ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            //  ANSWER REVIEW SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Answer Review",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ...questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;

                    final List options = q['options'];
                    // int correctIndex = int.tryParse(q['correct']?.toString() ?? '') ?? -1
                    int correctIndex = -1;

                    // Case 1: correct exists
                    if (q['correct'] != null) {
                      correctIndex =
                          int.tryParse(q['correct'].toString()) ?? -1;
                    }
                    // Case 2: AI answer
                    else if (q['answer'] != null) {
                      var ans = q['answer'];

                      if (ans is int) {
                        correctIndex = ans;
                      } else if (ans is String && ans.isNotEmpty) {
                        correctIndex = ans.toUpperCase().codeUnitAt(0) - 65;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${index + 1}: ${q['question']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ...options.asMap().entries.map((opt) {
                              final selectedIndex = selectedAnswers[index];

                              final isCorrect = opt.key == correctIndex;
                              final isSelected = opt.key == selectedIndex;

                              Color bgColor = Colors.transparent;
                              Color borderColor = Colors.grey.shade300;
                              IconData? icon;

                              if (isCorrect) {
                                bgColor = Colors.green.withOpacity(0.2);
                                borderColor = Colors.green;
                                icon = Icons.check;
                              } else if (isSelected) {
                                bgColor = Colors.red.withOpacity(0.2);
                                borderColor = Colors.red;
                                icon = Icons.close;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(opt.value)),
                                    if (icon != null)
                                      Icon(
                                        icon,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Performance Analysis'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: Colors.lightBlue,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuizPerformanceScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
