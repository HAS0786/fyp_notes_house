import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/dashboard/searching_notes/smart_search_result_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/resource_list_screen.dart';

void showSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) {
      return const _SearchDialog();
    },
  );
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog();

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  int selectedTab = 0; // 0 = Normal, 1 = Smart

  String? selectedUniversity;
  String? selectedDepartment;
  int? selectedSemester;
  String? selectedCategory;

  final TextEditingController _searchController = TextEditingController();

  _SearchDialogState();

  final categories = const [
    'Books',
    'Notes',
    'Past Papers',
    'Assignments',
    'Lab Manuals',
    'Projects',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF9F4FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.lightBlue,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Search Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Find your study material',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.black54,
                    tooltip: 'Close',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // SEARCH TYPE SWITCH
              _buildSwitch(),

              const SizedBox(height: 18),

              // CONTENT
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: selectedTab == 0
                      ? _buildNormalSearch()
                      : _buildSmartSearch(),
                ),
              ),

              const SizedBox(height: 16),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black54,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedTab == 0
                          ? selectedUniversity != null &&
                                    selectedDepartment != null &&
                                    selectedSemester != null &&
                                    selectedCategory != null
                                ? _normalSearch
                                : null
                          : _searchController.text.trim().isNotEmpty
                          ? _smartSearch
                          : null,
                      icon: Icon(
                        selectedTab == 0
                            ? Icons.filter_alt_rounded
                            : Icons.search_rounded,
                        size: 18,
                      ),
                      label: Text(selectedTab == 0 ? 'Find Notes' : 'Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // =========================
  // SWITCH
  // =========================

  Widget _buildSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(children: [_tab('Normal Search', 0), _tab('Smart Search', 1)]),
    );
  }

  Widget _tab(String text, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedTab == index
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selectedTab == index ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // NORMAL SEARCH
  // =========================

  Widget _buildNormalSearch() {
    return Column(
      children: [
        // UNIVERSITY
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
              decoration: const InputDecoration(labelText: 'University'),
              items: snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
                final name = doc['name'] as String;

                return DropdownMenuItem(value: name, child: Text(name));
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

        // DEPARTMENT
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
                decoration: const InputDecoration(labelText: 'Department'),
                items: snapshot.data!.docs.map<DropdownMenuItem<String>>((doc) {
                  final name = doc['name'] as String;

                  return DropdownMenuItem(value: name, child: Text(name));
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

        // SEMESTER
        if (selectedUniversity != null && selectedDepartment != null)
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

              final semesters =
                  snapshot.data!.docs
                      .map((d) => d['semester'] as int)
                      .toSet()
                      .toList()
                    ..sort();

              return DropdownButtonFormField<int>(
                value: selectedSemester,
                decoration: const InputDecoration(labelText: 'Semester'),
                items: semesters.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem(value: s, child: Text('Semester $s'));
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

        // CATEGORY
        if (selectedSemester != null)
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories.map<DropdownMenuItem<String>>((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
          ),
      ],
    );
  }

  // =========================
  // SMART SEARCH
  // =========================

  Widget _buildSmartSearch() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            labelText: 'Search notes',
            hintText: 'e.g. DBMS normalization',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Search across all universities, departments and semesters.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // =========================
  // NORMAL SEARCH ACTION
  // =========================

  void _normalSearch() {
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

  // =========================
  // SMART SEARCH ACTION
  // =========================

  void _smartSearch() {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SmartSearchResultScreen(query: query)),
    );
  }
}
