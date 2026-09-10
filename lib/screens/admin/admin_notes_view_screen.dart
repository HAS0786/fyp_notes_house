import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/config.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/resourcesscreens/pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminNotesViewScreen extends StatefulWidget {
  const AdminNotesViewScreen({super.key});

  @override
  State<AdminNotesViewScreen> createState() => _AdminNotesViewScreenState();
}

class _AdminNotesViewScreenState extends State<AdminNotesViewScreen> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  // ============================================================
  // FILTER STATE
  // ============================================================

  String selectedUniversity = 'All Universities';
  String selectedLocation = 'All Locations';
  String selectedDepartment = 'All Departments';
  String selectedSemester = 'All Semesters';
  String selectedCategory = 'All Categories';
  String selectedStatus = 'All Status';
  String selectedDateFilter = 'All Dates';

  DateTime? selectedDate;
  DateTime? customStartDate;
  DateTime? customEndDate;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(Map<String, dynamic> note) {
    final search = _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return true;
    }

    final searchableValues = <String>[
      note['title']?.toString() ?? '',
      note['subject']?.toString() ?? '',
      note['teacherName']?.toString() ?? '',
      note['university']?.toString() ?? '',
      note['department']?.toString() ?? '',
      note['category']?.toString() ?? '',
      note['location']?.toString() ?? '',
    ];

    return searchableValues.any(
      (value) => value.toLowerCase().contains(search),
    );
  }

  // ============================================================
  // UNIVERSITY
  // ============================================================

  bool _matchesUniversity(Map<String, dynamic> note) {
    if (selectedUniversity == 'All Universities') {
      return true;
    }

    return note['university']?.toString() == selectedUniversity;
  }

  // ============================================================
  // LOCATION
  // ============================================================

  bool _matchesLocation(Map<String, dynamic> note) {
    if (selectedLocation == 'All Locations') {
      return true;
    }

    return note['location']?.toString() == selectedLocation;
  }

  // ============================================================
  // DEPARTMENT
  // ============================================================

  bool _matchesDepartment(Map<String, dynamic> note) {
    if (selectedDepartment == 'All Departments') {
      return true;
    }

    return note['department']?.toString() == selectedDepartment;
  }

  // ============================================================
  // SEMESTER
  // ============================================================

  bool _matchesSemester(Map<String, dynamic> note) {
    if (selectedSemester == 'All Semesters') {
      return true;
    }

    return note['semester']?.toString() == selectedSemester;
  }

  // ============================================================
  // CATEGORY
  // ============================================================

  bool _matchesCategory(Map<String, dynamic> note) {
    if (selectedCategory == 'All Categories') {
      return true;
    }

    return note['category']?.toString() == selectedCategory;
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool _matchesStatus(Map<String, dynamic> note) {
    if (selectedStatus == 'All Status') {
      return true;
    }

    return note['status']?.toString().toLowerCase() ==
        selectedStatus.toLowerCase();
  }

  // ============================================================
  // DATE
  // ============================================================

  bool _matchesDate(Map<String, dynamic> note) {
    if (selectedDateFilter == 'All Dates') {
      return true;
    }

    final createdAt = note['createdAt'];

    if (createdAt is! Timestamp) {
      return false;
    }

    final date = createdAt.toDate();

    final dateOnly = DateTime(date.year, date.month, date.day);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    switch (selectedDateFilter) {
      case 'Today':
        return dateOnly == today;

      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));

        return dateOnly == yesterday;

      case 'Last 7 Days':
        final start = today.subtract(const Duration(days: 6));

        return !dateOnly.isBefore(start) && !dateOnly.isAfter(today);

      case 'Last 28 Days':
        final start = today.subtract(const Duration(days: 27));

        return !dateOnly.isBefore(start) && !dateOnly.isAfter(today);

      case 'Custom Date':
        if (selectedDate == null) {
          return true;
        }

        final selected = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );

        return dateOnly == selected;

      case 'Custom Range':
        if (customStartDate == null || customEndDate == null) {
          return true;
        }

        final start = DateTime(
          customStartDate!.year,
          customStartDate!.month,
          customStartDate!.day,
        );

        final end = DateTime(
          customEndDate!.year,
          customEndDate!.month,
          customEndDate!.day,
        );

        return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);

      default:
        return true;
    }
  }

  // ============================================================
  // ALL FILTERS
  // ============================================================

  bool _matchesAllFilters(Map<String, dynamic> note) {
    return _matchesSearch(note) &&
        _matchesUniversity(note) &&
        _matchesLocation(note) &&
        _matchesDepartment(note) &&
        _matchesSemester(note) &&
        _matchesCategory(note) &&
        _matchesStatus(note) &&
        _matchesDate(note);
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Note Date',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDateFilter = 'Custom Date';

      selectedDate = picked;

      customStartDate = null;

      customEndDate = null;
    });
  }

  // ============================================================
  // CUSTOM RANGE
  // ============================================================

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Note Date Range',
      saveText: 'Apply',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDateFilter = 'Custom Range';

      customStartDate = picked.start;

      customEndDate = picked.end;

      selectedDate = null;
    });
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Future<void> _selectDateFilter() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.70,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Filter by Date',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),

                _dateOption(context, 'All Dates', Icons.history),

                _dateOption(context, 'Today', Icons.today),

                _dateOption(context, 'Yesterday', Icons.event),

                _dateOption(context, 'Last 7 Days', Icons.date_range),

                _dateOption(context, 'Last 28 Days', Icons.calendar_month),

                _dateOption(context, 'Custom Date', Icons.calendar_today),

                _dateOption(context, 'Custom Range', Icons.date_range_outlined),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result == 'Custom Date') {
      await _selectCustomDate();
      return;
    }

    if (result == 'Custom Range') {
      await _selectCustomRange();
      return;
    }

    setState(() {
      selectedDateFilter = result;

      selectedDate = null;

      customStartDate = null;

      customEndDate = null;
    });
  }

  // ============================================================
  // DATE OPTION
  // ============================================================

  Widget _dateOption(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.lightBlue),

      title: Text(title),

      trailing: selectedDateFilter == title
          ? const Icon(Icons.check, color: Colors.lightBlue)
          : null,

      onTap: () {
        Navigator.pop(context, title);
      },
    );
  }

  // ============================================================
  // SIMPLE FILTER
  // ============================================================

  Future<void> _selectSimpleFilter(
    String filterType,
    List<String> options,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.70,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Filter by $filterType',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...options.map((option) {
                  final selected = _getCurrentFilter(filterType) == option;

                  return ListTile(
                    leading: Icon(
                      _getFilterIcon(filterType),
                      color: Colors.lightBlue,
                    ),

                    title: Text(option),

                    trailing: selected
                        ? const Icon(Icons.check, color: Colors.lightBlue)
                        : null,

                    onTap: () {
                      Navigator.pop(context, option);
                    },
                  );
                }),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      switch (filterType) {
        case 'University':
          selectedUniversity = result;
          break;

        case 'Location':
          selectedLocation = result;
          break;

        case 'Department':
          selectedDepartment = result;
          break;

        case 'Semester':
          selectedSemester = result;
          break;

        case 'Category':
          selectedCategory = result;
          break;

        case 'Status':
          selectedStatus = result;
          break;
      }
    });
  }

  // ============================================================
  // CURRENT FILTER
  // ============================================================

  String _getCurrentFilter(String filterType) {
    switch (filterType) {
      case 'University':
        return selectedUniversity;

      case 'Location':
        return selectedLocation;

      case 'Department':
        return selectedDepartment;

      case 'Semester':
        return selectedSemester;

      case 'Category':
        return selectedCategory;

      case 'Status':
        return selectedStatus;

      default:
        return '';
    }
  }

  // ============================================================
  // FILTER ICON
  // ============================================================

  IconData _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'University':
        return Icons.school_outlined;

      case 'Location':
        return Icons.location_on_outlined;

      case 'Department':
        return Icons.domain_outlined;

      case 'Semester':
        return Icons.menu_book_outlined;

      case 'Category':
        return Icons.category_outlined;

      case 'Status':
        return Icons.info_outline;

      default:
        return Icons.filter_alt_outlined;
    }
  }

  // ============================================================
  // GET OPTIONS FROM FIRESTORE
  // ============================================================

  List<String> _getOptions(
    List<QueryDocumentSnapshot> docs,
    String field,
    String allLabel,
  ) {
    final Set<String> values = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final value = data[field];

      if (value != null && value.toString().trim().isNotEmpty) {
        values.add(value.toString());
      }
    }

    final result = values.toList()..sort();

    return [allLabel, ...result];
  }

  // ============================================================
  // SEMESTER OPTIONS
  // ============================================================

  List<String> _getSemesterOptions(List<QueryDocumentSnapshot> docs) {
    final Set<String> values = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final value = data['semester'];

      if (value != null) {
        values.add(value.toString());
      }
    }

    final result = values.toList();

    result.sort(
      (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
    );

    return ['All Semesters', ...result.map((e) => 'Semester $e')];
  }

  // ============================================================
  // FIX SEMESTER MATCH
  // ============================================================

  bool _matchesSemesterFixed(Map<String, dynamic> note) {
    if (selectedSemester == 'All Semesters') {
      return true;
    }

    final semester = selectedSemester.replaceFirst('Semester ', '');

    return note['semester']?.toString() == semester;
  }

  // ============================================================
  // FILTER MENU
  // ============================================================

  Future<void> _openFilterMenu(List<QueryDocumentSnapshot> docs) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Filter Notes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                _filterMenuItem(context, 'University', selectedUniversity, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'University',
                    _getOptions(docs, 'university', 'All Universities'),
                  );
                }),

                _filterMenuItem(context, 'Location', selectedLocation, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'Location',
                    _getOptions(docs, 'location', 'All Locations'),
                  );
                }),

                _filterMenuItem(context, 'Department', selectedDepartment, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'Department',
                    _getOptions(docs, 'department', 'All Departments'),
                  );
                }),

                _filterMenuItem(context, 'Semester', selectedSemester, () {
                  Navigator.pop(context);

                  _selectSimpleFilter('Semester', _getSemesterOptions(docs));
                }),

                _filterMenuItem(context, 'Category', selectedCategory, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'Category',
                    _getOptions(docs, 'category', 'All Categories'),
                  );
                }),

                _filterMenuItem(context, 'Status', selectedStatus, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'Status',
                    _getOptions(docs, 'status', 'All Status'),
                  );
                }),

                _filterMenuItem(context, 'Date', _getDateLabel(), () {
                  Navigator.pop(context);

                  _selectDateFilter();
                }),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTER MENU ITEM
  // ============================================================

  Widget _filterMenuItem(
    BuildContext context,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(_getFilterIcon(title), color: Colors.lightBlue),

      title: Text(title),

      subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),

      trailing: const Icon(Icons.chevron_right),

      onTap: onTap,
    );
  }

  // ============================================================
  // DATE LABEL
  // ============================================================

  String _getDateLabel() {
    if (selectedDateFilter == 'Custom Date' && selectedDate != null) {
      return '${selectedDate!.day}/'
          '${selectedDate!.month}/'
          '${selectedDate!.year}';
    }

    if (selectedDateFilter == 'Custom Range' &&
        customStartDate != null &&
        customEndDate != null) {
      return '${customStartDate!.day}/'
          '${customStartDate!.month}/'
          '${customStartDate!.year}'
          ' - '
          '${customEndDate!.day}/'
          '${customEndDate!.month}/'
          '${customEndDate!.year}';
    }

    return selectedDateFilter;
  }

  // ============================================================
  // ACTIVE FILTER COUNT
  // ============================================================

  int _activeFilterCount() {
    int count = 0;

    if (_searchController.text.trim().isNotEmpty) {
      count++;
    }

    if (selectedUniversity != 'All Universities') {
      count++;
    }

    if (selectedLocation != 'All Locations') {
      count++;
    }

    if (selectedDepartment != 'All Departments') {
      count++;
    }

    if (selectedSemester != 'All Semesters') {
      count++;
    }

    if (selectedCategory != 'All Categories') {
      count++;
    }

    if (selectedStatus != 'All Status') {
      count++;
    }

    if (selectedDateFilter != 'All Dates') {
      count++;
    }

    return count;
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  void _clearAllFilters() {
    _searchController.clear();

    setState(() {
      selectedUniversity = 'All Universities';

      selectedLocation = 'All Locations';

      selectedDepartment = 'All Departments';

      selectedSemester = 'All Semesters';

      selectedCategory = 'All Categories';

      selectedStatus = 'All Status';

      selectedDateFilter = 'All Dates';

      selectedDate = null;

      customStartDate = null;

      customEndDate = null;
    });

    _searchFocusNode.requestFocus();
  }

  // ============================================================
  // OPEN FILE
  // ============================================================

  Future<void> openFile(BuildContext context, String url, String title) async {
    if (kIsWeb) {
      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        throw "Could not open file";
      }

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerScreen(fileUrl: url, title: title),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),

      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),

          const SizedBox(width: 6),

          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
// ============================================================
// DELETE NOTE
// ============================================================

  Future<bool> deleteNote(String noteId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return false;
      }

      final token = await user.getIdToken();

      final response = await http.delete(
        Uri.parse("$baseUrl/delete-note/$noteId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("Delete response: ${response.statusCode}");
      debugPrint(response.body);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Delete note error: $e");
      return false;
    }
  }

// ============================================================
// CONFIRM DELETE
// ============================================================

  Future<bool> confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Note"),
          content: const Text(
            "Are you sure you want to permanently delete this note?\n\n"
                "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
  // ============================================================
  // NOTE CARD
  // ============================================================

  Widget buildCard(BuildContext context, DocumentSnapshot doc) {
    final note = doc.data() as Map<String, dynamic>;

    String createdDate = '';

    final createdAt = note['createdAt'];

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      createdDate =
          '${date.day}/${date.month}/${date.year}'
          ' • '
          '${date.hour}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            note['title'] ?? 'No Title',

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildInfoRow(Icons.book, note['subject'] ?? 'Unknown Subject'),

          buildInfoRow(
            Icons.school,
            note['university'] ?? 'Unknown University',
          ),

          buildInfoRow(
            Icons.location_on,
            note['location'] ?? 'Unknown Location',
          ),

          buildInfoRow(
            Icons.domain,
            note['department'] ?? 'Unknown Department',
          ),

          buildInfoRow(
            Icons.menu_book,
            "Semester ${note['semester'] ?? 'N/A'}",
          ),

          buildInfoRow(Icons.category, note['category'] ?? 'Unknown Category'),

          buildInfoRow(
            Icons.person,
            "Teacher: ${note['teacherName'] ?? 'Unknown'}",
          ),

          buildInfoRow(
            Icons.info_outline,
            "Status: ${note['status'] ?? 'Unknown'}",
          ),

          if (createdDate.isNotEmpty)
            buildInfoRow(Icons.calendar_today, createdDate),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),

              onPressed: () {
                final url = note['fileUrl']?.toString();

                final name = note['title']?.toString() ?? 'Note';

                if (url != null && url.isNotEmpty) {
                  openFile(context, url, name);
                }
              },

              icon: const Icon(Icons.picture_as_pdf),

              label: const Text("View PDF"),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        title: const Text("All Notes"),

        backgroundColor: Colors.lightBlue,

        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("notes").snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Unable to load notes.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final allNotes = snapshot.data?.docs ?? [];

          if (allNotes.isEmpty) {
            return const Center(
              child: Text(
                "No notes available.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,

            builder: (context, searchValue, _) {
              final notes = allNotes.where((doc) {
                final note = doc.data() as Map<String, dynamic>;

                return _matchesSearch(note) &&
                    _matchesUniversity(note) &&
                    _matchesLocation(note) &&
                    _matchesDepartment(note) &&
                    _matchesSemesterFixed(note) &&
                    _matchesCategory(note) &&
                    _matchesStatus(note) &&
                    _matchesDate(note);
              }).toList();

              return Column(
                children: [
                  // ==================================================
                  // SEARCH BOX
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),

                    child: TextField(
                      controller: _searchController,

                      focusNode: _searchFocusNode,

                      keyboardType: TextInputType.text,

                      decoration: InputDecoration(
                        hintText: 'Search title, subject, teacher...',

                        prefixIcon: const Icon(Icons.search),

                        suffixIcon: searchValue.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();

                                  _searchFocusNode.requestFocus();
                                },
                              )
                            : null,

                        filled: true,

                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.lightBlue,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // FILTER BUTTON + CLEAR
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _openFilterMenu(
                              allNotes.cast<QueryDocumentSnapshot>(),
                            );
                          },

                          icon: const Icon(Icons.filter_alt_outlined, size: 18),

                          label: Text(
                            _activeFilterCount() == 0
                                ? 'Filters'
                                : 'Filters (${_activeFilterCount()})',
                          ),
                        ),

                        const Spacer(),

                        if (_activeFilterCount() > 0)
                          TextButton(
                            onPressed: _clearAllFilters,

                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ==================================================
                  // ACTIVE FILTER SUMMARY
                  // ==================================================
                  if (_activeFilterCount() > 0)
                    Container(
                      width: double.infinity,

                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withOpacity(0.08),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Text(
                        '${notes.length} matching note${notes.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // ==================================================
                  // NO RESULTS
                  // ==================================================
                  if (notes.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.search_off,
                              size: 50,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 10),

                            Text(
                              "No matching notes found.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // ==================================================
                  // NOTES
                  // ==================================================
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),

                        itemCount: notes.length,

                        itemBuilder: (context, index) {
                          final doc = notes[index];

                          return Dismissible(
                            key: ValueKey(doc.id),

                            direction: DismissDirection.endToStart,

                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.only(right: 24),

                              alignment: Alignment.centerRight,

                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),

                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),

                            confirmDismiss: (direction) async {
                              // Show confirmation first
                              final confirmed = await confirmDelete(context);

                              if (!confirmed) {
                                return false;
                              }

                              // Call backend
                              final success = await deleteNote(doc.id);

                              if (!success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Failed to delete note"),
                                    ),
                                  );
                                }

                                return false;
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Note deleted successfully"),
                                  ),
                                );
                              }

                              return true;
                            },

                            child: buildCard(context, doc),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
