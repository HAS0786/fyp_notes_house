import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:fyp_ui_design/screens/aichatbot/ai_chat_screen.dart';
import 'package:fyp_ui_design/config.dart';

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
  bool isUploaded = false;

  final PdfViewerController _pdfController = PdfViewerController();
  bool _savingAnnotations = false;

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

  // Detect file type
  bool isPdf(String path) => path.toLowerCase().endsWith(".pdf");

  bool isImage(String path) =>
      path.toLowerCase().endsWith(".png") ||
          path.toLowerCase().endsWith(".jpg") ||
          path.toLowerCase().endsWith(".jpeg");


  //  Save for offline use

  Future<void> _downloadTempFile() async {
    try {
      print("PDF URL: ${widget.fileUrl}");

      final response = await http.get(
        Uri.parse(widget.fileUrl),
      );

      print("PDF STATUS: ${response.statusCode}");
      print("PDF CONTENT-TYPE: ${response.headers['content-type']}");
      print("PDF SIZE: ${response.bodyBytes.length}");

      if (response.statusCode != 200) {
        throw Exception(
          "PDF download failed: ${response.statusCode}",
        );
      }

      final contentType = response.headers['content-type'];

      if (contentType != null &&
          !contentType.toLowerCase().contains('application/pdf')) {
        throw Exception(
          "Not a PDF. Content-Type: $contentType",
        );
      }

      final dir = await getTemporaryDirectory();

      final safeTitle = widget.title.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final file = File(
        '${dir.path}/$safeTitle.pdf',
      );

      await file.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      print("PDF SAVED AT: ${file.path}");

      if (!mounted) return;

      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e, stackTrace) {
      print("PDF LOAD ERROR: $e");
      print(stackTrace);

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage('Failed to load file');
    }
  }
  Future<void> _downloadOffline() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
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

  Future<void> _saveAnnotations() async {
    if (!widget.isLocal || localPath == null || _savingAnnotations) {
      return;
    }

    try {
      _savingAnnotations = true;

      final List<int> bytes =
      await _pdfController.saveDocument();

      await File(localPath!).writeAsBytes(
        bytes,
        flush: true,
      );

      print("ANNOTATIONS SAVED: $localPath");
    } catch (e) {
      print("ANNOTATION SAVE ERROR: $e");
    } finally {
      _savingAnnotations = false;
    }
  }

  void _setAnnotationMode(PdfAnnotationMode mode) {
    _pdfController.annotationMode = mode;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // MAIN VIEWER LOGIC
  Widget _buildViewer() {
    if (localPath == null) {
      return const Center(child: Text("No file available"));
    }

    print("OPENING FILE: $localPath");

    //  FORCE PDF VIEWER (NO CHECK)
    return SfPdfViewer.file(
      File(localPath!),
      controller: _pdfController,

      onAnnotationAdded: (Annotation annotation) {
        _saveAnnotations();
      },

      onAnnotationEdited: (Annotation annotation) {
        _saveAnnotations();
      },

      onAnnotationRemoved: (Annotation annotation) {
        _saveAnnotations();
      },
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
          // Download button - only for online files
          if (!widget.isLocal)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadOffline,
            ),

          // Annotation tools - only for downloaded files
          if (widget.isLocal)
            PopupMenuButton<String>(
              icon: const Icon(Icons.edit,),
              tooltip: "Annotate",
              onSelected: (value) {
                switch (value) {
                  case 'highlight':
                    _setAnnotationMode(
                      PdfAnnotationMode.highlight,
                    );
                    break;

                  case 'underline':
                    _setAnnotationMode(
                      PdfAnnotationMode.underline,
                    );
                    break;

                  case 'strikethrough':
                    _setAnnotationMode(
                      PdfAnnotationMode.strikethrough,
                    );
                    break;

                  case 'squiggly':
                    _setAnnotationMode(
                      PdfAnnotationMode.squiggly,
                    );
                    break;

                  case 'sticky':
                    _setAnnotationMode(
                      PdfAnnotationMode.stickyNote,
                    );
                    break;

                  case 'none':
                    _setAnnotationMode(
                      PdfAnnotationMode.none,
                    );
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'highlight',
                  child: Row(
                    children: [
                      Icon(Icons.highlight, color: Colors.orange),
                      SizedBox(width: 10),
                      Text("Highlight"),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'underline',
                  child: Row(
                    children: [
                      Icon(Icons.format_underlined, color: Colors.blue),
                      SizedBox(width: 10),
                      Text("Underline"),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'strikethrough',
                  child: Row(
                    children: [
                      Icon(Icons.strikethrough_s, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Strikethrough"),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'squiggly',
                  child: Row(
                    children: [
                      Icon(Icons.text_fields,color: Colors.purple),
                      SizedBox(width: 10),
                      Text("Squiggly"),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: 'sticky',
                  child: Row(
                    children: [
                      Icon(Icons.note_add,color: Colors.amber),
                      SizedBox(width: 10),
                      Text("Sticky Note"),
                    ],
                  ),
                ),

                PopupMenuDivider(),

                PopupMenuItem(
                  value: 'none',
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.grey),
                      SizedBox(width: 10),
                      Text("Stop Annotating"),
                    ],
                  ),
                ),
              ],
            ),

          // Save annotations
          if (widget.isLocal)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: "Save annotations",
              onPressed: _saveAnnotations,
            ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildViewer(),

      // 🤖 AI Button
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🤖 Ask AI
          FloatingActionButton.extended(
            heroTag: "ai",
            backgroundColor: Colors.lightBlue,
            icon: const Icon(Icons.smart_toy),
            label: const Text('Ask AI'),
            onPressed: () {
              if (localPath == null) return;

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
        ],
      ),

    );
  }
}