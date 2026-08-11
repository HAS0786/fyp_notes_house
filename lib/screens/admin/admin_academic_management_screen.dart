import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAcademicManagementScreen extends StatelessWidget {
  const AdminAcademicManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Academic Management"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          int columns;
          if (width >= 1100) {
            columns = 3;
          } else if (width >= 600) {
            columns = 2;
          } else {
            columns = 1;
          }

          const spacing = 14.0;
          final cardWidth =
              (width - ((columns - 1) * spacing) - 32) / columns;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _actionTile(
                    context,
                    icon: Icons.account_balance,
                    title: "Add University",
                    subtitle: "Add a new university",
                    color: Colors.blue,
                    onTap: () => showAddUniversity(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: _actionTile(
                    context,
                    icon: Icons.domain,
                    title: "Add Department",
                    subtitle: "Add department under university",
                    color: Colors.teal,
                    onTap: () => showAddDepartment(context),
                  ),
                ),

                SizedBox(
                  width: cardWidth,
                  child: _actionTile(
                    context,
                    icon: Icons.menu_book,
                    title: "Add Course",
                    subtitle: "Add course under department",
                    color: Colors.deepPurple,
                    onTap: () => showAddCourse(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD UNIVERSITY
  // ============================================================

  void showAddUniversity(BuildContext context) {
    final universityController = TextEditingController();
    final locationController = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: Colors.lightBlue,
                  ),
                  SizedBox(width: 10),
                  Text("Add University"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: universityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "University Name",
                      hintText: "e.g. University of the Punjab",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Location",
                      hintText: "e.g. Lahore",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                    final name = universityController.text.trim();
                    final location = locationController.text.trim();

                    if (name.isEmpty || location.isEmpty) {
                      _message(
                        context,
                        "Enter university name and location",
                        isError: true,
                      );
                      return;
                    }

                    setState(() => loading = true);

                    try {
                      final id = name.toLowerCase();

                      final ref = FirebaseFirestore.instance
                          .collection('universities')
                          .doc(id);

                      final existing = await ref.get();

                      if (existing.exists) {
                        if (context.mounted) {
                          _message(
                            context,
                            "University already exists",
                            isError: true,
                          );
                        }

                        setState(() => loading = false);
                        return;
                      }

                      await ref.set({
                        'name': name,
                        'location': [location],
                      });

                      if (context.mounted) {
                        Navigator.pop(dialogContext);

                        _message(
                          context,
                          "University added successfully",
                        );
                      }
                    } catch (e) {
                      setState(() => loading = false);

                      if (context.mounted) {
                        _message(
                          context,
                          "Failed to add university",
                          isError: true,
                        );
                      }
                    }
                  },
                  child: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ADD DEPARTMENT
  // ============================================================

  void showAddDepartment(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddDepartmentDialog(),
    );
  }

  // ============================================================
  // ADD COURSE
  // ============================================================

  void showAddCourse(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddCourseDialog(),
    );
  }

  void _message(
      BuildContext context,
      String text, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        content: Text(text),
      ),
    );
  }
}


// ============================================================
// ADD DEPARTMENT DIALOG
// ============================================================

class _AddDepartmentDialog extends StatefulWidget {
  const _AddDepartmentDialog();

  @override
  State<_AddDepartmentDialog> createState() =>
      _AddDepartmentDialogState();
}

class _AddDepartmentDialogState
    extends State<_AddDepartmentDialog> {
  String? selectedUniversity;
  String? selectedLocation;

  final departmentController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.domain,
            color: Colors.teal,
          ),
          SizedBox(width: 10),
          Text("Add Department"),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('universities')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedUniversity,
                    decoration: const InputDecoration(
                      labelText: "University",
                      border: OutlineInputBorder(),
                    ),
                    items: docs.map((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;

                      return DropdownMenuItem<String>(
                        value: data['name']?.toString(),
                        child: Text(
                          data['name']?.toString() ?? '',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUniversity = value;
                        selectedLocation = null;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 14),

              if (selectedUniversity != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('universities')
                      .where(
                    'name',
                    isEqualTo: selectedUniversity,
                  )
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    final data =
                    snapshot.data!.docs.first.data()
                    as Map<String, dynamic>;

                    final locations =
                    List<String>.from(
                      data['location'] ?? [],
                    );

                    if (locations.isEmpty) {
                      return const Text(
                        "No location available for this university.",
                        style: TextStyle(
                          color: Colors.orange,
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                        labelText: "Location",
                        border: OutlineInputBorder(),
                      ),
                      items: locations.map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value;
                        });
                      },
                    );
                  },
                ),

              const SizedBox(height: 14),

              TextField(
                controller: departmentController,
                textCapitalization:
                TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Department Name",
                  hintText: "e.g. Computer Science",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
          loading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: loading ? null : _addDepartment,
          child: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text("Add"),
        ),
      ],
    );
  }

  Future<void> _addDepartment() async {
    if (selectedUniversity == null ||
        selectedLocation == null ||
        departmentController.text.trim().isEmpty) {
      _showMessage(
        "Complete all fields",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final department =
      departmentController.text.trim();

      final id =
      '${selectedUniversity}_${selectedLocation}_$department'
          .toLowerCase();

      final ref = FirebaseFirestore.instance
          .collection('departments')
          .doc(id);

      final existing = await ref.get();

      if (existing.exists) {
        _showMessage(
          "Department already exists",
          isError: true,
        );

        setState(() => loading = false);
        return;
      }

      await ref.set({
        'name': department,
        'university': selectedUniversity,
        'location': selectedLocation,
      });

      if (mounted) {
        Navigator.pop(context);

        _showMessage(
          "Department added successfully",
        );
      }
    } catch (e) {
      setState(() => loading = false);

      _showMessage(
        "Failed to add department",
        isError: true,
      );
    }
  }

  void _showMessage(
      String text, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        isError ? Colors.red : Colors.green,
        content: Text(text),
      ),
    );
  }
}


// ============================================================
// ADD COURSE DIALOG
// ============================================================

class _AddCourseDialog extends StatefulWidget {
  const _AddCourseDialog();

  @override
  State<_AddCourseDialog> createState() =>
      _AddCourseDialogState();
}

class _AddCourseDialogState
    extends State<_AddCourseDialog> {
  String? selectedUniversity;
  String? selectedLocation;
  String? selectedDepartment;

  final courseController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.menu_book,
            color: Colors.deepPurple,
          ),
          SizedBox(width: 10),
          Text("Add Course"),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _universityDropdown(),

              const SizedBox(height: 12),

              if (selectedUniversity != null)
                _locationDropdown(),

              const SizedBox(height: 12),

              if (selectedUniversity != null &&
                  selectedLocation != null)
                _departmentDropdown(),

              const SizedBox(height: 12),

              TextField(
                controller: courseController,
                textCapitalization:
                TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Course Name",
                  hintText: "e.g. Database Systems",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
          loading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: loading ? null : _addCourse,
          child: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text("Add"),
        ),
      ],
    );
  }

  Widget _universityDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('universities')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedUniversity,
          decoration: const InputDecoration(
            labelText: "University",
            border: OutlineInputBorder(),
          ),
          items: docs.map((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: data['name']?.toString(),
              child: Text(
                data['name']?.toString() ?? '',
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedUniversity = value;
              selectedLocation = null;
              selectedDepartment = null;
            });
          },
        );
      },
    );
  }

  Widget _locationDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('universities')
          .where(
        'name',
        isEqualTo: selectedUniversity,
      )
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final data =
        snapshot.data!.docs.first.data()
        as Map<String, dynamic>;

        final locations =
        List<String>.from(
          data['location'] ?? [],
        );

        return DropdownButtonFormField<String>(
          value: selectedLocation,
          decoration: const InputDecoration(
            labelText: "Location",
            border: OutlineInputBorder(),
          ),
          items: locations.map((location) {
            return DropdownMenuItem<String>(
              value: location,
              child: Text(location),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedLocation = value;
              selectedDepartment = null;
            });
          },
        );
      },
    );
  }

  Widget _departmentDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('departments')
          .where(
        'university',
        isEqualTo: selectedUniversity,
      )
          .where(
        'location',
        isEqualTo: selectedLocation,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedDepartment,
          decoration: const InputDecoration(
            labelText: "Department",
            border: OutlineInputBorder(),
          ),
          items: docs.map((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return DropdownMenuItem<String>(
              value: data['name']?.toString(),
              child: Text(
                data['name']?.toString() ?? '',
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedDepartment = value;
            });
          },
        );
      },
    );
  }

  Future<void> _addCourse() async {
    if (selectedUniversity == null ||
        selectedLocation == null ||
        selectedDepartment == null ||
        courseController.text.trim().isEmpty) {
      _showMessage(
        "Complete all fields",
        isError: true,
      );
      return;
    }

    setState(() => loading = true);

    try {
      final course =
      courseController.text.trim();

      final id =
      '${selectedDepartment}_$course'
          .toLowerCase();

      final ref = FirebaseFirestore.instance
          .collection('courses')
          .doc(id);

      final existing = await ref.get();

      if (existing.exists) {
        _showMessage(
          "Course already exists",
          isError: true,
        );

        setState(() => loading = false);
        return;
      }

      await ref.set({
        'name': course,
        'department': selectedDepartment,
      });

      if (mounted) {
        Navigator.pop(context);

        _showMessage(
          "Course added successfully",
        );
      }
    } catch (e) {
      setState(() => loading = false);

      _showMessage(
        "Failed to add course",
        isError: true,
      );
    }
  }

  void _showMessage(
      String text, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        isError ? Colors.red : Colors.green,
        content: Text(text),
      ),
    );
  }
}