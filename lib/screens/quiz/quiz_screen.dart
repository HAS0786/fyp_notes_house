import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_ui_design/screens/quiz/result_performance/quiz_result_screen.dart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final String? quizId;
  final List quizData;
  final bool isEditable;

  const QuizScreen({
    super.key,
    this.quizId,
    required this.quizData,
    required this.isEditable,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int seconds = 0;
  Timer? timer;

  List questions = [];

  Map<int, int> selectedAnswers = {};
  final Map<String, int> weakTopics = {};

  @override
  void initState() {
    super.initState();

    // 🔥 IMPORTANT FIX
    if (widget.quizId == null) {
      // AI quiz
      questions = widget.quizData;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // 🔥 API (only for teacher quizzes)
  Future<Map<String, dynamic>?> fetchQuizFromAPI() async {
    try {
      final url = Uri.parse(
        // "http://192.168.100.13:3000/get-quiz/${widget.quizId}",
        "http://10.99.151.209:3000/get-quiz/${widget.quizId}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void answerQuestion({
    required int selectedIndex,
    required int correctIndex,
    required String topic,
    required int totalQuestions,
  }) async {
    selectedAnswers[currentQuestion] = selectedIndex;

    if (selectedIndex == correctIndex) {
      score++;
    } else {
      weakTopics[topic] = (weakTopics[topic] ?? 0) + 1;
    }

    if (currentQuestion < totalQuestions - 1) {
      setState(() => currentQuestion++);
    } else {
      timer?.cancel();
      await _saveAttempt(totalQuestions);
    }
  }

  Future<void> _saveAttempt(int total) async {
    final user = FirebaseAuth.instance.currentUser!;
    final accuracy = ((score / total) * 100).round();

    await FirebaseFirestore.instance.collection('quiz_attempts').add({
      "userId": user.uid,
      "quizId": widget.quizId ??
          "AI_${DateTime.now().millisecondsSinceEpoch}", // 🔥 FIX
      "score": score,
      "total": total,
      "accuracy": accuracy,
      "timeTaken": seconds,
      "weakTopics": weakTopics,
      "questions": questions,
      "selectedAnswers": selectedAnswers,
      "attemptedAt": Timestamp.now(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          score: score,
          total: total,
          accuracy: accuracy,
          questions: questions,
          selectedAnswers: selectedAnswers,
        ),
      ),
    );
  }

  // 🔥 COMMON UI (reuse)
  Widget buildQuizUI() {
    final Map<String, dynamic> q =
    Map<String, dynamic>.from(questions[currentQuestion]);

    final List options = q['options'];
    final int correctIndex = int.parse(q['correct'].toString());
    final String topic = (q['topic'] ?? 'General').toString();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Progress + Timer
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (currentQuestion + 1) / questions.length,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.lightBlue,
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.timer, size: 18),
                  const SizedBox(width: 4),
                  Text('${seconds}s'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            'Question ${currentQuestion + 1} of ${questions.length}',
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                q['question'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(height: 26),

          ...options.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: OutlinedButton(
                onPressed: () {
                  answerQuestion(
                    selectedIndex: e.key,
                    correctIndex: correctIndex,
                    topic: topic,
                    totalQuestions: questions.length,
                  );
                },
                child: Text(e.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: widget.quizId != null
          ? FutureBuilder<Map<String, dynamic>?>(
        future: fetchQuizFromAPI(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          questions = snapshot.data!['questions'];

          return buildQuizUI();
        },
      )
          : buildQuizUI(), // 🔥 AI quiz direct
    );
  }
}