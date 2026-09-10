import 'package:flutter/material.dart';

class AIAvatarLoader extends StatefulWidget {
  const AIAvatarLoader({super.key});

  @override
  State<AIAvatarLoader> createState() => _AIAvatarLoaderState();
}

class _AIAvatarLoaderState extends State<AIAvatarLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose(); // THIS FIXES ERROR
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.1).animate(_controller),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          const Text("AI is thinking...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
