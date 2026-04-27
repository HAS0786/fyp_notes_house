import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/quiz/ai_based_quiz/ai_quiz_upload_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_list_screen.dart';
import 'package:fyp_ui_design/screens/quiz/student/quiz_filter_screen.dart';
class StudentScreenSelection extends StatefulWidget {
  final String university;
  final String department;
  final int semester;
  const StudentScreenSelection({
    super.key,
    required this.university,
    required this.department,
    required this.semester,
  });

  @override
  State<StudentScreenSelection> createState() => _StudentScreenSelectionState();
}

class _StudentScreenSelectionState extends State<StudentScreenSelection> {
  int selectedTab = 0; // 0 = Attempt, 1 = AI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Quizzes"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSwitch(),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: [
                const QuizFilterScreen(),
                const AIQuizUploadScreen(isTeacher: false),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwitch() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _tab("Attempt", 0),
          _tab("AI Practice", 1),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedTab == index
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selectedTab == index
                    ? Colors.blue
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}