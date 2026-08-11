import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';


class AdminNotesViewScreen extends StatelessWidget {
  const AdminNotesViewScreen({super.key});

  Future<void> openFile(
      BuildContext context,
      String url,
      String title,
      ) async {
    // Web / Laptop / Desktop
    if (kIsWeb) {
      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      )) {
        throw "Could not open file";
      }

      return;
    }

    // Android / iOS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(
          fileUrl: url, title: title,
        )
      ),
    );
  }
  Widget buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, DocumentSnapshot doc) {
    final note = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note['title'] ?? 'No Title',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          buildInfoRow(
            Icons.book,
            note['subject'] ?? 'Unknown Subject',
          ),

          buildInfoRow(
            Icons.school,
            note['university'] ?? 'Unknown University',
          ),

          buildInfoRow(
            Icons.location_on,
            note['location'] ?? 'Unknown Location',
          ),

          buildInfoRow(
            Icons.menu_book,
            "Semester ${note['semester'] ?? 'N/A'}",
          ),

          buildInfoRow(
            Icons.person,
            "Teacher: ${note['teacherName'] ?? 'Unknown'}",
          ),

          buildInfoRow(
            Icons.info_outline,
            "Status: ${note['status'] ?? 'Unknown'}",
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final url = note['fileUrl']?.toString();
               final name = note['title'];

                if (url != null && url.isNotEmpty) {
                  openFile(context, url,name);
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("View PDF"),
            ),
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
        title: const Text("All Notes"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notes")
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Unable to load notes.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final notes = snapshot.data?.docs ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                "No notes available.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return buildCard(
                context,
                notes[index],
              );
            },
          );
        },
      ),
    );
  }
}