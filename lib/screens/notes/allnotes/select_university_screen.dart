
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/campusScreen.dart';
import 'department_screen.dart';

class SelectUniversityScreen extends StatelessWidget {
  const SelectUniversityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: const Text("Select University"),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('universities')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final universities = snapshot.data!.docs;

          if (universities.isEmpty) {
            return const Center(child: Text("No universities found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: universities.length,
            itemBuilder: (_, i) {
              final uni = universities[i];
              final data = uni.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                  // 🔹 Icon container
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.lightBlue,
                      size: 28,
                    ),
                  ),

                  // 🔹 University Name
                  title: Text(
                    data['name'] ?? 'Unknown University',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // 🔹 Location
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data['location'] is List
                          ? (data['location'] as List).join(", ")
                          : (data['location'] ?? 'Location not provided').toString(),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black45,
                  ),

                    onTap: () {
                      final rawLocation = data['location'];

                      final List<String> locations = rawLocation is List
                          ? rawLocation.map((e) => e.toString()).toList()
                          : rawLocation != null
                          ? [rawLocation.toString()]
                          : [];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CampusScreen(
                            universityName: data['name'].toString(),
                            locations: locations, // ✅ ALWAYS LIST
                          ),
                        ),
                      );
                    }
                ),
              );
            },
          );
        },
      ),
    );
  }
}
