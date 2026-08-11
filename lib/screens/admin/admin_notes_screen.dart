import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class AdminNotesScreen extends StatelessWidget {
  const AdminNotesScreen({super.key});

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<void> approveNote(String noteId) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("$baseUrl/approve-note"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"noteId": noteId}),
    );
  }

  Future<void> openFile(BuildContext context, String url, String title) async {
    // 🌐 Web / Laptop
    if (kIsWeb) {
      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw "Could not open file";
      }

      return;
    }

    // 📱 Android / iOS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(fileUrl: url, title: title),
      ),
    );
  }

  Future<void> rejectNote(String noteId, String reason) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("$baseUrl/reject-note"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"noteId": noteId, "reason": reason}),
    );
  }

  void showRejectDialog(BuildContext context, String noteId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Note"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter rejection reason"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await rejectNote(noteId, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, doc) {
    final note = doc.data();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            note['title'] ?? "No Title",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          buildInfoRow(Icons.book, note['subject']),
          buildInfoRow(Icons.school, note['university']),
          buildInfoRow(Icons.location_on, note['location']),
          buildInfoRow(Icons.menu_book, "Semester ${note['semester']}"),
          buildInfoRow(Icons.person, "Respected ${note['teacherName']}"),

          const SizedBox(height: 12),

          /// ACTION BUTTONS
          /// ACTION BUTTONS
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => approveNote(doc.id),
                      child: const Text("Approve"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => showRejectDialog(context, doc.id),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: ()  {
                final furl = note['fileUrl'];
                final name = note['title'];
                    openFile(context, furl,name);},
                  icon: const Icon(Icons.visibility),
                  label: const Text("View File / Notes"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Notes Approval"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notes")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs;

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                "No pending notes",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (_, i) => buildCard(context, notes[i]),
          );
        },
      ),
    );
  }
}
