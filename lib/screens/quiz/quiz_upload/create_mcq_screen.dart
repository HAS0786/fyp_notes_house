import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/firebase/services/quiz_service.dart';
import 'package:fyp_ui_design/widgets/academic_info_form.dart';

class CreateMCQScreen extends StatefulWidget {
  static _CreateMCQScreenState? _instance;
  const CreateMCQScreen({super.key});

  @override
  State<CreateMCQScreen> createState() => _CreateMCQScreenState();

  static void submit() {
    _instance?._submitQuiz();
  }
}


class _CreateMCQScreenState extends State<CreateMCQScreen> {
  AcademicSelection academic = AcademicSelection();
  String? correctAnswerIndex;
  bool isLoading = false;
  final questionCtrl = TextEditingController();
  final option1Ctrl = TextEditingController();
  final option2Ctrl = TextEditingController();
  final option3Ctrl = TextEditingController();
  final option4Ctrl = TextEditingController();



  final List<Map<String, dynamic>> allQuestions = [];

  @override
  void initState() {
    super.initState();
    CreateMCQScreen._instance = this;
  }

  // ---------------- LOGIC ----------------

  void _addQuestion() {
    if (questionCtrl.text.isEmpty ||
        option1Ctrl.text.isEmpty ||
        option2Ctrl.text.isEmpty ||
        option3Ctrl.text.isEmpty ||
        option4Ctrl.text.isEmpty ||
        correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete question & options')),
      );
      return;
    }

    allQuestions.add({
      'question': questionCtrl.text.trim(),
      'options': [
        option1Ctrl.text.trim(),
        option2Ctrl.text.trim(),
        option3Ctrl.text.trim(),
        option4Ctrl.text.trim(),
      ],
      'correct': correctAnswerIndex,
    });

    questionCtrl.clear();
    option1Ctrl.clear();
    option2Ctrl.clear();
    option3Ctrl.clear();
    option4Ctrl.clear();
    correctAnswerIndex = null;

    setState(() {});
  }

  Future<void> _submitQuiz() async {
    if (allQuestions.isEmpty ||
        academic.university == null ||
        academic.department == null ||
        academic.semester == null ||
        academic.subject == null ||
        academic.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await QuizService.createQuiz(
      university: academic.university!,
      location: academic.location!,
      department: academic.department!,
      semester: academic.semester!,
      subject: academic.subject!,
      questions: allQuestions,
      type: "manual",
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Quiz created successfully"),
        ),
      );
      Navigator.pop(context);
    }
  }
  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[ Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ================= BASIC INFO =================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Academic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      AcademicInfoForm(
                        value: academic,
                        onChanged: (val) {
                          setState(() {
                            academic = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= QUESTION =================
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Add Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      TextField(
                        controller: questionCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Question'),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: option1Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option A',
                          prefixIcon: Radio<String>(
                            value: '0',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option2Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option B',
                          prefixIcon: Radio<String>(
                            value: '1',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option3Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option C',
                          prefixIcon: Radio<String>(
                            value: '2',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option4Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option D',
                          prefixIcon: Radio<String>(
                            value: '3',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _addQuestion,
                        child: const Text('Add Question'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${allQuestions.length} question(s) added',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Uploading Quiz...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
    ]
    );
  }}
