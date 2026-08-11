import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminCollectionViewScreen extends StatelessWidget {
  final String title;
  final Query query;
  final String type;

  const AdminCollectionViewScreen({
    super.key,
    required this.title,
    required this.query,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Unable to load $title",
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No $title found.",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,

            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),

            itemBuilder: (context, index) {
              final data =
              docs[index].data() as Map<String, dynamic>;

              return _buildDetailTile(
                context,
                data,
                docs[index].id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(
      BuildContext context,
      Map<String, dynamic> data,
      String documentId,
      ) {
    final details = _getDetails(data);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),

            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              _getIcon(),
              color: Colors.lightBlue,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  details['title'] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                ...details.entries
                    .where((entry) => entry.key != 'title')
                    .map(
                      (entry) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: 3),

                    child: Text(
                      "${entry.key}: ${entry.value}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getDetails(
      Map<String, dynamic> data,
      ) {
    switch (type) {
      case "users":
      case "students":
      case "teachers":
        return {
          "title": data['name'] ??
              data['displayName'] ??
              "Unknown User",
          "Email": data['email'] ?? "Not available",
          "Role": data['role'] ?? "Not available",
        };

      case "universities":
        return {
          "title": data['name'] ??
              data['university'] ??
              "Unknown University",
          "Location": data['location'] ?? "Not available",
        };

      case "departments":
        return {
          "title": data['name'] ??
              data['department'] ??
              "Unknown Department",
          "University":
          data['university'] ?? "Not available",
          "Location":
          data['location'] ?? "Not available",
        };

      case "courses":
        return {
          "title": data['name'] ??
              data['course'] ??
              data['subject'] ??
              "Unknown Course",
          "Department":
          data['department'] ?? "Not available",
          "University":
          data['university']  ?? "Not available",
        };

      case "notes":
        return {
          "title": data['title'] ??
              data['name'] ??
              "Untitled Note",
          "Subject":
          data['subject'] ?? "Not available",
          "University":
          data['university']  ?? "Not available",
    "Location": data['location'] ?? "Not available",
          "Department":
          data['department'] ?? "Not available",
          "Semester":
          data['semester']?.toString() ??
              "Not available",
          "Teacher":
          data['teacherName'] ?? "Not available",
        };

      case "quizzes":
        return {
          "title": data['title'] ??
              data['name'] ??
              "Untitled Quiz",
          "Subject":
          data['subject'] ?? "Not available",
          "University":
          data['university']  ?? "Not available",
          "Location": data['location'] ?? "Not available",
          "Department":
          data['department'] ?? "Not available",
          "Semester":
          data['semester']?.toString() ??
              "Not available",
          "Teacher":
          data['teacherName'] ?? "Not available",
        };

      default:
        return {
          "title": data['name'] ??
              data['title'] ??
              "Unknown",
        };
    }
  }

  IconData _getIcon() {
    switch (type) {
      case "users":
      case "students":
      case "teachers":
        return Icons.person;

      case "universities":
        return Icons.account_balance;

      case "departments":
        return Icons.domain;

      case "courses":
        return Icons.menu_book;

      case "notes":
        return Icons.note_alt;

      case "quizzes":
        return Icons.quiz;

      default:
        return Icons.info_outline;
    }
  }
}