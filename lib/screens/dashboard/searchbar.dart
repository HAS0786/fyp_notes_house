import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/resource_list_screen.dart';

void showSearchDialog(BuildContext context) {
  String? selectedUniversity;
  String? selectedDepartment;
  int? selectedSemester;
  String? selectedCategory;

  const categories = [
    'Books',
    'Notes',
    'Past Papers',
    'Assignments',
    'Lab Manuals',
    'Projects',
  ];

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Search Notes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// 🔹 UNIVERSITY
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('universities')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedUniversity,
                        decoration:
                        const InputDecoration(labelText: 'University'),
                        items: snapshot.data!.docs
                            .map<DropdownMenuItem<String>>((doc) {
                          final name = doc['name'] as String;
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedUniversity = value;
                            selectedDepartment = null;
                            selectedSemester = null;
                            selectedCategory = null;
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 DEPARTMENT
                  if (selectedUniversity != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('departments')
                          .where('university', isEqualTo: selectedUniversity)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          decoration:
                          const InputDecoration(labelText: 'Department'),
                          items: snapshot.data!.docs
                              .map<DropdownMenuItem<String>>((doc) {
                            final name = doc['name'] as String;
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDepartment = value;
                              selectedSemester = null;
                              selectedCategory = null;
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  /// 🔹 SEMESTER (FROM NOTES)
                  if (selectedUniversity != null &&
                      selectedDepartment != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notes')
                          .where('university', isEqualTo: selectedUniversity)
                          .where('department', isEqualTo: selectedDepartment)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final semesters = snapshot.data!.docs
                            .map((d) => d['semester'] as int)
                            .toSet()
                            .toList()
                          ..sort();

                        return DropdownButtonFormField<int>(
                          value: selectedSemester,
                          decoration:
                          const InputDecoration(labelText: 'Semester'),
                          items: semesters
                              .map<DropdownMenuItem<int>>((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('Semester $s'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSemester = value;
                              selectedCategory = null;
                            });
                          },
                        );
                      },
                    ),

                  const SizedBox(height: 12),

                  /// 🔹 CATEGORY
                  if (selectedSemester != null)
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration:
                      const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value);
                      },
                    ),
                ],
              ),
            ),

            /// 🔘 ACTIONS
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedUniversity != null &&
                    selectedDepartment != null &&
                    selectedSemester != null &&
                    selectedCategory != null
                    ? () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResourceListScreen(
                        university: selectedUniversity!,
                        department: selectedDepartment!,
                        semester: selectedSemester!,
                        category: selectedCategory!,
                      ),
                    ),
                  );
                }
                    : null,
                child: const Text('Search'),
              ),
            ],
          );
        },
      );
    },
  );
}
