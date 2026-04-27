import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../dashboard/home_screen.dart';

class AdminApproveTeachersScreen extends StatelessWidget {
  const AdminApproveTeachersScreen({super.key});

  Future<void> approveTeacher(String teacherId) async {
    final url = Uri.parse("http://192.168.100.13:3000/approve-teacher");
    // final url = Uri.parse("http://10.99.151.209:3000/approve-teacher");

    final user = FirebaseAuth.instance.currentUser!;
    final token = await user.getIdToken(); // 🔥 IMPORTANT

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", //
      },
      body: jsonEncode({
        "teacherId": teacherId,
      }),
    );

    print(response.body); // debug
  }
  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(), // teacher-like UI
                ),
              );
            },
            icon: const Icon(Icons.switch_account, color: Colors.white),
            label: const Text(
              "Add Notes/Quizzes",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          adminStatsCards(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pending Teacher Requests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .where("role", isEqualTo: "pending_teacher")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teachers = snapshot.data!.docs;

                if (teachers.isEmpty) {
                  return const Center(
                    child: Text("No pending teachers"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final doc = teachers[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person,color:Colors.lightBlue),
                        title: RichText(text: TextSpan(
                          text: "Email:  ",
                          children: <TextSpan>[
                            TextSpan(
                              text: doc["email"] ?? "No email",
                            )
                          ]

                        )),
                        subtitle: Row(
                          children: [
                            Text("Name: ${doc["name"]}",style: TextStyle(fontWeight: FontWeight.bold),),
                            SizedBox(width: 20,),
                            Text("University: ${doc["university"]}",style: TextStyle(fontWeight: FontWeight.bold),),
                            SizedBox(width: 20,),
                            Text("Teacher-ID: ${doc.id}"),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await approveTeacher(doc.id);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Teacher approved successfully"),
                              ),
                            );
                          },
                          child: const Text("Approve",style: TextStyle(color: Colors.lightBlue),),
                        ),
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

Widget adminStatsCards() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      children: [
        _statCard("Total-Users", FirebaseFirestore.instance.collection('users')),
        SizedBox(width: 10,),
        _statCard("Students", FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student')),
        SizedBox(width: 10,),
        _statCard("Teachers", FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')),
        SizedBox(width: 10,),
        _statCard("Total-Universities", FirebaseFirestore.instance.collection('universities')),
        SizedBox(width: 10,),
        _statCard("Total-Departments", FirebaseFirestore.instance.collection('departments')),
        SizedBox(width: 10,),
        _statCard("Total-Courses", FirebaseFirestore.instance.collection('courses')),
        SizedBox(width: 10,),
        _statCard("Total-Notes", FirebaseFirestore.instance.collection('notes')),
        SizedBox(width: 10,),
        _statCard("Total-Quizzes", FirebaseFirestore.instance.collection('quizzes')),
      ],
    ),
  );
}

Widget _statCard(String title, Query query) {
  return Expanded(
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
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

