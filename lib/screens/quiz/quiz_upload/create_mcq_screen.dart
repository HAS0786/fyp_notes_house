import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/firebase/services/quiz_service.dart';


class CreateMCQScreen extends StatefulWidget {
  static _CreateMCQScreenState? _instance;
  const CreateMCQScreen({super.key});

  @override
  State<CreateMCQScreen> createState() => _CreateMCQScreenState();

  static void submit() {
    _instance?._submitQuiz();
  }
}


class _CreateMCQScreenState extends State<CreateMCQScreen> {
  String? selectedUniversity;
  String? selectedDepartment;
  String? selectedSemester;
  String? selectedSubject;
  String? correctAnswerIndex;
  bool isLoading = false;
  final locationCtrl = TextEditingController();
  final questionCtrl = TextEditingController();
  final option1Ctrl = TextEditingController();
  final option2Ctrl = TextEditingController();
  final option3Ctrl = TextEditingController();
  final option4Ctrl = TextEditingController();



  final List<Map<String, dynamic>> allQuestions = [];

  final List<String> semesters = List.generate(8, (i) => 'Semester ${i + 1}');

  @override
  void initState() {
    super.initState();
    CreateMCQScreen._instance = this;
  }
  String normalize(String input) {
    input = input.trim().toLowerCase();
    return input[0].toUpperCase() + input.substring(1);
  }
  // ---------------- STREAMS ----------------

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

  // ---------------- LOGIC ----------------

  void _addQuestion() {
    if (questionCtrl.text.isEmpty ||
        option1Ctrl.text.isEmpty ||
        option2Ctrl.text.isEmpty ||
        option3Ctrl.text.isEmpty ||
        option4Ctrl.text.isEmpty ||
        correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete question & options')),
      );
      return;
    }

    allQuestions.add({
      'question': questionCtrl.text.trim(),
      'options': [
        option1Ctrl.text.trim(),
        option2Ctrl.text.trim(),
        option3Ctrl.text.trim(),
        option4Ctrl.text.trim(),
      ],
      'correct': correctAnswerIndex,
    });

    questionCtrl.clear();
    option1Ctrl.clear();
    option2Ctrl.clear();
    option3Ctrl.clear();
    option4Ctrl.clear();
    correctAnswerIndex = null;

    setState(() {});
  }

  Future<void> _submitQuiz() async {
    if (allQuestions.isEmpty ||
        selectedUniversity == null ||
        selectedDepartment == null ||
        selectedSemester == null ||
        selectedSubject == null ||
        locationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    final success = await QuizService.createQuiz(
      university: selectedUniversity!,
      location: normalize(locationCtrl.text),
      department: normalize(selectedDepartment!),
      semester: int.parse(selectedSemester!.split(' ').last),      subject: selectedSubject!,
      questions: allQuestions,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Quiz created successfully"),
        ),
      );
      Navigator.pop(context);
    }
  }
  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[ Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // ================= BASIC INFO =================
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
                            onChanged: (v) =>
                                setState(() {
                                  selectedUniversity = v;
                                  locationCtrl.clear();
                                  selectedDepartment = null;
                                  selectedSubject = null;
                                }),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      StreamBuilder<List<String>>(
                        stream: locationsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

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
                        onChanged: (v) {
                          setState(() {
                            selectedSemester = v;
                          });
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

              const SizedBox(height: 20),

              // ================= QUESTION =================
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
                        'Add Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      TextField(
                        controller: questionCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Question'),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: option1Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option A',
                          prefixIcon: Radio<String>(
                            value: '0',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option2Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option B',
                          prefixIcon: Radio<String>(
                            value: '1',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option3Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option C',
                          prefixIcon: Radio<String>(
                            value: '2',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      TextField(
                        controller: option4Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Option D',
                          prefixIcon: Radio<String>(
                            value: '3',
                            groupValue: correctAnswerIndex,
                            onChanged: (v) =>
                                setState(() => correctAnswerIndex = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _addQuestion,
                        child: const Text('Add Question'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${allQuestions.length} question(s) added',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Uploading Quiz...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
    ]
    );
  }

  // ---------------- SMALL UI HELPERS ----------------

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _text(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _option(TextEditingController c, String label, String value) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: 'Option $label',
        prefixIcon: Radio<String>(
          value: value,
          groupValue: correctAnswerIndex,
          onChanged: (v) => setState(() => correctAnswerIndex = v),
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _universityDropdown() => StreamBuilder<List<String>>(
    stream: universitiesStream(),
    builder: (_, snap) {
      if (!snap.hasData) return const SizedBox();
      return DropdownButtonFormField(
        value: selectedUniversity,
        decoration: const InputDecoration(labelText: 'University'),
        items: snap.data!
            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
            .toList(),
        onChanged: (v) => setState(() => selectedUniversity = v),
      );
    },
  );

  Widget _departmentDropdown() => StreamBuilder<List<String>>(
    stream: departmentsStream(),
    builder: (_, snap) {
      if (!snap.hasData) return const SizedBox();
      return DropdownButtonFormField(
        value: selectedDepartment,
        decoration: const InputDecoration(labelText: 'Department'),
        items: snap.data!
            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
            .toList(),
        onChanged: (v) => setState(() => selectedDepartment = v),
      );
    },
  );

  Widget _subjectDropdown() => StreamBuilder<List<String>>(
    stream: subjectsStream(),
    builder: (_, snap) {
      if (!snap.hasData) return const SizedBox();
      return DropdownButtonFormField(
        value: selectedSubject,
        decoration: const InputDecoration(labelText: 'Subject'),
        items: snap.data!
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => selectedSubject = v),
      );
    },
  );

  Widget _semesterDropdown() => DropdownButtonFormField(
    value: semesters.contains(selectedSemester)
        ? selectedSemester
        : null,
    decoration: const InputDecoration(labelText: 'Semester'),
    items: semesters
        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
        .toList(),
    onChanged: (v) => setState(() => selectedSemester = v),
  );
}
