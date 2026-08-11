import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/admin/admin_academic_management_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_collection_view_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_notes_view_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_notes_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_quiz_view_screen.dart';
import 'package:fyp_ui_design/screens/admin/admin_teacher_approval_screen.dart';
import 'package:fyp_ui_design/screens/notes/uploadnotes/upload_notes_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_upload/create_mcq_screen.dart';
import 'package:fyp_ui_design/screens/quiz/teacher/screen_selection.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                _buildWelcomeHeader(),

                const SizedBox(height: 24),

                /// OVERVIEW
                const Text(
                  "Overview",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _buildStatsGrid(context),

                const SizedBox(height: 30),

                /// QUICK ACTIONS
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _buildQuickActions(context),

                const SizedBox(height: 30),

                /// MANAGEMENT
                const Text(
                  "Management",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _buildManagementCards(context),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.lightBlue.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.lightBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Admin",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Manage users, academic content and learning resources.",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      _StatItem(
        title: "Users",
        icon: Icons.people,
        color: Colors.blue,
        type: "users",
        query: FirebaseFirestore.instance.collection('users'),
      ),
      _StatItem(
        title: "Students",
        icon: Icons.school,
        color: Colors.green,
        type: "students",
        query: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'student'),
      ),

      _StatItem(
        title: "Teachers",
        icon: Icons.person,
        color: Colors.deepPurple,
        type: "teachers",
        query: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher'),
      ),

      _StatItem(
        title: "Universities",
        icon: Icons.account_balance,
        color: Colors.orange,
        type: "universities",
        query: FirebaseFirestore.instance.collection('universities'),
      ),

      _StatItem(
        title: "Departments",
        icon: Icons.domain,
        color: Colors.teal,
        type: "departments",
        query: FirebaseFirestore.instance.collection('departments'),
      ),

      _StatItem(
        title: "Courses",
        icon: Icons.menu_book,
        color: Colors.indigo,
        type: "courses",
        query: FirebaseFirestore.instance.collection('courses'),
      ),

      _StatItem(
        title: "Notes",
        icon: Icons.note_alt,
        color: Colors.redAccent,
        type: "notes",
        query: FirebaseFirestore.instance.collection('notes'),
      ),

      _StatItem(
        title: "Quizzes",
        icon: Icons.quiz,
        color: Colors.pink,
        type: "quizzes",
        query: FirebaseFirestore.instance.collection('quizzes'),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1200) {
          columns = 4;
        } else if (constraints.maxWidth >= 700) {
          columns = 3;
        } else if (constraints.maxWidth >= 450) {
          columns = 2;
        } else {
          columns = 2;
        }

        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: _statCard(
                stat,
                onTap: () {
                  if (stat.type == "notes") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNotesViewScreen(),
                      ),
                    );
                  } else if (stat.type == "quizzes") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminQuizViewScreen(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminCollectionViewScreen(
                          title: stat.title,
                          query: stat.query,
                          type: stat.type,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statCard(_StatItem stat, {required VoidCallback onTap}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stat.query.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stat.color.withOpacity(0.10)),
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
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 24),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
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

        const spacing = 12.0;

        final cardWidth = (width - ((columns - 1) * spacing)) / columns;

        final actions = [
          (
            Icons.account_balance,
            "Add University",
            "Create university",
            Colors.orange,
            "Add University",
          ),
          (
            Icons.domain,
            "Add Department",
            "Create department",
            Colors.teal,
            "Add Department",
          ),
          (
            Icons.menu_book,
            "Add Course",
            "Create course",
            Colors.indigo,
            "Add Course",
          ),
          (
            Icons.note_add,
            "Upload Note",
            "Add study material",
            Colors.redAccent,
            "Upload Note",
          ),
          (
            Icons.quiz,
            "Upload Quiz",
            "Add quiz content",
            Colors.pink,
            "Upload Quiz",
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((action) {
            return SizedBox(
              width: cardWidth,
              child: _actionCard(
                icon: action.$1,
                title: action.$2,
                subtitle: action.$3,
                color: action.$4,
                onTap: () {
                  final academic = const AdminAcademicManagementScreen();

                  if (action.$5 == "Add University") {
                    academic.showAddUniversity(context);
                  } else if (action.$5 == "Add Department") {
                    academic.showAddDepartment(context);
                  } else if (action.$5 == "Add Course") {
                    academic.showAddCourse(context);
                  }else if (action.$5 == "Upload Note") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadNoteScreen(),
                      ),
                    );
                  }else if (action.$5 == "Upload Quiz") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherScreenSelection(),
                      ),
                    );
                  }
                  else {
                    _showComingSoon(context, action.$5);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
  // ============================================================
  // MANAGEMENT
  // ============================================================

  Widget _buildManagementCards(BuildContext context) {
    return LayoutBuilder(
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

        const spacing = 12.0;

        final cardWidth = (width - ((columns - 1) * spacing)) / columns;

        final managementItems = [
          (
            Icons.people,
            "Teacher Requests",
            "Review teacher registrations",
            Colors.blue,
            "teacher",
          ),
          (
            Icons.note_alt,
            "Notes Approval",
            "Review pending notes",
            Colors.orange,
            "notesApproval",
          ),
          // (
          //   Icons.library_books,
          //   "Manage Notes",
          //   "View and manage notes",
          //   Colors.redAccent,
          //   "notes",
          // ),
          // (
          //   Icons.quiz,
          //   "Manage Quizzes",
          //   "View and manage quizzes",
          //   Colors.pink,
          //   "quizzes",
          // ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: managementItems.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _managementCard(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                color: item.$4,
                onTap: () {
                  if (item.$5 == "teacher") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminTeacherScreen()),
                    );
                  } else if (item.$5 == "notesApproval") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminNotesScreen(),
                      ),
                    );
                  } else {
                    _showComingSoon(context, item.$2);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _actionCard({
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
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // MANAGEMENT CARD
  // ============================================================

  Widget _managementCard({
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
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 7,
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
              child: Icon(icon, color: color, size: 25),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
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
  // TEMPORARY ACTION
  // ============================================================

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$action will be connected next."),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ================================================================
// STAT MODEL
// ================================================================

class _StatItem {
  final String title;
  final IconData icon;
  final Color color;
  final Query query;
  final String type;

  const _StatItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.query,
    required this.type,
  });
}
