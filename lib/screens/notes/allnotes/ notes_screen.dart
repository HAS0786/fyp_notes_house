import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/resource_list_screen.dart';

class NotesScreen extends StatelessWidget {
  final String university;
  final String department;
  final int semester;

  NotesScreen({
    super.key,
    required this.university,
    required this.department,
    required this.semester,
  });

  final List<Map<String, dynamic>> categories = [
    {'title': 'Books', 'icon': Icons.book, 'color': Colors.blue},
    {'title': 'Notes', 'icon': Icons.note, 'color': Colors.green},
    {'title': 'Past Papers', 'icon': Icons.history, 'color': Colors.orange},
    {'title': 'Assignments', 'icon': Icons.assignment, 'color': Colors.purple},
    {'title': 'Lab Manuals', 'icon': Icons.science, 'color': Colors.teal},
    {'title': 'Projects', 'icon': Icons.folder_open, 'color': Colors.indigo},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('$department • Semester $semester'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (_, i) {
          final cat = categories[i];

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final title = cat['title'] as String;

              if (title == 'Quizzes') {
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResourceListScreen(
                      university: university,
                      department: department,
                      semester: semester,
                      category: title,
                    ),
                  ),
                );
              }
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: cat['color'] as Color,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 12),

                  //  Category Title
                  Text(
                    cat['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
