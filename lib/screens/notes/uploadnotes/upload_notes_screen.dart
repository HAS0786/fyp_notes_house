  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:path/path.dart';
  import 'package:fyp_ui_design/firebase/services/note_upload_service.dart';
  import 'package:flutter/material.dart';
  import 'package:file_picker/file_picker.dart';
  import 'dart:convert';
  import 'package:crypto/crypto.dart';
  
  class UploadNoteScreen extends StatefulWidget {
    const UploadNoteScreen({super.key});
  
    @override
    State<UploadNoteScreen> createState() => _UploadNoteScreenState();
  }
  
  class _UploadNoteScreenState extends State<UploadNoteScreen> {
    // Dropdown values
    String? selectedUniversity;
    String? selectedDepartment;
    String? selectedSemester;
    String? selectedTypeofDocument;
    String? selectedCourse;
    bool isUploading = false;
  
  
  
    // Controllers
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
  
    // Selected file
    File? selectedFile;
  
    // Mock lists (later from Firestore)
    List<String> universities = [
      'Punjab University',
      'GC University Lahore',
      'UET Lahore',
      'COMSATS University',
    ];
  
    List<String> departments = [
      'Computer Science',
      'Software Engineering',
      'Electrical Engineering',
      'Business Administration',
    ];
  
    List<String> semesters = List.generate(8, (i) => 'Semester ${i + 1}');
  
    List<String> courses = [
      'Data Structures',
      'OOP',
      'Database Systems',
      'Operating Systems',
      'Web Development',
    ];
    List<String> typeofDocument = [
      'Books',
      'Notes',
      'Past Papers',
      'Assignments ',
      'Lab Manuals',
      'Projects',
    ];
  
    // Add new item dialog
    void _addNew(BuildContext context, String type) {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Add New $type'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter $type name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
  
                final db = FirebaseFirestore.instance;

                if (type == 'University') {
                  final docId = text.toLowerCase(); // ❗ REMOVE location dependency

                  await db.collection('universities').doc(docId).set({
                    'name': normalize(text),
                    'location': "", // empty initially
                    'createdAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  setState(() {
                    selectedUniversity = normalize(text);
                  });
                }
                if (type == 'Location') {
                  final loc = normalize(text);

                  final docId = selectedUniversity!.toLowerCase();

                  await db.collection('universities').doc(docId).update({
                    'location': loc,
                  });

                  setState(() {
                    locationCtrl.text = loc;
                  });
                }
  
                if (type == 'Department') {
                  final docId =
                      '${selectedUniversity}_${locationCtrl.text.trim()}_${text}'
                          .toLowerCase();
  
                  await db.collection('departments').doc(docId).set({
                    'name': text,
                    'university': selectedUniversity,
                    'location': locationCtrl.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  setState(() {
                    selectedDepartment = text;
                  });
                }
  
                if (type == 'Course') {
                  final docId = '${selectedDepartment}_${text}'.toLowerCase();
  
                  await db.collection('courses').doc(docId).set({
                    'name': text,
                    'department': selectedDepartment,
                    'createdAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  setState(() {
                    selectedCourse = text;
                  });
                }
  
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }
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
    Future<void> _pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any, //  IMPORTANT
      );
  
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
  
        setState(() {
          selectedFile = file; //  force new reference
        });
  
        debugPrint("FILE PICKED: ${file.path}");
      }
    }
  
    // Upload note
    Future<void> _uploadNote(BuildContext context) async {
  
      if (selectedUniversity == null ||
          locationCtrl.text.isEmpty ||
          selectedDepartment == null ||
          selectedSemester == null ||
          selectedTypeofDocument == null ||
          selectedCourse == null ||
          selectedFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }
      final fileId = await generateFileHash(selectedFile!);
  // 🔍 check duplicate
      final existing = await FirebaseFirestore.instance
          .collection('notes')
          .where('fileId', isEqualTo: fileId)
          .where('university', isEqualTo: normalize(selectedUniversity!))
          .where('location', isEqualTo: normalize(locationCtrl.text))
          .where('department', isEqualTo: normalize(selectedDepartment!))
          .where('subject', isEqualTo: normalize(selectedCourse!))
          .get();
  
      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
  
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File already uploaded")),
        );
        return;
      }
      setState(() => isUploading = true);
      final success = await NoteUploadService.uploadNote(
        file: selectedFile!,
        title: titleCtrl.text.trim(),
        university: normalize(selectedUniversity!),
        location: normalize(locationCtrl.text),
        department: normalize(selectedDepartment!),
        subject: normalize(selectedCourse!),
        semester: int.parse(selectedSemester!.split(' ').last),
        resourceType: selectedTypeofDocument!,
        fileId: fileId,
      );
  
      if (!mounted) return;
      setState(() => isUploading = false);
  
      if (success) {
        await _ensureUniversityHasLocation(); // ADD THIS LINE
  
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Note uploaded successfully'),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
    }
  
    Stream<List<String>> universitiesStream() {
      return FirebaseFirestore.instance
          .collection('universities')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => doc['name'].toString())
                .toSet()
                .toList(),
          );
    }
  
    Stream<List<String>> departmentsStream() {
      if (selectedUniversity == null || locationCtrl.text.isEmpty) {
        return const Stream.empty();
      }
  
      return FirebaseFirestore.instance
          .collection('departments')
          .where('university', isEqualTo: selectedUniversity)
          .where('location', isEqualTo: locationCtrl.text.trim())
          .snapshots()
          .map(
            (snapshot) => snapshot.docs.map((d) => d['name'].toString()).toList(),
          );
    }
  
    Future<void> _ensureUniversityHasLocation() async {
      final db = FirebaseFirestore.instance;
  
      final snap = await db
          .collection('universities')
          .where('name', isEqualTo: selectedUniversity)
          .get();
  
      if (snap.docs.isEmpty) return;
  
      final doc = snap.docs.first;
      final data = doc.data();
  
      if ((data['location'] ?? '').toString().trim().isEmpty) {
        await doc.reference.update({'location': locationCtrl.text.trim()});
      }
    }
  
    Stream<List<String>> coursesStream() {
      if (selectedDepartment == null) {
        return const Stream.empty();
      }
  
      return FirebaseFirestore.instance
          .collection('courses')
          .where('department', isEqualTo: selectedDepartment)
          .snapshots()
          .map((snapshot) {
            final unique = snapshot.docs
                .map((d) => d['name'].toString().trim())
                .toSet() // REMOVE DUPLICATES
                .toList();
            unique.sort();
            return unique;
          });
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
        final values = snapshot.docs
            .map((doc) => doc['location']?.toString() ?? "")
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
  
        return values;
      });
    }
  
    String generateFileId(File file) {
      final name = basename(file.path);
      final size = file.lengthSync();
      return "${name}_$size";
    }
    Future<String> generateFileHash(File file) async {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes);
      return hash.toString();
    }
  
    @override
    Widget build(BuildContext context) {
      return Stack(
        children:[ Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: const Text('Upload Note'),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () async {
                  await _uploadNote(context);
                },
                child: const Text(
                  'Upload',
                  style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),            ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
  
              children: [
  
                /// ================= ACADEMIC INFO =================
                _card(
                  title: 'Academic Information',
                  child: Column(
                    children: [
  
                      // University
                      StreamBuilder<List<String>>(
                        stream: universitiesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedUniversity,
                                  decoration: const InputDecoration(
                                    labelText: 'University',
                                  ),
                                  items: snapshot.data!
                                      .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedUniversity = v;
                                      selectedDepartment = null;
                                      selectedCourse = null;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => _addNew(context, 'University'),
                              ),
                            ],
                          );
                        },
                      ),
  
                      const SizedBox(height: 12),
  
                      // Location
                      StreamBuilder<List<String>>(
                        stream: locationsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
  
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
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
                                    });
                                  },
                                ),
                              ),
  
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => _addNew(context, 'Location'),
                              ),
                            ],
                          );
                        },
                      ),
  
                      const SizedBox(height: 12),
  
                      // Semester
                      DropdownButtonFormField<String>(
                        value: selectedSemester,
                        decoration: const InputDecoration(labelText: 'Semester'),
                        items: semesters
                            .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedSemester = v),
                      ),
  
                      const SizedBox(height: 12),
  
                      // Type of Document
                      DropdownButtonFormField<String>(
                        value: selectedTypeofDocument,
                        decoration:
                        const InputDecoration(labelText: 'Type of Document'),
                        items: typeofDocument
                            .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedTypeofDocument = v),
                      ),
  
                      const SizedBox(height: 12),
  
                      // Department
                      StreamBuilder<List<String>>(
                        stream: departmentsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDepartment,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                  ),
                                  items: snapshot.data!
                                      .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedDepartment = v;
                                      selectedCourse = null;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => _addNew(context, 'Department'),
                              ),
                            ],
                          );
                        },
                      ),
  
                      const SizedBox(height: 12),
  
                      // Course
                      StreamBuilder<List<String>>(
                        stream: coursesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedCourse,
                                  decoration: const InputDecoration(
                                    labelText: 'Course / Subject',
                                  ),
                                  items: snapshot.data!
                                      .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedCourse = v),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => _addNew(context, 'Course'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
  
                const SizedBox(height: 20),
  
                /// ================= FILE UPLOAD =================
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
                                ? basename(selectedFile!.path)
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
  
                const SizedBox(height: 20),
  
                /// ================= NOTE DETAILS =================
                _card(
                  title: 'Note Details',
                  child: Column(
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration:
                        const InputDecoration(labelText: 'Note Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          if (isUploading)
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
                      "Uploading Notes...",
                      style: TextStyle(fontSize:15,color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
  
    /// ================= CARD HELPER =================
    Widget _card({required String title, required Widget child}) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              child,
            ],
          ),
        ),
      );
    }
  
    @override
    void dispose() {
      titleCtrl.dispose();
      descCtrl.dispose();
      super.dispose();
    }
  }
