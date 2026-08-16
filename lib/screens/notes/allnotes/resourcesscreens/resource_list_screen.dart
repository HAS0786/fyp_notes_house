import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';

import '../../../../firebase/services/note_fetch_service.dart';

class ResourceListScreen extends StatelessWidget {
  final String university;
  final String department;
  final int semester;
  final String category;

  const ResourceListScreen({
    super.key,
    required this.university,
    required this.department,
    required this.semester,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('$category • Semester $semester'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NoteFetchService.getNotes(
          university: university,
          department: department,
          semester: semester,
          category: category,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading resources: ${snapshot.error}",
              ),
            );
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'No resources available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (_, i) {
              final data = notes[i];

              final String teacherName =
                  data['teacherName'] ?? 'Unknown Teacher';

              final String fileUrl =
                  data['fileUrl'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),

                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      fileUrl.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: fileUrl.toLowerCase().endsWith('.pdf')
                          ? Colors.red
                          : Colors.blue,
                      size: 26,
                    ),
                  ),

                  title: Text(
                    data['title'] ?? 'Untitled Resource',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher: $teacherName',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Subject ${data['subject'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: const Icon(
                    Icons.open_in_new,
                    color: Colors.black45,
                    size: 20,
                  ),

                  onTap: () {
                    if (fileUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("File not available"),
                        ),
                      );
                      return;
                    }

                    print("OPENING FILE URL: $fileUrl");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileViewerScreen(
                          title: data['title'] ?? "No Title",
                          fileUrl: fileUrl,
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
