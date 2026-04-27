import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fyp_ui_design/screens/aichatbot/ai_chat_screen.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';

class OfflineNotesScreen extends StatefulWidget {
  const OfflineNotesScreen({super.key});

  @override
  State<OfflineNotesScreen> createState() => _OfflineNotesScreenState();
}

class _OfflineNotesScreenState extends State<OfflineNotesScreen> {
  List<FileSystemEntity> pdfFiles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineNotes();
  }

  Future<void> _loadOfflineNotes() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();

    setState(() {
      pdfFiles = files
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();
      loading = false;
    });
  }

  String _fileName(String path) {
    return path.split('/').last.replaceAll('.pdf', '');
  }

  // 🔴 Delete PDF
  Future<void> _deleteFile(FileSystemEntity file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline Note'),
        content: const Text(
          'Are you sure you want to delete this file? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await File(file.path).delete();
      _loadOfflineNotes(); // refresh list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline note deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Offline Notes'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pdfFiles.isEmpty
          ? const Center(
        child: Text(
          'No offline notes downloaded',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: pdfFiles.length,
        itemBuilder: (_, i) {
          final file = pdfFiles[i];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),

              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 26,
                ),
              ),

              title: Text(
                _fileName(file.path),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Available offline',
                  style: TextStyle(color: Colors.black54),
                ),
              ),

              // 🔹 Menu (Delete)
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteFile(file);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FileViewerScreen(
                      fileUrl: file.path,
                      title: _fileName(file.path),
                      isLocal: true,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
