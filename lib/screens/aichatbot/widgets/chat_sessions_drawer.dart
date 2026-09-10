import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:fyp_ui_design/screens/aichatbot/ai_chat_screen.dart';
import 'package:http/http.dart' as http;

class ChatSessionsDrawer extends StatefulWidget {
  const ChatSessionsDrawer({super.key});

  @override
  State<ChatSessionsDrawer> createState() => _ChatSessionsDrawerState();
}

class _ChatSessionsDrawerState extends State<ChatSessionsDrawer> {
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
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() {
      sessions = jsonDecode(res.body);
    });
  }

  Future<void> deleteChat(String id) async {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();

    await http.delete(
      Uri.parse("$baseUrl/delete-chat/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    loadSessions();
  }

  Future<void> renameChat(String id) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Rename Chat"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () async {
              final token = await FirebaseAuth.instance.currentUser!
                  .getIdToken();

              await http.put(
                Uri.parse("$baseUrl/rename-chat/$id"),
                headers: {
                  "Authorization": "Bearer $token",
                  "Content-Type": "application/json",
                },
                body: jsonEncode({"title": controller.text}),
              );

              Navigator.pop(context);
              loadSessions();
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.lightBlue,
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Chat History",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          // New Chat button (KEEPING YOUR FEATURE)
          ListTile(
            titleTextStyle: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            hoverColor: Colors.grey,
            leading: Icon(
              Icons.add_circle_outline_outlined,
              color: Colors.lightBlue,
              size: 30,
            ),
            title: Text("Add New Chat"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AIChatScreen()),
              );
            },
          ),

          Divider(),

          //  Chat List (YOUR SAME UI)
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                final s = sessions[i];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.lightBlue,
                    child: Icon(Icons.chat, color: Colors.white),
                  ),
                  title: Text(
                    s["title"] ?? "Chat",
                    style: TextStyle(fontWeight: FontWeight.w600),
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

                  onTap: () {
                    Navigator.pop(context);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIChatScreen(sessionId: s["id"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
