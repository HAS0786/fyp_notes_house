import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp_ui_design/screens/aichatbot/ai_chat_screen.dart';

class FileViewerScreen extends StatefulWidget {
  final String title;
  final String fileUrl;
  final bool isLocal;
  const FileViewerScreen({
    super.key,
    required this.title,
    required this.fileUrl,
    this.isLocal = false,
  });

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  String? localPath;
  bool loading = true;

  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    if (widget.isLocal) {
      localPath = widget.fileUrl;
      loading = false;
    } else {
      _downloadTempFile();
    }

  }

  // 🔹 Detect file type
  bool isPdf(String path) => path.toLowerCase().endsWith(".pdf");

  bool isImage(String path) =>
      path.toLowerCase().endsWith(".png") ||
          path.toLowerCase().endsWith(".jpg") ||
          path.toLowerCase().endsWith(".jpeg");

  // 🔹 Download file temporarily
  Future<void> _downloadTempFile() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.title}');

      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      _showMessage('Failed to load file');
    }
  }

  // 🔹 Open unsupported files externally
  Future<void> _openExternally() async {
    final url = Uri.parse(widget.fileUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showMessage("Cannot open file");
    }
  }

  // 🔹 Save for offline use
  Future<void> _downloadOffline() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // final file = File('${dir.path}/${widget.title}');
      final file = File('${dir.path}/${widget.title}.pdf');


      if (await file.exists()) {
        _showMessage('Already downloaded');
        return;
      }

      final response = await http.get(Uri.parse(widget.fileUrl));
      await file.writeAsBytes(response.bodyBytes);

      _showMessage('Saved for offline use');
    } catch (e) {
      _showMessage('Download failed');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // 🔥 MAIN VIEWER LOGIC
  Widget _buildViewer() {
    if (localPath == null) {
      return const Center(child: Text("No file available"));
    }

    print("OPENING FILE: $localPath");

    // 🔥 FORCE PDF VIEWER (NO CHECK)
    return SfPdfViewer.file(
      File(localPath!),
      controller: _pdfController,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadOffline,
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildViewer(),

      // 🤖 AI Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        icon: const Icon(Icons.smart_toy),
        label: const Text('Ask AI'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIChatScreen(
                pdfPath: localPath!,
                pdfTitle: widget.title,
              ),
            ),
          );
        },
      ),
    );
  }
}