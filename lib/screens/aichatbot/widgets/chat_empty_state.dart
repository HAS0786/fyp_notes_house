import 'package:flutter/material.dart';

class ChatEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 60, color: Colors.lightBlue),
          SizedBox(height: 10),
          Text("AI Assistant", style: TextStyle(fontSize: 18)),
          Text("Ask anything or attach file",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}