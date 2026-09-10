import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:fyp_ui_design/screens/quiz/result_performance/quiz_result_screen.dart.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final String? quizId;
  final List quizData;
  final bool isEditable;
  final String? subject;
  final String? department;
  final int? semester;
  final String? university;
  final String? campus;

  const QuizScreen({
    super.key,
    this.quizId,
    required this.quizData,
    required this.isEditable,
    this.subject,
    this.department,
    this.semester,
    this.university,
    this.campus,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  int seconds = 0;
  Timer? timer;
  bool timerStarted = false;

  List questions = [];

  Map<int, int> selectedAnswers = {};
  final Map<String, int> weakTopics = {};

  @override
  void initState() {
    super.initState();

    if (widget.quizData.isEmpty && widget.quizId != null) {
      FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get()
          .then((doc) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            questions = data['questions'];
          });
        }
      });
    } else {
      questions = widget.quizData;
    }
    if (widget.quizId == null) {
      // AI quiz
      questions = widget.quizData;
      startTimer();
      timerStarted = true;
    }
  }

  void startTimer() {
    timer?.cancel();
    seconds = 0;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => seconds++);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  //  API (only for teacher quizzes)
  Future<Map<String, dynamic>?> fetchQuizFromAPI() async {
    try {
      final url =Uri.parse("$baseUrl/get-quiz/${widget.quizId}");

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
      // score++;
      // calculateScore();
    } else {
      weakTopics[topic] = (weakTopics[topic] ?? 0) + 1;
    }

    if (currentQuestion < totalQuestions - 1) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => currentQuestion++);
        }
      });
    }
  }
  void calculateScore() {
    score = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];

      int correctIndex = -1;

      // Case 1: normal quiz
      if (q['correct'] != null) {
        correctIndex = int.tryParse(q['correct'].toString()) ?? -1;
      }

      // Case 2: AI quiz
      else if (q['answer'] != null) {
        var ans = q['answer'];

        if (ans is int) {
          correctIndex = ans;
        } else if (ans is String && ans.isNotEmpty) {
          correctIndex = ans.toUpperCase().codeUnitAt(0) - 65;
        }
      }

      if (selectedAnswers[i] == correctIndex) {
        score++;
      }
    }
  }
  Future<void> _saveAttempt(int total) async {
    final user = FirebaseAuth.instance.currentUser!;
    final accuracy = ((score / total) * 100).round();

    await FirebaseFirestore.instance.collection('quiz_attempts').add({
      "userId": user.uid,
      "quizId": widget.quizId ??
          "AI_${DateTime.now().millisecondsSinceEpoch}", //  FIX
      "score": score,
      "total": total,
      "accuracy": accuracy,
      "timeTaken": seconds,
      "weakTopics": weakTopics,
      "questions": questions,
      "selectedAnswers": selectedAnswers.map(
            (key, value) => MapEntry(key.toString(), value),
      ),
      "attemptedAt": Timestamp.now(),

      "subject": widget.subject,
      "department": widget.department,
      "semester": widget.semester,
      "university": widget.university,
      "location": widget.campus,
    });
    if (!mounted) return;
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
  // UI
  Widget buildQuizUI() {
    final Map<String, dynamic> q =
    Map<String, dynamic>.from(questions[currentQuestion]);

    final List options = q['options'] ?? [];
    int correctIndex = int.tryParse(q['correct']?.toString() ?? '') ?? 0;
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
            style: const TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
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
                q['question'] ?? "Question missing",
                style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 26),

          ...options.asMap().entries.map((e) {
            final isSelected = selectedAnswers[currentQuestion] == e.key;

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  selectedAnswers[currentQuestion] = e.key;
                });

                answerQuestion(
                  selectedIndex: e.key,
                  correctIndex: correctIndex,
                  topic: topic,
                  totalQuestions: questions.length,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.lightBlue.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.lightBlue : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected
                          ? Colors.lightBlue
                          : Colors.grey.shade300,
                      child: Text(
                        String.fromCharCode(65 + e.key), // A B C D
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // 🔹 PREVIOUS
              ElevatedButton(
                onPressed: currentQuestion == 0
                    ? null
                    : () {
                  setState(() {
                    currentQuestion--;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                ),
                child: const Text("Previous"),
              ),

              // 🔹 NEXT / SUBMIT
              ElevatedButton(
                onPressed: () async {
                  if (!selectedAnswers.containsKey(currentQuestion)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select an option first")),
                    );
                    return;
                  }

                  if (currentQuestion < questions.length - 1) {
                    setState(() {
                      currentQuestion++;
                    });
                  } else {
                    timer?.cancel();
                    calculateScore();
                    await _saveAttempt(questions.length);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                ),
                child: Text(
                  currentQuestion == questions.length - 1
                      ? "Submit"
                      : "Next",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz'),
      foregroundColor: Colors.white,
        backgroundColor: Colors.lightBlue,
      ),
      body: widget.quizId != null
          ? FutureBuilder<Map<String, dynamic>?>(
        future: fetchQuizFromAPI(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          questions = snapshot.data!['questions'];
          if (!timerStarted) {
            startTimer();
            timerStarted = true;
          }

          return buildQuizUI();
        },
      )
          : buildQuizUI(), //  AI quiz direct
    );
  }
}