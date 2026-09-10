import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';

import '../../../../firebase/services/note_fetch_service.dart';

class ResourceListScreen extends StatefulWidget {
  final String university;
  final String department;
  final int semester;
  final String category;

  const ResourceListScreen({
    super.key,
    required this.university,
    required this.department,
    required this.semester,
    required this.category,
  });

  @override
  State<ResourceListScreen> createState() => _ResourceListScreenState();
}

class _ResourceListScreenState extends State<ResourceListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<Map<String, dynamic>> _filterNotes(List<Map<String, dynamic>> notes) {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return notes;
    }

    return notes.where((data) {
      final title = data['title']?.toString().toLowerCase() ?? '';

      final subject = data['subject']?.toString().toLowerCase() ?? '';

      final teacher = data['teacherName']?.toString().toLowerCase() ?? '';

      return title.contains(query) ||
          subject.contains(query) ||
          teacher.contains(query);
    }).toList();
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },

        decoration: InputDecoration(
          hintText: 'Search resources...',
          hintStyle: const TextStyle(color: Colors.black45),

          prefixIcon: const Icon(Icons.search, color: Colors.black54),

          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                )
              : null,

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESOURCE CARD
  // ============================================================

  Widget _buildResourceCard(BuildContext context, Map<String, dynamic> data) {
    final String teacherName = data['teacherName'] ?? 'Unknown Teacher';

    final String fileUrl = data['fileUrl'] ?? '';

    final String title = data['title'] ?? 'Untitled Resource';

    final String subject = data['subject'] ?? '';

    final bool isPdf = fileUrl.toLowerCase().endsWith('.pdf');

    return Card(
      elevation: 2,

      margin: const EdgeInsets.symmetric(vertical: 8),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

        // ======================================================
        // FILE ICON
        // ======================================================
        leading: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),

          child: Icon(
            isPdf ? Icons.picture_as_pdf : Icons.image,

            color: isPdf ? Colors.red : Colors.blue,

            size: 26,
          ),
        ),

        // ======================================================
        // TITLE
        // ======================================================
        title: Text(
          title,

          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),

        // ======================================================
        // DETAILS
        // ======================================================
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Teacher: $teacherName',

                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),

              const SizedBox(height: 2),

              Text(
                'Subject: $subject',

                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),

        trailing: const Icon(
          Icons.open_in_new,
          color: Colors.black45,
          size: 20,
        ),

        // ======================================================
        // OPEN RESOURCE
        // ======================================================
        onTap: () {
          if (fileUrl.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("File not available")));

            return;
          }

          debugPrint("OPENING FILE URL: $fileUrl");

          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (_) => FileViewerScreen(title: title, fileUrl: fileUrl),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        backgroundColor: Colors.lightBlue,

        foregroundColor: Colors.white,

        elevation: 0,

        title: Text(
          '${widget.category} • '
          'Semester ${widget.semester}',
        ),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NoteFetchService.getNotes(
          university: widget.university,
          department: widget.department,
          semester: widget.semester,
          category: widget.category,
        ),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading resources: "
                "${snapshot.error}",
              ),
            );
          }

          final notes = snapshot.data ?? [];

          // ====================================================
          // NO RESOURCES AT ALL
          // ====================================================

          if (notes.isEmpty) {
            return const Center(
              child: Text(
                'No resources available',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final filteredNotes = _filterNotes(notes);

          return Column(
            children: [
              // ==================================================
              // SEARCH
              // ==================================================
              _buildSearchBar(),

              // ==================================================
              // RESULTS COUNT
              // ==================================================
              if (_searchText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),

                  child: Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      '${filteredNotes.length} '
                      'resource'
                      '${filteredNotes.length == 1 ? '' : 's'} found',

                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),

              // ==================================================
              // RESULTS
              // ==================================================
              Expanded(
                child: filteredNotes.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching resources found',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

                        itemCount: filteredNotes.length,

                        itemBuilder: (_, i) {
                          return _buildResourceCard(context, filteredNotes[i]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
