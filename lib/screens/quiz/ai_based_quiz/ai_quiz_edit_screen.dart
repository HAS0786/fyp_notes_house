import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIQuizEditScreen extends StatefulWidget {
  final List quiz;
  final String? university;
  final String? department;
  final String? semester;
  final String? subject;

  const AIQuizEditScreen({
    super.key,
    required this.quiz,
    this.university,
    this.department,
    this.semester,
    this.subject,
  });

  @override
  State<AIQuizEditScreen> createState() => _AIQuizEditScreenState();
}

class _AIQuizEditScreenState extends State<AIQuizEditScreen> {
  late List quiz;

  @override
  void initState() {
    super.initState();
    quiz = List.from(widget.quiz);
  }

  void updateQuestion(int index, String value) {
    quiz[index]["question"] = value;
  }

  void updateOption(int qIndex, int oIndex, String value) {
    quiz[qIndex]["options"][oIndex] = value;
  }

  Future<void> _saveQuiz() async {
    await FirebaseFirestore.instance.collection('quizzes').add({
      "university": widget.university,
      "department": widget.department,
      "semester": int.tryParse(widget.semester ?? "1") ?? 1,
      "subject": widget.subject,
      "questions": quiz,
      "isPublic": true,
      "createdAt": Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("AI Quiz Saved")));

    Navigator.pop(context, quiz);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit AI Quiz"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            // onPressed: () => AIQuizEditScreen.submit(),
            onPressed: () async {
              await _saveQuiz();
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: quiz.length,
        itemBuilder: (_, i) {
          final q = quiz[i];
          int correctIndex = 0;

// CASE 1: correct is already index
          if (q["correct"] is int) {
            correctIndex = q["correct"];
          }

// CASE 2: correct is letter (A, B, C, D)
          else if (q["correct"] is String) {
            final letter = q["correct"].toString().trim().toUpperCase();
            correctIndex = letter.codeUnitAt(0) - 65; // A=0, B=1
          }

// CASE 3: answer is index
          else if (q["answer"] is int) {
            correctIndex = q["answer"];
          }

// CASE 4: answer is letter
          else if (q["answer"] is String &&
              q["answer"].toString().length == 1) {
            final letter = q["answer"].toString().toUpperCase();
            correctIndex = letter.codeUnitAt(0) - 65;
          }

// CASE 5: answer is text
          else if (q["answer"] != null && q["options"] != null) {
            final answer = q["answer"].toString().trim().toLowerCase();

            correctIndex = q["options"].indexWhere((opt) =>
            opt.toString().trim().toLowerCase() == answer);

            if (correctIndex == -1) {
              correctIndex = q["options"].indexWhere((opt) =>
                  opt.toString().toLowerCase().contains(answer));
            }
          }

// FINAL SAFETY
          if (correctIndex < 0 || correctIndex >= q["options"].length) {
            correctIndex = 0;
          }

// SYNC BACK
          q["correct"] = correctIndex;

          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Question ${i + 1}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),

                      TextField(
                        controller: TextEditingController(text: q["question"]),
                        onChanged: (v) => updateQuestion(i, v),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ...List.generate(q["options"].length, (j) {

                    // ⭐ check correct option
                    final isCorrect = j == (q["correct"] ?? 0);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.grey.shade100,
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.grey.shade300,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor:
                            isCorrect ? Colors.green : Colors.grey.shade400,
                            child: Text(
                              String.fromCharCode(65 + j), // A B C D
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller:
                              TextEditingController(text: q["options"][j]),
                              onChanged: (v) => updateOption(i, j, v),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: correctIndex,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: List.generate(q["options"].length, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text("Correct Answer: Option ${index + 1}"),
                        );
                      }),
                      onChanged: (val) {
                        setState(() {
                          quiz[i]["correct"] = val;
                        });
                      },
                    ),
                  ),
                  TextField(
                    controller: TextEditingController(
                      text: q["explanation"] ?? "",
                    ),
                    onChanged: (v) {
                      quiz[i]["explanation"] = v;
                    },
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Explanation",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
