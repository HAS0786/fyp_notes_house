import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminTeacherScreen extends StatelessWidget {
  const AdminTeacherScreen({super.key});

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<void> approveTeacher(String teacherId) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("http://192.168.100.13:3000/approve-teacher"),
      // Uri.parse("http://10.99.151.209:3000/approve-teacher"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"teacherId": teacherId}),
    );
  }

  Future<void> rejectTeacher(String teacherId,String reason) async {
    final token = await _getToken();

    await http.post(
      Uri.parse("http://192.168.100.13:3000/reject-teacher"),
      // Uri.parse("http://10.99.151.209:3000/reject-teacher"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "teacherId": teacherId,
        "reason": reason, // 🔥 IMPORTANT
      }),
    );
  }
  void showRejectDialog(BuildContext context, String teacherId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Teacher"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter rejection reason",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();

              Navigator.pop(context);

              await rejectTeacher(teacherId, reason);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Teacher rejected")),
              );
            },
            child: const Text("Submit"),
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
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, doc) {
    final teacher = doc.data();

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

          /// NAME
          Text(
            teacher['name'] ?? "No Name",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          buildInfoRow(Icons.email, teacher['email'] ?? ""),
          buildInfoRow(Icons.school, teacher['university'] ?? ""),
          buildInfoRow(Icons.work, teacher['department'] ?? ""),

          const SizedBox(height: 12),

          /// ACTION BUTTONS
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                    foregroundColor: Colors.white
                ),
                onPressed: () => approveTeacher(doc.id),
                child: const Text("Approve"),
              ),

              const SizedBox(width: 10),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                    foregroundColor: Colors.white
                ),
                onPressed: () => showRejectDialog(context, doc.id),
                child: const Text("Reject"),
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
        title: const Text("Teacher Requests"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("role", isEqualTo: "teacher")
            .where("status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final teachers = snapshot.data!.docs;

          if (teachers.isEmpty) {
            return const Center(
              child: Text(
                "No pending teacher requests",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (_, i) => buildCard(context, teachers[i]),
          );
        },
      ),
    );
  }
}