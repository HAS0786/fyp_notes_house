import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:fyp_ui_design/screens/aichatbot/ai_chat_screen.dart';
import 'package:http/http.dart' as http;

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  List sessions = [];

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.get(
      Uri.parse("$baseUrl/chat-sessions"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(res.body);

    setState(() {
      sessions = data;
    });
  }
  Future<void> deleteChat(String id) async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();

    final res = await http.delete(
      Uri.parse("$baseUrl/delete-chat/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      loadSessions();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Chat deleted")));
    } else {
      print(res.body); // 🔥 DEBUG
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Delete failed")));
    }
  }
  Future<void> renameChat(String id) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Chat"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final token =
              await FirebaseAuth.instance.currentUser!.getIdToken();

              final res = await http.put(
                Uri.parse("$baseUrl/rename-chat/$id"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({"title": controller.text}),
              );

              if (res.statusCode == 200) {
                Navigator.pop(context);
                loadSessions();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Chat renamed")),
                );
              } else {
                print(res.body);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Rename failed")),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // 🔥 same as app
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            SizedBox(width: 8),
            Text("Chat History"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined,),
            onPressed: () async {
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AIChatScreen(),
                ),
              );
              loadSessions(); // 🔥 refresh list
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (_, i) {
          final s = sessions[i];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child:ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.lightBlue,
                  child: Icon(Icons.chat, color: Colors.white),
                ),

                title: Text(
                  s["title"] ?? "Chat",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "delete") {
                      deleteChat(s["id"]);
                    } else if (value == "rename") {
                      renameChat(s["id"]);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: "rename", child: Text("Rename")),
                    PopupMenuItem(value: "delete", child: Text("Delete")),
                  ],
                ),

                onTap: () async {
                  await Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIChatScreen(sessionId: s["id"]),
                    ),
                  );

                  loadSessions();
                },
              )
          );
        },
      ),
    );
  }
}