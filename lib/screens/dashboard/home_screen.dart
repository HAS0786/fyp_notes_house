import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/firebase/services/local_notification_service.dart';
import 'package:fyp_ui_design/firebase/services/notification_service.dart';
import 'package:fyp_ui_design/screens/dashboard/searchbar.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/select_university_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/teacherdraft/teacher_draft_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_history/quiz_history_screen.dart';
import 'package:fyp_ui_design/screens/quiz/result_performance/quiz_performance_analysis_screen.dart';
import 'package:fyp_ui_design/screens/notes/uploadnotes/upload_notes_screen.dart';
import 'package:fyp_ui_design/screens/quiz/student/screen_selection.dart';
import 'package:fyp_ui_design/screens/quiz/teacher/screen_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../aichatbot/ai_chat_screen.dart';
import '../notes/downloadnotes/offline_notes_showing_screen.dart';
import '../profile/profile_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String userRole = 'student';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadUserRole();
    _listenForRoleChange();
    NotificationService.saveToken(); // VERY IMPORTANT

    FirebaseMessaging.onMessage.listen((message) {
      LocalNotificationService.show(message);
    });
  }

  void _listenForRoleChange() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
          final role = doc.data()?['role'];

          final prefs = await SharedPreferences.getInstance();
          // final oldRole = prefs.getString('user_role');

          final status = doc.data()?['status'];
          final reason = doc.data()?['rejectionReason'];

          final alreadyShown = prefs.getBool('teacher_approved_shown') ?? false;

          if (status == 'approved' &&
              role == 'teacher' &&
              userRole != 'teacher' &&
              !alreadyShown) {
            await prefs.setBool('teacher_approved_shown', true);

            await prefs.setString('user_role', 'teacher');

            if (!mounted) return;

            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('🎉 Approved!'),
                content: const Text(
                  'Your teacher account has been approved.\n'
                  'You now have access to teacher features.',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() {
                        userRole = 'teacher';
                      });

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
          }
          if (status == 'rejected') {
            await prefs.setBool('teacher_approved_shown', false);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("❌ Request Rejected"),
                content: Text(
                  "Your teacher request was rejected.\n\nReason: ${reason ?? "Not specified"}",
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await retryTeacher(); // 👈 API call
                    },
                    child: const Text("Request Again"),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_role', 'student');

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        });
  }

  String welcomeText() {
    if (userRole == 'admin') return 'Welcome Admin!';
    if (userRole == 'teacher') return 'Welcome Teacher!';
    return 'Welcome, Champion';
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = doc.data()?['role'] ?? 'student';
    final status = doc.data()?['status'] ?? 'approved';

    String finalRole = role;

    if (role == 'teacher' && status != 'approved') {
      finalRole = 'student'; // 👈 FORCE student mode
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', finalRole);

    setState(() {
      userRole = finalRole;
      _isLoading = false;
    });
  }

  late final List<Widget> studentPages = [
    HomeTab(isTeacher: false, welcomeText: welcomeText()),
    OfflineNotesScreen(),
    QuizHistoryScreen(),
    const ProfileScreen(),
  ];

  late final List<Widget> teacherPages = [
    HomeTab(isTeacher: true, welcomeText: welcomeText()),
    TeacherDraftScreen(),
    OfflineNotesScreen(),
    const SelectUniversityScreen(),
    const ProfileScreen(),
  ];

  Future<void> retryTeacher() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final token = await user.getIdToken();

    final response = await http.post(
      Uri.parse("http://192.168.100.13:3000/retry-teacher"),
      // Uri.parse("http://10.99.151.209:3000/retry-teacher"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Request sent again")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Retry failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = (userRole == 'teacher' || userRole == 'admin')
        ? teacherPages
        : studentPages;

    return WillPopScope(
      onWillPop: () async {
        if (_index != 0) {
          setState(() => _index = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF007AFF),
          items: (userRole == 'teacher' || userRole == 'admin')
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.description),
                    label: 'Drafts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.download),
                    label: 'Downloads',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sticky_note_2),
                    label: 'Notes',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.download),
                    label: 'Downloads',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_edu),
                    label: "Quiz History",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final bool isTeacher;
  final String welcomeText;
  const HomeTab({
    super.key,
    required this.isTeacher,
    required this.welcomeText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/user.png'),
                );
              }

              final imagePath = snapshot.data!.getString('profile_image');

              return CircleAvatar(
                backgroundImage: imagePath != null
                    ? FileImage(File(imagePath))
                    : const AssetImage('assets/images/user.png')
                          as ImageProvider,
              );
            },
          ),
        ),

        title: const Text('Notes House'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearchDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              welcomeText,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (!isTeacher) ...[
              _card(
                context,
                'My Notes',
                'All your notes in one place',
                Icons.folder,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectUniversityScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _card(
                context,
                'Take Quiz',
                'Attempt or AI Practice',
                Icons.school,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentScreenSelection(
                        university: "YourUni",
                        department: "YourDept",
                        semester: 1,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _card(
                context,
                'Quiz Performance',
                'Your Quiz Stats Here',
                Icons.quiz,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizPerformanceScreen(),
                    ),
                  );
                },
              ),
            ],

            if (isTeacher) ...[
              _card(
                context,
                'Upload Notes',
                'Share with students',
                Icons.upload_file,
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UploadNoteScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _card(
                context,
                'Create Quiz',
                'Make new quizzes',
                Icons.add_task,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherScreenSelection(),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            _aiCard(context),
          ],
        ),
      ),
    );
  }

  static Widget _card(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(sub),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  static Widget _aiCard(BuildContext context) {
    return Center(
      child: Card(
        child: Column(
          children: [
            Container(
              height: 120,
              width: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/ai.webp'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'AI Study Buddy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Ask me anything about your course'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIChatScreen()),
                    ),
                    child: const Text('Start Chat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
