import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/teacherdraft/quiz_viewer_screen.dart';
import 'package:fyp_ui_design/screens/notes/uploadnotes/upload_notes_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_screen.dart';
import 'package:http/http.dart' as http;

class TeacherDraftScreen extends StatefulWidget {
  const TeacherDraftScreen({super.key});

  @override
  State<TeacherDraftScreen> createState() => _TeacherDraftScreenState();
}

class _TeacherDraftScreenState extends State<TeacherDraftScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List quizzes = [];
  bool isQuizLoading = true;

  final String baseUrl = "http://192.168.100.13:3000";
  // final String baseUrl = "http://10.99.151.209:3000";

  List notes = [];
  bool isLoading = true;

  String currentStatus = "pending";

  Future<void> fetchQuizzes() async {
    setState(() => isQuizLoading = true);

    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/teacher-quizzes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        quizzes = jsonDecode(res.body);
        isQuizLoading = false;
      });
    } else {
      setState(() => isQuizLoading = false);
    }
  }

  Widget buildQuizList() {
    if (isQuizLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quizzes.isEmpty) {
      return const Center(child: Text("No quizzes yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quizzes.length,
      itemBuilder: (_, i) {
        final quiz = quizzes[i];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizViewerScreen(
                  questions: quiz['questions'] ?? [],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // TITLE + TYPE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quiz['subject'] ?? "Quiz",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: quiz['type'] == "ai"
                            ? Colors.purple.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (quiz['type'] ?? "manual").toUpperCase(),
                        style: TextStyle(
                          color: quiz['type'] == "ai"
                              ? Colors.purple
                              : Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                ///  DETAILS
                buildInfoRow(Icons.school, quiz['university'] ?? ""),
                buildInfoRow(Icons.location_on, quiz['location'] ?? "Not Specified"),
                buildInfoRow(Icons.account_tree, quiz['department'] ?? ""),
                buildInfoRow(Icons.menu_book,
                    quiz['semester'] != null ? "Semester ${quiz['semester']}" : "No semester"),

                const SizedBox(height: 8),

                ///  OPEN HINT
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchNotes();
    fetchQuizzes();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      if (_tabController.index == 0) currentStatus = "pending";
      if (_tabController.index == 1) currentStatus = "approved";
      if (_tabController.index == 2) currentStatus = "rejected";

      fetchNotes();
    });

    fetchNotes();
  }

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<void> fetchNotes() async {
    setState(() => isLoading = true);

    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/teacher-notes?status=$currentStatus"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        notes = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteNote(String id) async {
    final token = await _getToken();
    await http.delete(
      Uri.parse("$baseUrl/delete-note/$id"),
      headers: {"Authorization": "Bearer ${token}"},
    );

    fetchNotes();
  }

  Future<void> resubmitNote(String id) async {
    final token = await _getToken();
    await http.post(
      Uri.parse("$baseUrl/resubmit-note"),
      headers: {
        "Authorization": "Bearer ${token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"noteId": id}),
    );

    fetchNotes();
  }

  Widget buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text ?? "", style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget buildCard(note) {
    final status = note['status'];

    Color statusColor;
    if (status == "approved") {
      statusColor = Colors.green;
    } else if (status == "rejected") {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        if (status == "approved" && note['fileUrl'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FileViewerScreen(
                title: note['title'] ?? "Document",
                fileUrl: note['fileUrl'],
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note['title'] ?? "No Title",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// 🔹 INFO SECTION
            buildInfoRow(Icons.school, note['university']),
            buildInfoRow(Icons.location_on, note['location']),
            buildInfoRow(Icons.account_tree, note['department'] ?? ""),
            buildInfoRow(Icons.menu_book, "Semester ${note['semester']}"),
            buildInfoRow(Icons.book, note['subject']),

            /// 🔴 REJECTION REASON
            if (status == "rejected" && note['rejectionReason'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Reason: ${note['rejectionReason']}",
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            const SizedBox(height: 10),

            /// 🔹 ACTIONS
            Row(
              children: [
                if (status == "pending" || status == "rejected")
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UploadNoteScreen(
                            isEdit: true,
                            noteData: note,
                            noteId: note['id'],
                          ),
                        ),
                      );
                    },
                  ),

                if (status != "approved")
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => deleteNote(note['id']),
                  ),


                if (status == "rejected")
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => resubmitNote(note['id']),
                    child: const Text("Resubmit"),
                  ),
              ],
            ),
            if (status == "approved")
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notes.isEmpty) {
      return const Center(
        child: Text(
          "No drafts yet",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchNotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notes.length,
        itemBuilder: (_, i) => buildCard(notes[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Drafts"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          dividerColor: Colors.white,
          labelColor: Colors.white,
          dividerHeight: 3,
          controller: _tabController,

          tabs: const [
            Tab(
              icon: Icon(
                Icons.pending_actions_outlined,
                color: Colors.orangeAccent,
              ),
              text: "Pending",
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline_sharp, color: Colors.green),
              text: "Approved",
            ),
            Tab(
              icon: Icon(Icons.block_flipped, color: Colors.red),
              text: "Rejected",
            ),
            Tab(
              icon: Icon(Icons.quiz, color: Colors.green),
              text: "Quizzes",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [buildList(), buildList(), buildList(), buildQuizList()],
      ),
    );
  }
}
