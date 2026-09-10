import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp_ui_design/screens/notes/allnotes/teacherdraft/quiz_viewer_screen.dart';

class AdminQuizViewScreen extends StatefulWidget {
  const AdminQuizViewScreen({super.key});

  @override
  State<AdminQuizViewScreen> createState() => _AdminQuizViewScreenState();
}

class _AdminQuizViewScreenState extends State<AdminQuizViewScreen> {
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
  String selectedTeacher = 'All Teachers';
  String selectedVisibility = 'All Visibility';
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

  bool _matchesSearch(Map<String, dynamic> quiz) {
    final search = _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return true;
    }

    final searchableValues = <String>[
      quiz['subject']?.toString() ?? '',
      quiz['teacherName']?.toString() ?? '',
      quiz['university']?.toString() ?? '',
      quiz['department']?.toString() ?? '',
      quiz['location']?.toString() ?? '',
    ];

    return searchableValues.any(
      (value) => value.toLowerCase().contains(search),
    );
  }

  // ============================================================
  // UNIVERSITY
  // ============================================================

  bool _matchesUniversity(Map<String, dynamic> quiz) {
    if (selectedUniversity == 'All Universities') {
      return true;
    }

    return quiz['university']?.toString() == selectedUniversity;
  }

  // ============================================================
  // LOCATION
  // ============================================================

  bool _matchesLocation(Map<String, dynamic> quiz) {
    if (selectedLocation == 'All Locations') {
      return true;
    }

    return quiz['location']?.toString() == selectedLocation;
  }

  // ============================================================
  // DEPARTMENT
  // ============================================================

  bool _matchesDepartment(Map<String, dynamic> quiz) {
    if (selectedDepartment == 'All Departments') {
      return true;
    }

    return quiz['department']?.toString() == selectedDepartment;
  }

  // ============================================================
  // SEMESTER
  // ============================================================

  bool _matchesSemester(Map<String, dynamic> quiz) {
    if (selectedSemester == 'All Semesters') {
      return true;
    }

    final semester = selectedSemester.replaceFirst('Semester ', '');

    return quiz['semester']?.toString() == semester;
  }

  // ============================================================
  // TEACHER
  // ============================================================

  bool _matchesTeacher(Map<String, dynamic> quiz) {
    if (selectedTeacher == 'All Teachers') {
      return true;
    }

    return quiz['teacherName']?.toString() == selectedTeacher;
  }

  // ============================================================
  // VISIBILITY
  // ============================================================

  bool _matchesVisibility(Map<String, dynamic> quiz) {
    if (selectedVisibility == 'All Visibility') {
      return true;
    }

    final isPublic = quiz['isPublic'] == true;

    if (selectedVisibility == 'Public') {
      return isPublic;
    }

    if (selectedVisibility == 'Private') {
      return !isPublic;
    }

    return true;
  }

  // ============================================================
  // DATE
  // ============================================================

  bool _matchesDate(Map<String, dynamic> quiz) {
    if (selectedDateFilter == 'All Dates') {
      return true;
    }

    final createdAt = quiz['createdAt'];

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

  bool _matchesAllFilters(Map<String, dynamic> quiz) {
    return _matchesSearch(quiz) &&
        _matchesUniversity(quiz) &&
        _matchesLocation(quiz) &&
        _matchesDepartment(quiz) &&
        _matchesSemester(quiz) &&
        _matchesTeacher(quiz) &&
        _matchesVisibility(quiz) &&
        _matchesDate(quiz);
  }

  // ============================================================
  // CUSTOM DATE
  // ============================================================

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Quiz Date',
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
      helpText: 'Select Quiz Date Range',
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

        case 'Teacher':
          selectedTeacher = result;
          break;

        case 'Visibility':
          selectedVisibility = result;
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

      case 'Teacher':
        return selectedTeacher;

      case 'Visibility':
        return selectedVisibility;

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

      case 'Teacher':
        return Icons.person_outline;

      case 'Visibility':
        return Icons.visibility_outlined;

      default:
        return Icons.filter_alt_outlined;
    }
  }

  // ============================================================
  // GET OPTIONS
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
                    'Filter Quizzes',
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

                _filterMenuItem(context, 'Teacher', selectedTeacher, () {
                  Navigator.pop(context);

                  _selectSimpleFilter(
                    'Teacher',
                    _getOptions(docs, 'teacherName', 'All Teachers'),
                  );
                }),

                _filterMenuItem(context, 'Visibility', selectedVisibility, () {
                  Navigator.pop(context);

                  _selectSimpleFilter('Visibility', const [
                    'All Visibility',
                    'Public',
                    'Private',
                  ]);
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

    if (selectedTeacher != 'All Teachers') {
      count++;
    }

    if (selectedVisibility != 'All Visibility') {
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

      selectedTeacher = 'All Teachers';

      selectedVisibility = 'All Visibility';

      selectedDateFilter = 'All Dates';

      selectedDate = null;

      customStartDate = null;

      customEndDate = null;
    });

    _searchFocusNode.requestFocus();
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

          const SizedBox(width: 7),

          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // ============================================================
  // QUIZ CARD
  // ============================================================

  Widget buildQuizCard(BuildContext context, DocumentSnapshot doc) {
    final quiz = doc.data() as Map<String, dynamic>;

    final questions = quiz['questions'] as List? ?? [];

    String createdDate = '';

    final createdAt = quiz['createdAt'];

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      createdDate =
          '${date.day}/${date.month}/${date.year}'
          ' • '
          '${date.hour}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    final isPublic = quiz['isPublic'] == true;

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
          // SUBJECT
          Text(
            quiz['subject'] ?? 'Untitled Quiz',

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          buildInfoRow(
            Icons.school,
            quiz['university'] ?? 'Unknown University',
          ),

          buildInfoRow(
            Icons.location_on,
            quiz['location'] ?? 'Unknown Location',
          ),

          buildInfoRow(
            Icons.domain,
            quiz['department'] ?? 'Unknown Department',
          ),

          buildInfoRow(
            Icons.menu_book,
            "Semester ${quiz['semester'] ?? 'N/A'}",
          ),

          buildInfoRow(
            Icons.person,
            "Teacher: ${quiz['teacherName'] ?? 'Unknown'}",
          ),

          buildInfoRow(Icons.quiz, "${questions.length} Questions"),

          buildInfoRow(
            isPublic ? Icons.public : Icons.lock_outline,
            isPublic ? "Visibility: Public" : "Visibility: Private",
          ),

          if (createdDate.isNotEmpty)
            buildInfoRow(Icons.calendar_today, createdDate),

          const SizedBox(height: 12),

          // VIEW QUIZ
          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizViewerScreen(questions: questions),
                  ),
                );
              },

              icon: const Icon(Icons.visibility),

              label: const Text("View Quiz"),
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
        title: const Text("All Quizzes"),

        backgroundColor: Colors.lightBlue,

        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("quizzes").snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Unable to load quizzes.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final allQuizzes = snapshot.data?.docs ?? [];

          if (allQuizzes.isEmpty) {
            return const Center(
              child: Text(
                "No quizzes available.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,

            builder: (context, searchValue, _) {
              final quizzes = allQuizzes.where((doc) {
                final quiz = doc.data() as Map<String, dynamic>;

                return _matchesAllFilters(quiz);
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
                        hintText: 'Search subject, teacher...',

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
                  // FILTER BUTTON
                  // ==================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _openFilterMenu(
                              allQuizzes.cast<QueryDocumentSnapshot>(),
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
                  // RESULT COUNT
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
                        '${quizzes.length} matching quiz${quizzes.length == 1 ? '' : 'zes'}',

                        style: const TextStyle(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // ==================================================
                  // NO RESULTS
                  // ==================================================
                  if (quizzes.isEmpty)
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
                              "No matching quizzes found.",
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
                  // QUIZ LIST
                  // ==================================================
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),

                        itemCount: quizzes.length,

                        itemBuilder: (context, index) {
                          return buildQuizCard(context, quizzes[index]);
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
