import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';

class SmartSearchResultScreen extends StatefulWidget {
  final String query;

  const SmartSearchResultScreen({
    super.key,
    required this.query,
  });

  @override
  State<SmartSearchResultScreen> createState() =>
      _SmartSearchResultScreenState();
}

class _SmartSearchResultScreenState
    extends State<SmartSearchResultScreen> {
  late Future<List<Map<String, dynamic>>> _results;

  @override
  void initState() {
    super.initState();
    _results = _searchNotes();
  }

  Future<List<Map<String, dynamic>>> _searchNotes() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('notes').get();

    final query = widget.query.toLowerCase().trim();

    final words = query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final results = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final title =
      (data['title'] ?? '').toString().toLowerCase();

      final subject =
      (data['subject'] ?? '').toString().toLowerCase();

      final description =
      (data['description'] ?? '').toString().toLowerCase();

      final category =
      (data['category'] ?? '').toString().toLowerCase();

      final university =
      (data['university'] ?? '').toString().toLowerCase();

      final department =
      (data['department'] ?? '').toString().toLowerCase();

      int score = 0;

      // Exact phrase
      if (title.contains(query)) score += 10;
      if (subject.contains(query)) score += 8;
      if (description.contains(query)) score += 5;

      // Individual keywords
      for (final word in words) {
        if (title.contains(word)) score += 5;
        if (subject.contains(word)) score += 4;
        if (description.contains(word)) score += 2;
        if (category.contains(word)) score += 1;
        if (university.contains(word)) score += 1;
        if (department.contains(word)) score += 1;
      }

      if (score > 0) {
        results.add({
          ...data,
          '_searchScore': score,
        });
      }
    }

    // Highest relevance first
    results.sort(
          (a, b) => (b['_searchScore'] as int)
          .compareTo(a['_searchScore'] as int),
    );

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: Text('Search: ${widget.query}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _results,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error searching notes: ${snapshot.error}',
              ),
            );
          }

          final notes = snapshot.data ?? [];

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'No relevant notes found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final data = notes[index];

              final title =
                  data['title'] ?? 'Untitled Resource';

              final teacherName =
                  data['teacherName'] ?? 'Unknown Teacher';

              final subject =
                  data['subject'] ?? '';

              final university =
                  data['university'] ?? '';

              final department =
                  data['department'] ?? '';

              final semester =
                  data['semester'] ?? '';

              final category =
                  data['category'] ?? '';

              final fileUrl =
                  data['fileUrl'] ?? '';

              final isPdf =
              fileUrl.toString().toLowerCase().endsWith('.pdf');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
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
                      isPdf
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color:
                      isPdf ? Colors.red : Colors.blue,
                      size: 26,
                    ),
                  ),

                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Padding(
                    padding:
                    const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject: $subject',
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$university • $department • Semester $semester',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Teacher: $teacherName • $category',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: const Icon(
                    Icons.open_in_new,
                    color: Colors.black45,
                  ),

                  onTap: () {
                    if (fileUrl.toString().isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                          Text('File not available'),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileViewerScreen(
                          title: title,
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