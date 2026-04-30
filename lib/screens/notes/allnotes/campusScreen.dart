import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/department_screen.dart';

class CampusScreen extends StatelessWidget {
  final String universityName;
  final List<String> locations;

  const CampusScreen({
    super.key,
    required this.universityName,
    required this.locations,
  });

  @override
  Widget build(BuildContext context) {
    final campuses = locations;

    return Scaffold(
      appBar: AppBar(
        title: Text("$universityName Campuses"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: campuses.length,
        itemBuilder: (_, i) {
          final campus = campuses[i];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),

              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: Colors.lightBlue,
                  size: 28,
                ),
              ),

              title: Text(
                campus,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Campus",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),

              trailing: const Icon(Icons.arrow_forward_ios, size: 16),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartmentScreen(
                      universityName: universityName,
                      location: campus,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}