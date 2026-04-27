// chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'typewriter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final Map msg;

  const ChatBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg['isUser'];

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.all(6),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.lightBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isUser
            ? Text(msg['text'], style: TextStyle(color: Colors.white))
            : msg['isTyped'] == true
            ? MarkdownBody(data: msg['text'])
            : TypewriterMarkdown(
          text: msg['text'],
          onCompleted: () {
            msg['isTyped'] = true;
          },
        ),
      ),
    );
  }
}