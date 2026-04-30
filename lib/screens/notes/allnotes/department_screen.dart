import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'semester_screen.dart';

class DepartmentScreen extends StatelessWidget {
  final String universityName;
  final String location;
  const DepartmentScreen({
    super.key,
    required this.universityName,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: Text(universityName),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('departments')
            .where('university', isEqualTo: universityName)
            .where('location', isEqualTo: location)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments = snapshot.data!.docs;

          if (departments.isEmpty) {
            return const Center(child: Text('No departments found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: departments.length,
            itemBuilder: (_, i) {
              final dept = departments[i];
              final data = dept.data() as Map<String, dynamic>;

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
                      Icons.import_contacts_rounded,
                      color: Colors.lightBlue,
                      size: 26,
                    ),
                  ),

                  // 🔹 Department name
                  title: Text(
                    data['name'] ?? 'Unnamed Department',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black45,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SemesterScreen(
                          university: universityName,
                          department: data['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
