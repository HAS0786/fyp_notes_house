import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  bool isLoading = false;

  final String baseUrl = "http://192.168.100.13:3000";
  // final String baseUrl = "http://10.99.151.209:3000";

  @override
  void initState() {
    super.initState();

    if (widget.pdfPath != null) {
      pickedFilePath = widget.pdfPath;

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

  Future<void> createSession() async {
    final token = await getToken();

    final res = await http.post(
      Uri.parse("$baseUrl/create-chat-session"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      setState(() {
        messages.add({
          "text": "AI error. Try again.",
          "isUser": false,
          "isTyped": true,
        });
        isLoading = false;
      });
      return;
    }

    final data = jsonDecode(res.body);
    sessionId = data["sessionId"];
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
    if (_controller.text.trim().isEmpty) return;

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
      await createSession();
    }

    if (sessionId != null) {
      request.fields["sessionId"] = sessionId!;
    }

    final filePathToUse = pickedFilePath ?? widget.pdfPath;

    if (filePathToUse != null) {
      print("SENDING FILE: $filePathToUse");

      request.files.add(
        await http.MultipartFile.fromPath("file", filePathToUse),
      );
    }

    final response = await request.send();
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

    if (result != null) {
      pickedFilePath = result.files.single.path;

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


    drawer: Drawer(
    child: ChatSessionsDrawer(),
    ),
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
            onSend: sendMessage,
            onAttach: pickFile, // 🔥 IMPORTANT
          ),
        ],
      ),
    );
  }
}
