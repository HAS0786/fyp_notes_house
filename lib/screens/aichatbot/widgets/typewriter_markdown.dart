import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TypewriterMarkdown extends StatefulWidget {
  final String text;
  final int speed;
  final VoidCallback? onCompleted;

  const TypewriterMarkdown({
    super.key,
    required this.text,
    this.onCompleted,
    this.speed = 8,
  });

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String displayedText = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  Future<void> _startTyping() async {
    while (index < widget.text.length) {
      await Future.delayed(Duration(milliseconds: widget.speed));
      if (!mounted) return;

      setState(() {
        displayedText += widget.text[index];
        index++;
      });
    }

    // ONLY ONCE AFTER COMPLETE
    widget.onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: displayedText,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 14, height: 1.4),
        strong: TextStyle(fontWeight: FontWeight.bold),
        listBullet: TextStyle(fontSize: 14),
      ),
    );
  }
}
