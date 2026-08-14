import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'quiz_review_screen.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() =>
      _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  String selectedFilter = 'All Dates';

  DateTime? selectedDate;
  DateTime? customStartDate;
  DateTime? customEndDate;

  // =============================================================
  // DATE FILTER
  // =============================================================

  bool _isDateInFilter(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    switch (selectedFilter) {
      case 'Today':
        return dateOnly == today;

      case 'Yesterday':
        final yesterday =
        today.subtract(const Duration(days: 1));

        return dateOnly == yesterday;

      case 'Last 7 Days':
        final start =
        today.subtract(const Duration(days: 6));

        return !dateOnly.isBefore(start) &&
            !dateOnly.isAfter(today);

      case 'Last 28 Days':
        final start =
        today.subtract(const Duration(days: 27));

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

      case 'All Dates':
      default:
        return true;
    }
  }

  // =============================================================
  // CUSTOM DATE
  // =============================================================

  Future<void> _selectCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Quiz Date',
    );

    if (picked == null) return;

    setState(() {
      selectedFilter = 'Custom Date';
      selectedDate = picked;
      customStartDate = null;
      customEndDate = null;
    });
  }

  // =============================================================
  // CUSTOM RANGE
  // =============================================================

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Quiz Date Range',
      saveText: 'Apply',
    );

    if (picked == null) return;

    setState(() {
      selectedFilter = 'Custom Range';
      customStartDate = picked.start;
      customEndDate = picked.end;
      selectedDate = null;
    });
  }

  // =============================================================
  // FILTER MENU
  // =============================================================

  Future<void> _openFilterMenu() async {
    final result =
    await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter Quiz History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              _filterOption(
                context,
                'All Dates',
                Icons.history,
              ),

              _filterOption(
                context,
                'Today',
                Icons.today,
              ),

              _filterOption(
                context,
                'Yesterday',
                Icons.event,
              ),

              _filterOption(
                context,
                'Last 7 Days',
                Icons.date_range,
              ),

              _filterOption(
                context,
                'Last 28 Days',
                Icons.calendar_month,
              ),

              _filterOption(
                context,
                'Custom Date',
                Icons.calendar_today,
              ),

              _filterOption(
                context,
                'Custom Range',
                Icons.date_range_outlined,
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    if (result == 'Custom Date') {
      await _selectCustomDate();
      return;
    }

    if (result == 'Custom Range') {
      await _selectCustomRange();
      return;
    }

    setState(() {
      selectedFilter = result;
      selectedDate = null;
      customStartDate = null;
      customEndDate = null;
    });
  }

  Widget _filterOption(
      BuildContext context,
      String title,
      IconData icon,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.lightBlue,
      ),
      title: Text(title),
      trailing: selectedFilter == title
          ? const Icon(
        Icons.check,
        color: Colors.lightBlue,
      )
          : null,
      onTap: () {
        Navigator.pop(context, title);
      },
    );
  }

  // =============================================================
  // FILTER LABEL
  // =============================================================

  String _getFilterLabel() {
    if (selectedFilter == 'Custom Date' &&
        selectedDate != null) {
      return '${selectedDate!.day}/'
          '${selectedDate!.month}/'
          '${selectedDate!.year}';
    }

    if (selectedFilter == 'Custom Range' &&
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

    return selectedFilter;
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final user =
    FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz History"),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            tooltip: 'Filter History',
            icon: const Icon(
              Icons.filter_alt_outlined,
            ),
            onPressed: _openFilterMenu,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_attempts')
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .orderBy(
          'attemptedAt',
          descending: true,
        )
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allAttempts =
              snapshot.data!.docs;

          // =====================================================
          // FILTER ATTEMPTS
          // =====================================================

          final attempts =
          allAttempts.where((doc) {
            final data =
            doc.data()
            as Map<String, dynamic>;

            final timestamp =
            data['attemptedAt'];

            if (timestamp is! Timestamp) {
              return false;
            }

            final dateTime =
            timestamp.toDate();

            return _isDateInFilter(dateTime);
          }).toList();

          // =====================================================
          // FILTER HEADER
          // =====================================================

          return Column(
            children: [
              if (selectedFilter != 'All Dates')
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    4,
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue
                        .withOpacity(0.08),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt_outlined,
                        size: 18,
                        color: Colors.lightBlue,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          _getFilterLabel(),
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Colors.lightBlue,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter =
                            'All Dates';
                            selectedDate = null;
                            customStartDate = null;
                            customEndDate = null;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              // =================================================
              // NO RESULTS
              // =================================================

              if (attempts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 55,
                          color:
                          Colors.grey.shade400,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'No Quiz Attempts Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          selectedFilter ==
                              'All Dates'
                              ? 'No quiz attempts yet.'
                              : 'No attempts found for this date filter.',
                          textAlign:
                          TextAlign.center,
                          style:
                          const TextStyle(
                            color:
                            Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
              // ===============================================
              // HISTORY LIST
              // ===============================================

                Expanded(
                  child: ListView.builder(
                    itemCount:
                    attempts.length,

                    itemBuilder: (_, i) {
                      final data =
                      attempts[i].data()
                      as Map<String,
                          dynamic>;

                      final timestamp =
                      data['attemptedAt']
                      as Timestamp?;

                      final dateTime =
                      timestamp?.toDate();

                      String formattedDate = "";

                      if (dateTime != null) {
                        formattedDate =
                        "${dateTime.day}/${dateTime.month}/${dateTime.year}"
                            " • "
                            "${dateTime.hour}:"
                            "${dateTime.minute.toString().padLeft(2, '0')}";
                      }

                      // Meta fields
                      final subject =
                          data['subject'] ??
                              'Quiz';

                      final acc =
                          data['accuracy'] ?? 0;

                      Color accColor =
                      acc >= 75
                          ? Colors.green
                          : acc >= 50
                          ? Colors.orange
                          : Colors.red;

                      return GestureDetector(
                        // IMPORTANT:
                        // Existing clickable behavior
                        // remains unchanged.
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  QuizReviewScreen(
                                    subject:
                                    data['subject'],
                                    department:
                                    data['department'],
                                    semester:
                                    data['semester'],
                                    university:
                                    data['university'],
                                    campus:
                                    data['location'],
                                    weakTopics:
                                    Map<String,
                                        dynamic>.from(
                                      data['weakTopics'] ??
                                          {},
                                    ),
                                    questions:
                                    List<Map<String,
                                        dynamic>>.from(
                                      data['questions'],
                                    ),
                                    selectedAnswers:
                                    Map<String,
                                        dynamic>.from(
                                      data['selectedAnswers'],
                                    ),
                                  ),
                            ),
                          );
                        },

                        child: Container(
                          margin:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),

                          padding:
                          const EdgeInsets.all(
                            14,
                          ),

                          decoration:
                          BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color:
                                Colors.black12,
                                blurRadius: 6,
                              ),
                            ],
                          ),

                          child: Row(
                            children: [
                              // LEFT ICON
                              Container(
                                padding:
                                const EdgeInsets
                                    .all(12),

                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .lightBlue
                                      .withOpacity(
                                    0.1,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    10,
                                  ),
                                ),

                                child:
                                const Icon(
                                  Icons.psychology,
                                  color:
                                  Colors.lightBlue,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              // TEXT INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [
                                    Text(
                                      subject,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Quiz Attempt",
                                      style:
                                      TextStyle(
                                        fontSize: 11,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),
                                    ),

                                    Text(
                                      formattedDate,
                                      style:
                                      TextStyle(
                                        fontSize: 12,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              // RIGHT SIDE
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,

                                children: [
                                  Text(
                                    "${data['score']}/${data['total']}",
                                    style:
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color: accColor
                                          .withOpacity(
                                        0.15,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        8,
                                      ),
                                    ),

                                    child: Text(
                                      "$acc%",
                                      style:
                                      TextStyle(
                                        color:
                                        accColor,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  const Icon(
                                    Icons
                                        .arrow_forward_ios,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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