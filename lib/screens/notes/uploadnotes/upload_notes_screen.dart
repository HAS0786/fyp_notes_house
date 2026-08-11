import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/widgets/academic_info_form.dart';
import 'package:path/path.dart';
import 'package:fyp_ui_design/firebase/services/note_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class UploadNoteScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? noteData;
  final String? noteId;
  const UploadNoteScreen({
    super.key,
    this.isEdit = false,
    this.noteData,
    this.noteId,
  });

  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  bool isUploading = false;
  AcademicSelection academic = AcademicSelection();
  String? selectedTypeofDocument;

  // Controllers
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  // Selected file
  File? selectedFile;
  bool isFileValid = false;
// Existing file from Firestore (Edit mode)
  String? existingFileName;

  List<String> typeofDocument = [
    'Books',
    'Notes',
    'Past Papers',
    'Assignments ',
    'Lab Manuals',
    'Projects',
  ];

  // Add new item dialog
  String normalize(String input) {
    input = input.trim();
    if (input.isEmpty) return "";

    List<String> words = input.split(' ');
    List<String> result = [];

    for (var word in words) {
      if (word.isEmpty) continue;
      result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
    }

    return result.join(' ');
  }

  @override
  void initState() {
    super.initState();
    selectedFile = null;
    isFileValid = false;
    if (widget.isEdit && widget.noteData != null) {
      titleCtrl.text = widget.noteData!['title'] ?? '';
      descCtrl.text = widget.noteData!['description'] ?? '';
      existingFileName =
          widget.noteData!['fileName']?.toString() ??
              getCleanName(widget.noteData!['fileUrl']?.toString() ?? '');
      academic.subject = widget.noteData!['subject'] ?? '';
      academic.university = widget.noteData!['university'];
      academic.location = widget.noteData!['location'];
      academic.department = widget.noteData!['department'];
      academic.semester = widget.noteData!['semester'];
      String doc = (widget.noteData?['category'] ?? "").toString().trim();
      selectedTypeofDocument =
      typeofDocument.contains(doc) ? doc : null;
    }
    print(widget.noteData);
  }

  // Future<void> _pickFile() async {
  //   final result = await FilePicker.platform.pickFiles(
  //     allowMultiple: false,
  //     type: FileType.any, //  IMPORTANT
  //   );
  //
  //   if (result != null && result.files.single.path != null) {
  //     final file = File(result.files.single.path!);
  //
  //     setState(() {
  //       selectedFile = file;
  //     });
  //
  //     debugPrint("FILE PICKED: ${file.path}");
  //   }
  // }

  // Upload note
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();

      if (fileSize > NoteUploadService.maxFileSize) {
        setState(() {
          selectedFile = file;
          isFileValid = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(
            content: Text('File size must be 10 MB or less.'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      setState(() {
        selectedFile = file;
        isFileValid = true;
      });

      debugPrint("FILE PICKED: ${file.path}");
    }
  }
  Future<void> _uploadNote(BuildContext context) async {
    if (titleCtrl.text.trim().isEmpty ||
    academic.university == null ||
        academic.location == null ||
        academic.department == null ||
        academic.semester == null ||
        academic.subject == null ||
        (widget.isEdit == false && (selectedFile == null || !isFileValid)) ||
        selectedTypeofDocument == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields'),backgroundColor: Colors.red,));
      return;
    }

    setState(() => isUploading = true);

    /// 🔥 EDIT MODE
    if (widget.isEdit && widget.noteId != null) {

      // 🔥 CASE 1: USER ne NEW FILE select ki hai
      if (selectedFile != null) {
        final result = await NoteUploadService.uploadNote(
          file: selectedFile!,
          title: titleCtrl.text.trim(),
          university: normalize(academic.university!),
          location: normalize(academic.location!),
          department: normalize(academic.department!),
          subject: normalize(academic.subject!),
          semester: academic.semester!,
          resourceType: selectedTypeofDocument!,
          fileId: "",
          noteId: widget.noteId,
        );

        setState(() => isUploading = false); // 🔥 ALWAYS STOP LOADER

        if (!mounted) return;

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Note updated successfully"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Update failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      //  CASE 2: sirf text update
      else {
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.noteId)
            .update({
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'subject': academic.subject,
          'university': academic.university,
          'location': academic.location,
          'department': academic.department,
          'semester': academic.semester!,
          'resourceType': selectedTypeofDocument,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    /// 🔥 NEW NOTE
    else {
      final fileId = await NoteUploadService.generateFileHash(selectedFile!);


      final result = await NoteUploadService.uploadNote(
        file: selectedFile!,
        title: titleCtrl.text.trim(),
        university: normalize(academic.university!),
        location: normalize(academic.location!),
        department: normalize(academic.department!),
        subject: normalize(academic.subject!),
        semester: academic.semester!,
        resourceType: selectedTypeofDocument!,
        fileId: fileId,
      );

      await _ensureUniversityHasLocation();

      setState(() => isUploading = false);

      if (!mounted) return;

      if (result['duplicate'] == true) {
        setState(() => isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File already exists"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      else if (result['success'] == true) {
        setState(() => isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Note uploaded in Draft and pending for Admin-Review"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
      else {
        setState(() => isUploading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload failed")),
        );
      }
    }
  }

  Future<void> _ensureUniversityHasLocation() async {
    final db = FirebaseFirestore.instance;

    final snap = await db
        .collection('universities')
        .where('name', isEqualTo: academic.university)
        .get();

    if (snap.docs.isEmpty) return;

    final doc = snap.docs.first;

    final loc = normalize(academic.location!);

    await doc.reference.set({
      'location': FieldValue.arrayUnion([loc]),
    }, SetOptions(merge: true));
  }

  // For displaying Clean Name to User (when Edit button Click)

  String getCleanName(String url) {
    final name = basename(url);
    return name.replaceFirst(RegExp(r'^\d+-'), '');
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: Text(widget.isEdit ? 'Edit Note' : 'Upload Note'),
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () async {
                  await _uploadNote(context);
                },
                child: const Text(
                  'Upload',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  child: AcademicInfoForm(
                    value: academic,
                    onChanged: (val) {
                      setState(() {
                        academic = val;
                      });
                    },
                  ),
                ),
                _card(
                  title: 'Document Type',
                  child: DropdownButtonFormField<String>(
                    value: typeofDocument.contains(selectedTypeofDocument)
                        ? selectedTypeofDocument
                        : null,
                    decoration: const InputDecoration(labelText: 'Select Type'),
                    items: typeofDocument
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedTypeofDocument = v;
                      });
                    },
                  ),
                ),

                /// ================= FILE UPLOAD =================
                _card(
                  title: 'Upload File',
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      height: 170,
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
                            selectedFile != null && isFileValid
                                ? Icons.check_circle
                                : selectedFile != null
                                ? Icons.cancel
                                : Icons.cloud_upload,
                            size: 55,
                            color: selectedFile != null && isFileValid
                                ? Colors.green
                                : selectedFile != null
                                ? Colors.red
                                : Colors.grey
                          ),
                          const SizedBox(height: 10),

                          /// 🔹 FILE NAME
                          Text(
                            selectedFile != null
                                ? basename(selectedFile!.path)
                                : existingFileName != null && existingFileName!.isNotEmpty
                                ? existingFileName!
                                : 'Tap to upload PDF or Image\nMaximum size: 10 MB',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selectedFile != null || existingFileName != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selectedFile != null
                                  ? Colors.green.shade700
                                  : existingFileName != null
                                  ? Colors.blue.shade700
                                  : Colors.black54,
                            ),
                          ),
                          if (selectedFile != null) ...[
                            const SizedBox(height: 4),
                            FutureBuilder<int>(
                              future: selectedFile!.length(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();

                                final sizeMB = snapshot.data! / (1024 * 1024);

                                return Text(
                                  isFileValid
                                      ? '${sizeMB.toStringAsFixed(1)} MB • Valid file'
                                      : '${sizeMB.toStringAsFixed(1)} MB • Maximum size is 10 MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isFileValid ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ],
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
                            ),
                          ],
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
                        decoration: const InputDecoration(
                          labelText: 'Note Title',
                        ),
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
                    style: TextStyle(fontSize: 15, color: Colors.white),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
