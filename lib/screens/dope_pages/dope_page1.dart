import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page_structure.dart';

class Intro_Page1 extends StatelessWidget{
  const Intro_Page1({super.key});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Container(
        // color: Colors.blue,
        child: Center(
          child: SlidePage("Welcome to Notes House", "Your all-in-one study companion", Icons.book, Colors.blue),
        ),
      ),
    );
  }
}