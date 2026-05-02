import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/quiz/ai_based_quiz/ai_quiz_upload_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_upload/create_mcq_screen.dart';


class TeacherScreenSelection extends StatefulWidget {
  const TeacherScreenSelection({super.key});

  @override
  State<TeacherScreenSelection> createState() => _TeacherScreenSelectionState();
}

class _TeacherScreenSelectionState extends State<TeacherScreenSelection> {
  int selectedTab = 0; // 0 = Self, 1 = AI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Quiz"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [

          TextButton(
            onPressed: () {
              if (selectedTab == 0) {
                CreateMCQScreen.submit();
              }
            },
            child: Text(
              selectedTab == 0 ? "Submit": "",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSwitch(),
          Expanded(
            child: IndexedStack(
              index: selectedTab,
              children: const [
                CreateMCQScreen(),
                AIQuizUploadScreen(isTeacher: true),
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
          _tab("Self", 0),
          _tab("AI", 1),
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
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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