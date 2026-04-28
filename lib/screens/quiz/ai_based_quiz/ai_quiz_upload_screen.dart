import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fyp_ui_design/screens/quiz/ai_based_quiz/ai_quiz_edit_screen.dart';
import 'package:fyp_ui_design/screens/quiz/quiz_screen.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;

class AIQuizUploadScreen extends StatefulWidget {
  final bool isTeacher;

  static _AIQuizUploadScreenState? _instance;
  static void submit() {
    _instance?._saveQuiz();
  }
  const AIQuizUploadScreen({super.key, required this.isTeacher});

  @override
  State<AIQuizUploadScreen> createState() => _AIQuizUploadScreenState();
}

class _AIQuizUploadScreenState extends State<AIQuizUploadScreen> {
  String? selectedUniversity;
  String? selectedDepartment;
  String? selectedSemester;
  String? selectedSubject;
  bool isLoading = false;

  final locationCtrl = TextEditingController();

  final List<String> semesters = List.generate(8, (i) => 'Semester ${i + 1}');
  File? selectedFile;
  bool loading = false;
  final uniCtrl = TextEditingController();
  final deptCtrl = TextEditingController();
  final semCtrl = TextEditingController();
  final subCtrl = TextEditingController();
  List generatedQuiz = [];
  final String baseUrl = "http://192.168.100.13:3000";
  // final String baseUrl = "http://10.99.151.209:3000";

  String normalize(String input) {
    input = input.trim();
    if (input.isEmpty) return "";

    List<String> words = input.split(' ');
    List<String> result = [];

    for (var word in words) {
      if (word.isEmpty) continue;
      result.add(
        word[0].toUpperCase() + word.substring(1).toLowerCase(),
      );
    }

    return result.join(' ');
  }
  // 📁 PICK FILE
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }
  Stream<List<String>> universitiesStream() {
    return FirebaseFirestore.instance
        .collection('universities')
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toSet().toList());
  }
  Stream<List<String>> locationsStream() {
    if (selectedUniversity == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('universities')
        .where('name', isEqualTo: selectedUniversity)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc['location']?.toString() ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    });
  }

  Stream<List<String>> departmentsStream() {
    if (selectedUniversity == null || locationCtrl.text.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('departments')
        .where('university', isEqualTo: selectedUniversity)
        .where('location', isEqualTo: normalize(locationCtrl.text))
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toList());
  }

  Stream<List<String>> subjectsStream() {
    if (selectedDepartment == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('courses')
        .where('department', isEqualTo: selectedDepartment)
        .snapshots()
        .map((s) =>
        s.docs.map((d) => d['name'].toString()).toSet().toList());
  }

  // 🤖 GENERATE QUIZ
  Future<void> generateQuiz() async {
    if (selectedFile == null) return;

    setState(() => loading = true);
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/generate-quiz-file"),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath("file", selectedFile!.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      setState(() => loading = false);

      //  IMPORTANT: get quiz array directly
      final data = jsonDecode(resBody);

// 🔥 STEP 1: ERROR CHECK
      if (data["error"] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${data["error"]}")),
        );
        return;
      }

// 🔥 STEP 2: SAFE EXTRACTION
      final quiz = data["quiz"] ?? data["questions"];

      if (quiz == null || quiz is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid quiz response from server")),
        );
        return;
      }

      // generatedQuiz = quiz;
      generatedQuiz = List.from(quiz);

      if (quiz == null || quiz.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No quiz generated from file")));
        return;
      }

      if (widget.isTeacher) {
        // 🔵 TEACHER FLOW (same as before)
        final updatedQuiz = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIQuizEditScreen(
              quiz: quiz,
              university: selectedUniversity,
              department: selectedDepartment,
              semester: selectedSemester,
              subject: selectedSubject,
            ),
          ),
        );

        if (updatedQuiz != null && updatedQuiz is List) {
          generatedQuiz = updatedQuiz;
        }
      } else {
        // 🟢 STUDENT FLOW (DIRECT QUIZ)

        String fileName = p.basename(selectedFile!.path);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              quizId: null,
              quizData: List.from(quiz),
              isEditable: false,

              subject: "AI Generated Quiz",
              department: fileName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    AIQuizUploadScreen._instance = this;
  }



  Future<void> _saveQuiz() async {
    if (selectedUniversity == null ||
        selectedDepartment == null ||
        selectedSemester == null ||
        selectedSubject == null ||
        locationCtrl.text.isEmpty ||
        generatedQuiz.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fill all fields")));
      return;
    }
    setState(() => isLoading = true);

    try{
      await FirebaseFirestore.instance.collection('quizzes').add({
        "university": selectedUniversity,
        "department": selectedDepartment,
        "location": normalize(locationCtrl.text),
        "semester": int.tryParse(
      selectedSemester?.split(' ').last ?? ''
    ) ?? 0,
        "subject": selectedSubject,
        "questions": generatedQuiz,
        "isPublic": true,
        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text("Quiz Submitted Successfully")),
      );
      Navigator.pop(context);
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }finally{
      if (mounted) setState(() => isLoading = false);
    }
  }
  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          )
        ],
      ),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
  // 🧩 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children:[ SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isTeacher)
                    Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'Quiz Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),

                          StreamBuilder<List<String>>(
                            stream: universitiesStream(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox();
                              return DropdownButtonFormField<String>(
                                value: selectedUniversity,
                                decoration:
                                const InputDecoration(labelText: 'University'),
                                items: snap.data!
                                    .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedUniversity = v;
                                    locationCtrl.clear();
                                    selectedDepartment = null;
                                    selectedSubject = null;
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          StreamBuilder<List<String>>(
                            stream: locationsStream(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }

                              return DropdownButtonFormField<String>(
                                value: locationCtrl.text.isEmpty ? null : locationCtrl.text,
                                decoration: const InputDecoration(
                                  labelText: 'Campus / Location',
                                ),
                                items: snapshot.data!
                                    .map((loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc),
                                ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    locationCtrl.text = v!;
                                    selectedDepartment = null;
                                    selectedSubject = null;
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: selectedSemester,
                            decoration:
                            const InputDecoration(labelText: 'Semester'),
                            items: semesters
                                .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedSemester = v),
                          ),

                          const SizedBox(height: 12),

                          StreamBuilder<List<String>>(
                            stream: departmentsStream(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox();
                              return DropdownButtonFormField<String>(
                                value: selectedDepartment,
                                decoration:
                                const InputDecoration(labelText: 'Department'),
                                items: snap.data!
                                    .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedDepartment = v),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          StreamBuilder<List<String>>(
                            stream: subjectsStream(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox();
                              return DropdownButtonFormField<String>(
                                value: selectedSubject,
                                decoration:
                                const InputDecoration(labelText: 'Subject'),
                                items: snap.data!
                                    .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedSubject = v),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  //  INFO TEXT
                  Text(
                    widget.isTeacher
                        ? "Upload notes to generate quiz (you can edit later)"
                        : "Generate your personal AI quiz instantly (private practice)",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // 📁 FILE BUTTON
                  _card(
                    title: 'Upload File',
                    child: GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: selectedFile != null
                              ? Colors.green.withOpacity(0.05)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedFile != null
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedFile != null
                                  ? Icons.check_circle
                                  : Icons.cloud_upload,
                              size: 55,
                              color: selectedFile != null
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 10),

                            /// 🔹 FILE NAME
                            Text(
                              selectedFile != null
                                  ? p.basename(selectedFile!.path)
                                  : 'Tap to upload PDF or Image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selectedFile != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selectedFile != null
                                    ? Colors.green.shade700
                                    : Colors.black54,
                              ),
                            ),

                            /// 🔹 REMOVE BUTTON (IMPORTANT UX)
                            if (selectedFile != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFile = null;
                                  });
                                },
                                child: const Text(
                                  "Remove",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const SizedBox(height: 30),

                  // 🤖 GENERATE BUTTON
                  loading
                      ? const CircularProgressIndicator()
                      :ElevatedButton(
                    onPressed: generateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Generate AI Quiz",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                    ),
                  ),
                  if (generatedQuiz.isNotEmpty && widget.isTeacher) ...[
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () async {
                        if (widget.isTeacher) {
                          // 🔵 TEACHER FLOW (same as before)
                          final updatedQuiz = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AIQuizEditScreen(
                                quiz: generatedQuiz,
                                university: selectedUniversity,
                                department: selectedDepartment,
                                semester: selectedSemester,
                                subject: selectedSubject,
                              ),
                            ),
                          );

                          if (updatedQuiz != null && updatedQuiz is List) {
                            generatedQuiz = updatedQuiz;
                          }
                        }
                        else {
                          // 🟢 STUDENT FLOW (NEW)

                          String fileName = p.basename(selectedFile!.path);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizScreen(
                                quizId: null,
                                quizData: List.from(generatedQuiz),
                                isEditable: false,

                                // 🔥 AI info
                                subject: "AI Quiz",
                                department: fileName,
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.edit),
                      label: Text("Edit Generated Quiz"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
            // LOADING OVERLAY
            if (isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Uploading Quiz...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ]
      ),
    );
  }
}
