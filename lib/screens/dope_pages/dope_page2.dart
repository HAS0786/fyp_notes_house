import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page_structure.dart';

class Intro_Page2 extends StatelessWidget{
  const Intro_Page2({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
        // color: Colors.blue
        child: Center(
          child: SlidePage("AI Study Buddy", "Ask anything, get instant help",  Icons.smart_toy, Colors.blue),
        ),
      ),
    );
  }
}