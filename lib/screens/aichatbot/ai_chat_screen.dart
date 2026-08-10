import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:fyp_ui_design/screens/aichatbot/widgets/chat_loading_avatar.dart';
import 'package:fyp_ui_design/screens/aichatbot/widgets/chat_empty_state.dart';
import 'package:fyp_ui_design/screens/aichatbot/widgets/chat_input_bar.dart';
import 'package:fyp_ui_design/screens/aichatbot/widgets/chat_bubble.dart';
import 'package:fyp_ui_design/screens/aichatbot/widgets/chat_sessions_drawer.dart';
import 'package:http/http.dart' as http;

class AIChatScreen extends StatefulWidget {
  final String? pdfPath;
  final String? sessionId;
  final String? pdfTitle;

  const AIChatScreen({super.key, this.pdfPath, this.sessionId, this.pdfTitle});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];

  String? pickedFilePath;
  String? sessionId;
  String? activeFilePath;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.pdfPath != null) {
      activeFilePath = widget.pdfPath; // 🔥 set here (NOT pickedFilePath)
      messages.add({
        "text": "📎 ${widget.pdfTitle ?? "PDF attached"}",
        "isUser": true,
        "isTyped": true,
      });
    }

    if (widget.sessionId != null) {
      sessionId = widget.sessionId;
      loadChatHistory();
    } else {
      createSession();
    }
  }

  Future<String?> getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }
  Future<String?> createSession() async {
    final token = await getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/create-chat-session"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    return data["sessionId"];
  }

  Future<void> loadChatHistory() async {
    final token = await getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/chat-history/$sessionId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      setState(() {
        messages.add({
          "text": "AI error. Please try again.",
          "isUser": false,
          "isTyped": true,
        });
        isLoading = false;
      });
      return;
    }

    final data = jsonDecode(res.body);

    setState(() {
      messages = [];
      for (var m in data) {
        messages.add({"text": m["question"], "isUser": true, "isTyped": true});
        messages.add({"text": m["answer"], "isUser": false, "isTyped": true});
      }
    });
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty || isLoading) return;

    final question = _controller.text.trim();
    _controller.clear();

    setState(() {
      messages.add({"text": question, "isUser": true});
      isLoading = true;
    });

    final token = await getToken();

    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/ask-ai"));

    request.headers["Authorization"] = "Bearer $token";
    request.fields["question"] = question;

    if (sessionId == null) {
      sessionId = await createSession();
    }

    if (sessionId == null) {
      setState(() {
        messages.add({
          "text": "Session error. Try again.",
          "isUser": false,
          "isTyped": true,
        });
        isLoading = false;
      });
      return;
    }

    request.fields["sessionId"] = sessionId!;
    if (activeFilePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath("file", activeFilePath!),
      );
      activeFilePath = null; //  send only once
    }

    final response = await request.send().timeout(
      const Duration(minutes: 2),
    );
    final res = await http.Response.fromStream(response);
    if (res.statusCode != 200) {
      setState(() {
        messages.add({
          "text": "AI error. Please try again.",
          "isUser": false,
          "isTyped": true,
        });
        isLoading = false;
      });
      return;
    }

    final data = jsonDecode(res.body);

    setState(() {
      messages.add({"text": data["answer"], "isUser": false, "isTyped": false});

      isLoading = false;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();

      if (size > 10 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size must be 10 MB or less.'),
          ),
        );
        return;
      }

      activeFilePath = file.path;

      setState(() {
        messages.add({
          "text": "📎 ${result.files.single.name} attached",
          "isUser": true,
          "isTyped": true,
        });
      });
    }
  }

  Future<List> loadDrawerSessions() async {
    final token = await getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/chat-sessions"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: Text("AI Assistant"),
      ),

      drawer: Drawer(child: ChatSessionsDrawer()),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? ChatEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (_, i) => ChatBubble(msg: messages[i]),
                  ),
          ),

          if (isLoading) const AIAvatarLoader(),

          ChatInputBar(
            controller: _controller,
            onSend: isLoading ? null : () => sendMessage(),
            onAttach: pickFile, //  IMPORTANT
          ),
        ],
      ),
    );
  }
}
