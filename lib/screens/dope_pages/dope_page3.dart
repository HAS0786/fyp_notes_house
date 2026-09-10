import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page_structure.dart';

class Intro_Page3 extends StatelessWidget {
  const Intro_Page3({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
        // color: Colors.blue,
        child: Center(
          child: SlidePage(
            "Organize & Track",
            "Notes, quizzes, progress — all in one place",
            Icons.bar_chart,
            Colors.blue,
          ),
        ),
      ),
    );
  }
}
