import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCollectionViewScreen extends StatefulWidget {
  final String title;
  final Query query;
  final String type;

  const AdminCollectionViewScreen({
    super.key,
    required this.title,
    required this.query,
    required this.type,
  });

  @override
  State<AdminCollectionViewScreen> createState() =>
      _AdminCollectionViewScreenState();
}

class _AdminCollectionViewScreenState
    extends State<AdminCollectionViewScreen> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  final FocusNode _searchFocusNode =
  FocusNode();

  // ============================================================
  // FILTER STATE
  // ============================================================

  String selectedRole = 'All Roles';
  String selectedStatus = 'All Status';

  String selectedLocation = 'All Locations';
  String selectedUniversity = 'All Universities';
  String selectedDepartment = 'All Departments';

  String selectedDateFilter = 'All Dates';

  DateTime? selectedDate;
  DateTime? customStartDate;
  DateTime? customEndDate;

  // ============================================================
  // TYPE CHECKS
  // ============================================================

  bool get isUsers =>
      widget.type == 'users';

  bool get isStudents =>
      widget.type == 'students';

  bool get isTeachers =>
      widget.type == 'teachers';

  bool get isUniversities =>
      widget.type == 'universities';

  bool get isDepartments =>
      widget.type == 'departments';

  bool get isCourses =>
      widget.type == 'courses';

  bool get supportsDateFilter =>
      isUsers ||
          isStudents ||
          isTeachers ||
          isCourses;

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

  bool _matchesSearch(
      Map<String, dynamic> data,
      ) {
    final search =
    _searchController.text.trim().toLowerCase();

    if (search.isEmpty) {
      return true;
    }

    final values = <String>[
      data['name']?.toString() ?? '',
      data['displayName']?.toString() ?? '',
      data['email']?.toString() ?? '',
      data['subject']?.toString() ?? '',
      data['course']?.toString() ?? '',
      data['department']?.toString() ?? '',
      data['university']?.toString() ?? '',
      data['title']?.toString() ?? '',
    ];

    return values.any(
          (value) =>
          value.toLowerCase().contains(search),
    );
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  bool _matchesDate(
      Map<String, dynamic> data,
      ) {
    if (!supportsDateFilter ||
        selectedDateFilter == 'All Dates') {
      return true;
    }

    final createdAt = data['createdAt'];

    if (createdAt is! Timestamp) {
      return false;
    }

    final date = createdAt.toDate();

    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    switch (selectedDateFilter) {
      case 'Today':
        return dateOnly == today;

      case 'Yesterday':
        final yesterday =
        today.subtract(
          const Duration(days: 1),
        );

        return dateOnly == yesterday;

      case 'Last 7 Days':
        final start =
        today.subtract(
          const Duration(days: 6),
        );

        return !dateOnly.isBefore(start) &&
            !dateOnly.isAfter(today);

      case 'Last 28 Days':
        final start =
        today.subtract(
          const Duration(days: 27),
        );

        return !dateOnly.isBefore(start) &&
            !dateOnly.isAfter(today);

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
        if (customStartDate == null ||
            customEndDate == null) {
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

        return !dateOnly.isBefore(start) &&
            !dateOnly.isAfter(end);

      default:
        return true;
    }
  }

  // ============================================================
  // ROLE FILTER
  // ============================================================

  bool _matchesRole(
      Map<String, dynamic> data,
      ) {
    if (!isUsers ||
        selectedRole == 'All Roles') {
      return true;
    }

    final role =
    data['role']?.toString().toLowerCase();

    switch (selectedRole) {
      case 'Student':
        return role == 'student';

      case 'Teacher':
        return role == 'teacher';

      case 'Admin':
        return role == 'admin';

      default:
        return true;
    }
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  bool _matchesStatus(
      Map<String, dynamic> data,
      ) {
    if (!(isUsers || isStudents || isTeachers) ||
        selectedStatus == 'All Status') {
      return true;
    }

    return data['status']
        ?.toString()
        .toLowerCase() ==
        selectedStatus.toLowerCase();
  }

  // ============================================================
  // LOCATION FILTER
  // ============================================================

  bool _matchesLocation(
      Map<String, dynamic> data,
      ) {
    if (!(isUniversities || isDepartments) ||
        selectedLocation == 'All Locations') {
      return true;
    }

    final location = data['location'];

    // Universities have location as ARRAY
    if (location is List) {
      return location.any(
            (item) =>
        item.toString() ==
            selectedLocation,
      );
    }

    // Departments have location as STRING
    return location?.toString() ==
        selectedLocation;
  }

  // ============================================================
  // UNIVERSITY FILTER
  // ============================================================

  bool _matchesUniversity(
      Map<String, dynamic> data,
      ) {
    if (!isDepartments ||
        selectedUniversity == 'All Universities') {
      return true;
    }

    return data['university']
        ?.toString() ==
        selectedUniversity;
  }

  // ============================================================
  // DEPARTMENT FILTER
  // ============================================================

  bool _matchesDepartment(
      Map<String, dynamic> data,
      ) {
    if (!isCourses ||
        selectedDepartment == 'All Departments') {
      return true;
    }

    return data['department']
        ?.toString() ==
        selectedDepartment;
  }

  // ============================================================
  // ALL FILTERS
  // ============================================================

  bool _matchesAllFilters(
      Map<String, dynamic> data,
      ) {
    return _matchesSearch(data) &&
        _matchesDate(data) &&
        _matchesRole(data) &&
        _matchesStatus(data) &&
        _matchesLocation(data) &&
        _matchesUniversity(data) &&
        _matchesDepartment(data);
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
      selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Date',
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
    final picked =
    await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Date Range',
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
  // DATE FILTER SHEET
  // ============================================================

  Future<void> _selectDateFilter() async {
    final result =
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.70,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Filter by Date',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                _sheetOption(
                  context,
                  'All Dates',
                  Icons.history,
                ),

                _sheetOption(
                  context,
                  'Today',
                  Icons.today,
                ),

                _sheetOption(
                  context,
                  'Yesterday',
                  Icons.event,
                ),

                _sheetOption(
                  context,
                  'Last 7 Days',
                  Icons.date_range,
                ),

                _sheetOption(
                  context,
                  'Last 28 Days',
                  Icons.calendar_month,
                ),

                _sheetOption(
                  context,
                  'Custom Date',
                  Icons.calendar_today,
                ),

                _sheetOption(
                  context,
                  'Custom Range',
                  Icons.date_range_outlined,
                ),

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
  // SIMPLE FILTER SHEET
  // ============================================================

  Future<void> _selectSimpleFilter(
      String filterType,
      List<String> options,
      ) async {
    final result =
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.70,
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
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                ...options.map(
                      (option) {
                    final isSelected =
                        _getCurrentFilterValue(
                          filterType,
                        ) ==
                            option;

                    return ListTile(
                      leading: Icon(
                        _getFilterIcon(
                          filterType,
                        ),
                        color:
                        Colors.lightBlue,
                      ),
                      title:
                      Text(option),
                      trailing:
                      isSelected
                          ? const Icon(
                        Icons.check,
                        color:
                        Colors.lightBlue,
                      )
                          : null,
                      onTap: () {
                        Navigator.pop(
                          context,
                          option,
                        );
                      },
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),
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
        case 'Role':
          selectedRole = result;
          break;

        case 'Status':
          selectedStatus = result;
          break;

        case 'Location':
          selectedLocation = result;
          break;

        case 'University':
          selectedUniversity = result;
          break;

        case 'Department':
          selectedDepartment = result;
          break;
      }
    });
  }

  // ============================================================
  // CURRENT FILTER VALUE
  // ============================================================

  String _getCurrentFilterValue(
      String filterType,
      ) {
    switch (filterType) {
      case 'Role':
        return selectedRole;

      case 'Status':
        return selectedStatus;

      case 'Location':
        return selectedLocation;

      case 'University':
        return selectedUniversity;

      case 'Department':
        return selectedDepartment;

      default:
        return '';
    }
  }

  // ============================================================
  // FILTER ICON
  // ============================================================

  IconData _getFilterIcon(
      String filterType,
      ) {
    switch (filterType) {
      case 'Role':
        return Icons.people_outline;

      case 'Status':
        return Icons.verified_outlined;

      case 'Location':
        return Icons.location_on_outlined;

      case 'University':
        return Icons.school_outlined;

      case 'Department':
        return Icons.domain_outlined;

      default:
        return Icons.filter_alt_outlined;
    }
  }

  // ============================================================
  // GENERIC SHEET OPTION
  // ============================================================

  Widget _sheetOption(
      BuildContext context,
      String title,
      IconData icon,
      ) {
    final bool selected =
        selectedDateFilter == title;

    return ListTile(
      leading: Icon(
        icon,
        color: Colors.lightBlue,
      ),
      title: Text(title),
      trailing: selected
          ? const Icon(
        Icons.check,
        color: Colors.lightBlue,
      )
          : null,
      onTap: () {
        Navigator.pop(
          context,
          title,
        );
      },
    );
  }

  // ============================================================
  // GET LOCATIONS
  // ============================================================

  List<String> _getLocations(
      List<QueryDocumentSnapshot> docs,
      ) {
    final Set<String> locations = {};

    for (final doc in docs) {
      final data =
      doc.data()
      as Map<String, dynamic>;

      final location =
      data['location'];

      if (location is List) {
        for (final item in location) {
          locations.add(
            item.toString(),
          );
        }
      } else if (location != null) {
        locations.add(
          location.toString(),
        );
      }
    }

    final result =
    locations.toList()..sort();

    return [
      'All Locations',
      ...result,
    ];
  }

  // ============================================================
  // GET UNIVERSITIES
  // ============================================================

  List<String> _getUniversities(
      List<QueryDocumentSnapshot> docs,
      ) {
    final Set<String> universities = {};

    for (final doc in docs) {
      final data =
      doc.data()
      as Map<String, dynamic>;

      final value =
      data['university'];

      if (value != null &&
          value.toString().isNotEmpty) {
        universities.add(
          value.toString(),
        );
      }
    }

    final result =
    universities.toList()..sort();

    return [
      'All Universities',
      ...result,
    ];
  }

  // ============================================================
  // GET DEPARTMENTS
  // ============================================================

  List<String> _getDepartments(
      List<QueryDocumentSnapshot> docs,
      ) {
    final Set<String> departments = {};

    for (final doc in docs) {
      final data =
      doc.data()
      as Map<String, dynamic>;

      final value =
      data['department'];

      if (value != null &&
          value.toString().isNotEmpty) {
        departments.add(
          value.toString(),
        );
      }
    }

    final result =
    departments.toList()..sort();

    return [
      'All Departments',
      ...result,
    ];
  }

  // ============================================================
  // OPEN MAIN FILTER MENU
  // ============================================================

  Future<void> _openFilterMenu(
      List<QueryDocumentSnapshot> docs,
      ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.70,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                // ==================================================
                // USERS
                // ==================================================

                if (isUsers)
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text('Role'),
                    subtitle:
                    Text(selectedRole),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectSimpleFilter(
                        'Role',
                        [
                          'All Roles',
                          'Student',
                          'Teacher',
                          'Admin',
                        ],
                      );
                    },
                  ),

                // ==================================================
                // STATUS
                // ==================================================

                if (isUsers ||
                    isStudents ||
                    isTeachers)
                  ListTile(
                    leading: const Icon(
                      Icons.verified_outlined,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text('Status'),
                    subtitle:
                    Text(selectedStatus),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectSimpleFilter(
                        'Status',
                        [
                          'All Status',
                          'approved',
                          'pending',
                          'rejected',
                        ],
                      );
                    },
                  ),

                // ==================================================
                // LOCATION
                // ==================================================

                if (isUniversities ||
                    isDepartments)
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text('Location'),
                    subtitle:
                    Text(selectedLocation),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectSimpleFilter(
                        'Location',
                        _getLocations(
                          docs,
                        ),
                      );
                    },
                  ),

                // ==================================================
                // UNIVERSITY
                // ==================================================

                if (isDepartments)
                  ListTile(
                    leading: const Icon(
                      Icons.school_outlined,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text(
                      'University',
                    ),
                    subtitle:
                    Text(
                      selectedUniversity,
                    ),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectSimpleFilter(
                        'University',
                        _getUniversities(
                          docs,
                        ),
                      );
                    },
                  ),

                // ==================================================
                // DEPARTMENT
                // ==================================================

                if (isCourses)
                  ListTile(
                    leading: const Icon(
                      Icons.domain_outlined,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text(
                      'Department',
                    ),
                    subtitle:
                    Text(
                      selectedDepartment,
                    ),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectSimpleFilter(
                        'Department',
                        _getDepartments(
                          docs,
                        ),
                      );
                    },
                  ),

                // ==================================================
                // DATE
                // ==================================================

                if (supportsDateFilter)
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color:
                      Colors.lightBlue,
                    ),
                    title:
                    const Text('Date'),
                    subtitle:
                    Text(
                      selectedDateFilter,
                    ),
                    trailing:
                    const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      _selectDateFilter();
                    },
                  ),

                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTIVE FILTER COUNT
  // ============================================================

  int _activeFilterCount() {
    int count = 0;

    if (_searchController.text
        .trim()
        .isNotEmpty) {
      count++;
    }

    if (selectedRole !=
        'All Roles') {
      count++;
    }

    if (selectedStatus !=
        'All Status') {
      count++;
    }

    if (selectedLocation !=
        'All Locations') {
      count++;
    }

    if (selectedUniversity !=
        'All Universities') {
      count++;
    }

    if (selectedDepartment !=
        'All Departments') {
      count++;
    }

    if (selectedDateFilter !=
        'All Dates') {
      count++;
    }

    return count;
  }

  // ============================================================
  // CLEAR FILTERS
  // ============================================================

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      selectedRole =
      'All Roles';

      selectedStatus =
      'All Status';

      selectedLocation =
      'All Locations';

      selectedUniversity =
      'All Universities';

      selectedDepartment =
      'All Departments';

      selectedDateFilter =
      'All Dates';

      selectedDate = null;
      customStartDate = null;
      customEndDate = null;
    });
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Map<String, dynamic> _getDetails(
      Map<String, dynamic> data,
      ) {
    switch (widget.type) {
      case "users":
      case "students":
      case "teachers":
        return {
          "title":
          data['name'] ??
              data['displayName'] ??
              "Unknown User",

          "Email":
          data['email'] ??
              "Not available",

          "Role":
          data['role'] ??
              "Not available",

          "Status":
          data['status'] ??
              "Not available",

          "University":
          data['university'] ??
              "Not available",
        };

      case "universities":
        return {
          "title":
          data['name'] ??
              data['university'] ??
              "Unknown University",

          "Location":
          _formatLocation(
            data['location'],
          ),
        };

      case "departments":
        return {
          "title":
          data['name'] ??
              data['department'] ??
              "Unknown Department",

          "University":
          data['university'] ??
              "Not available",

          "Location":
          data['location'] ??
              "Not available",
        };

      case "courses":
        return {
          "title":
          data['name'] ??
              data['course'] ??
              data['subject'] ??
              "Unknown Course",

          "Department":
          data['department'] ??
              "Not available",

          "University":
          data['university'] ??
              "Not available",
        };

      case "notes":
        return {
          "title":
          data['title'] ??
              data['name'] ??
              "Untitled Note",

          "Subject":
          data['subject'] ??
              "Not available",

          "University":
          data['university'] ??
              "Not available",

          "Location":
          data['location'] ??
              "Not available",

          "Department":
          data['department'] ??
              "Not available",

          "Semester":
          data['semester']
              ?.toString() ??
              "Not available",

          "Teacher":
          data['teacherName'] ??
              "Not available",
        };

      case "quizzes":
        return {
          "title":
          data['title'] ??
              data['name'] ??
              "Untitled Quiz",

          "Subject":
          data['subject'] ??
              "Not available",

          "University":
          data['university'] ??
              "Not available",

          "Location":
          data['location'] ??
              "Not available",

          "Department":
          data['department'] ??
              "Not available",

          "Semester":
          data['semester']
              ?.toString() ??
              "Not available",

          "Teacher":
          data['teacherName'] ??
              "Not available",
        };

      default:
        return {
          "title":
          data['name'] ??
              data['title'] ??
              "Unknown",
        };
    }
  }

  // ============================================================
  // LOCATION FORMAT
  // ============================================================

  String _formatLocation(
      dynamic location,
      ) {
    if (location is List) {
      return location.join(', ');
    }

    return location?.toString() ??
        "Not available";
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _getIcon() {
    switch (widget.type) {
      case "users":
      case "students":
      case "teachers":
        return Icons.person;

      case "universities":
        return Icons.account_balance;

      case "departments":
        return Icons.domain;

      case "courses":
        return Icons.menu_book;

      case "notes":
        return Icons.note_alt;

      case "quizzes":
        return Icons.quiz;

      default:
        return Icons.info_outline;
    }
  }

  // ============================================================
  // DETAIL TILE
  // ============================================================

  Widget _buildDetailTile(
      BuildContext context,
      Map<String, dynamic> data,
      String documentId,
      ) {
    final details =
    _getDetails(data);

    return Container(
      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 7,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Container(
            padding:
            const EdgeInsets.all(11),

            decoration:
            BoxDecoration(
              color: Colors.lightBlue
                  .withOpacity(0.10),

              borderRadius:
              BorderRadius.circular(12),
            ),

            child: Icon(
              _getIcon(),
              color:
              Colors.lightBlue,
              size: 24,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  details['title'] ??
                      "Unknown",

                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 7,
                ),

                ...details.entries
                    .where(
                      (entry) =>
                  entry.key !=
                      'title',
                )
                    .map(
                      (entry) => Padding(
                    padding:
                    const EdgeInsets
                        .only(
                      bottom: 3,
                    ),

                    child: Text(
                      "${entry.key}: ${entry.value}",

                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        title:
        Text(widget.title),

        backgroundColor:
        Colors.lightBlue,

        foregroundColor:
        Colors.white,
      ),

      body:
      StreamBuilder<QuerySnapshot>(
        stream:
        widget.query.snapshots(),

        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Unable to load ${widget.title}",
                style:
                const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          return ValueListenableBuilder<
              TextEditingValue>(
            valueListenable:
            _searchController,

            builder:
                (context, searchValue, _) {
              final filteredDocs =
              docs.where((doc) {
                final data =
                doc.data()
                as Map<String, dynamic>;

                return _matchesAllFilters(
                  data,
                );
              }).toList();

              return Column(
                children: [
                  // ==================================================
                  // SEARCH
                  // ==================================================

                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      8,
                    ),

                    child: TextField(
                      controller:
                      _searchController,

                      focusNode:
                      _searchFocusNode,

                      keyboardType:
                      TextInputType.text,

                      textInputAction:
                      TextInputAction.done,

                      decoration:
                      InputDecoration(
                        hintText:
                        _getSearchHint(),

                        prefixIcon:
                        const Icon(
                          Icons.search,
                        ),

                        suffixIcon:
                        searchValue.text
                            .isNotEmpty
                            ? IconButton(
                          icon:
                          const Icon(
                            Icons.clear,
                          ),

                          onPressed:
                              () {
                            _searchController
                                .clear();

                            // Do NOT unfocus.
                            // Keyboard stays open.
                            _searchFocusNode
                                .requestFocus();
                          },
                        )
                            : null,

                        filled: true,

                        fillColor:
                        Colors.white,

                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),

                        enabledBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),

                        focusedBorder:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),

                          borderSide:
                          const BorderSide(
                            color:
                            Colors.lightBlue,
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
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                    ),

                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            _openFilterMenu(
                              docs.cast<
                                  QueryDocumentSnapshot>(),
                            );
                          },

                          icon:
                          const Icon(
                            Icons
                                .filter_alt_outlined,
                            size: 18,
                          ),

                          label:
                          Text(
                            _activeFilterCount() ==
                                0
                                ? 'Filters'
                                : 'Filters (${_activeFilterCount()})',
                          ),
                        ),

                        const Spacer(),

                        if (_activeFilterCount() >
                            0)
                          TextButton(
                            onPressed:
                            _clearFilters,

                            child:
                            const Text(
                              'Clear All',
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // NO RECORDS
                  // ==================================================

                  if (docs.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          "No ${widget.title} found.",
                          style:
                          const TextStyle(
                            color:
                            Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )

                  // ==================================================
                  // NO MATCH
                  // ==================================================

                  else if (filteredDocs
                      .isEmpty)
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize:
                          MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.search_off,
                              size: 50,
                              color:
                              Colors.grey,
                            ),

                            SizedBox(
                              height: 10,
                            ),

                            Text(
                              "No matching records found.",
                              style:
                              TextStyle(
                                fontSize: 16,
                                color:
                                Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )

                  // ==================================================
                  // RESULTS
                  // ==================================================

                  else
                    Expanded(
                      child:
                      ListView.separated(
                        padding:
                        const EdgeInsets.all(
                          16,
                        ),

                        itemCount:
                        filteredDocs.length,

                        separatorBuilder:
                            (_, __) =>
                        const SizedBox(
                          height: 10,
                        ),

                        itemBuilder:
                            (context, index) {
                          final doc =
                          filteredDocs[
                          index];

                          final data =
                          doc.data()
                          as Map<String,
                              dynamic>;

                          return _buildDetailTile(
                            context,
                            data,
                            doc.id,
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

  // ============================================================
  // SEARCH HINT
  // ============================================================

  String _getSearchHint() {
    switch (widget.type) {
      case 'users':
        return 'Search name or email';

      case 'students':
        return 'Search student name or email';

      case 'teachers':
        return 'Search teacher name or email';

      case 'universities':
        return 'Search university';

      case 'departments':
        return 'Search department';

      case 'courses':
        return 'Search course';

      default:
        return 'Search';
    }
  }
}