import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_ui_design/screens/admin/admin_notes_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_teacher_approval_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// 📊 STATS (TOP)
            adminStatsCards(),

            const SizedBox(height: 20),

            /// 🔹 SECTION TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Admin Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔹 ACTION CARDS (FIXED WIDTH STYLE)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  dashboardCardSmall(
                    icon: Icons.people,
                    title: "Teacher Requests",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminTeacherScreen()),
                      );
                    },
                  ),

                  dashboardCardSmall(
                    icon: Icons.note_alt,
                    title: "Notes Approval",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminNotesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget dashboardCardSmall({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: 180, // ⭐ FIXED SIZE (IMPORTANT)
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

Widget adminStatsCards() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      children: [
        _statCard(
          "Total-Users",
          FirebaseFirestore.instance.collection('users'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Students",
          FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Teachers",
          FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'teacher'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Total-Universities",
          FirebaseFirestore.instance.collection('universities'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Total-Departments",
          FirebaseFirestore.instance.collection('departments'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Total-Courses",
          FirebaseFirestore.instance.collection('courses'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Total-Notes",
          FirebaseFirestore.instance.collection('notes'),
        ),
        SizedBox(width: 10),
        _statCard(
          "Total-Quizzes",
          FirebaseFirestore.instance.collection('quizzes'),
        ),
      ],
    ),
  );
}

Widget _statCard(String title, Query query) {
  return SizedBox(
    width: 150,
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("0");
                return Text(
                  snapshot.data!.docs.length.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
