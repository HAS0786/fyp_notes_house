import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class QuizPerformanceScreen extends StatefulWidget {
  const QuizPerformanceScreen({super.key});

  @override
  State<QuizPerformanceScreen> createState() => _QuizPerformanceScreenState();
}

class _QuizPerformanceScreenState extends State<QuizPerformanceScreen> {
  String selectedFilter = 'Today';

  DateTime? customStartDate;
  DateTime? customEndDate;

  // =============================================================
  // DATE FILTER
  // =============================================================

  DateTime _getStartDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (selectedFilter) {
      case 'Last 7 Days':
        return today.subtract(const Duration(days: 6));

      case 'Last 28 Days':
        return today.subtract(const Duration(days: 27));

      case 'Custom Range':
        if (customStartDate != null) {
          return DateTime(
            customStartDate!.year,
            customStartDate!.month,
            customStartDate!.day,
          );
        }
        return today;

      case 'Today':
      default:
        return today;
    }
  }

  DateTime _getEndDate() {
    final now = DateTime.now();

    if (selectedFilter == 'Custom Range' && customEndDate != null) {
      return DateTime(
        customEndDate!.year,
        customEndDate!.month,
        customEndDate!.day,
      ).add(const Duration(days: 1));
    }

    // Include the complete current day.
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  bool _isInSelectedRange(DateTime date) {
    final start = _getStartDate();
    final end = _getEndDate();

    return !date.isBefore(start) && date.isBefore(end);
  }

  // =============================================================
  // CUSTOM DATE RANGE
  // =============================================================

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();

    DateTimeRange? initialRange;

    if (customStartDate != null && customEndDate != null) {
      initialRange = DateTimeRange(
        start: customStartDate!,
        end: customEndDate!,
      );
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      helpText: 'Select Performance Period',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedFilter = 'Custom Range';
      customStartDate = picked.start;
      customEndDate = picked.end;
    });
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      appBar: AppBar(
        title: const Text('Performance Analysis'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_attempts')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          // =====================================================
          // FILTER ATTEMPTS
          // =====================================================

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final timestamp = data['attemptedAt'];

            if (timestamp is! Timestamp) {
              return false;
            }

            final attemptedAt = timestamp.toDate();

            return _isInSelectedRange(attemptedAt);
          }).toList();

          // Oldest → newest.
          // This makes A1 the first attempt in the selected period.
          filteredDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            final timestampA = dataA['attemptedAt'];
            final timestampB = dataB['attemptedAt'];

            if (timestampA is! Timestamp || timestampB is! Timestamp) {
              return 0;
            }

            return timestampA.toDate().compareTo(timestampB.toDate());
          });

          // =====================================================
          // CALCULATE ANALYTICS
          // =====================================================

          final List<FlSpot> lineSpots = [];
          final List<BarChartGroupData> barGroups = [];

          int excellent = 0;
          int average = 0;
          int poor = 0;

          int totalAccuracy = 0;

          for (int i = 0; i < filteredDocs.length; i++) {
            final data = filteredDocs[i].data() as Map<String, dynamic>;

            final int accuracy = int.tryParse(data['accuracy'].toString()) ?? 0;

            totalAccuracy += accuracy;

            lineSpots.add(FlSpot(i.toDouble(), accuracy.toDouble()));

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: accuracy.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue,
                  ),
                ],
              ),
            );

            if (accuracy >= 75) {
              excellent++;
            } else if (accuracy >= 50) {
              average++;
            } else {
              poor++;
            }
          }

          final avgAccuracy = filteredDocs.isNotEmpty
              ? (totalAccuracy / filteredDocs.length).round()
              : 0;

          int maxAccuracy = 0;

          if (filteredDocs.isNotEmpty) {
            maxAccuracy = filteredDocs
                .map((d) {
                  final data = d.data() as Map<String, dynamic>;

                  return int.tryParse(data['accuracy'].toString()) ?? 0;
                })
                .reduce((a, b) => a > b ? a : b);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // FILTER
                // =================================================
                _buildFilterCard(),

                const SizedBox(height: 20),

                // =================================================
                // SUMMARY
                // =================================================
                Row(
                  children: [
                    _summaryCard(
                      'Total Attempts',
                      filteredDocs.length.toString(),
                      Icons.assignment,
                    ),

                    const SizedBox(width: 12),

                    _summaryCard(
                      'Avg Accuracy',
                      '$avgAccuracy%',
                      Icons.trending_up,
                    ),

                    const SizedBox(width: 12),

                    _summaryCard('Best Score', '$maxAccuracy%', Icons.star),
                  ],
                ),

                const SizedBox(height: 28),

                // =================================================
                // NO DATA
                // =================================================
                if (filteredDocs.isEmpty)
                  _buildNoDataCard()
                else ...[
                  // =================================================
                  // ACCURACY PROGRESS
                  // =================================================
                  _section(
                    title: 'Accuracy Progress',
                    description: 'Performance trend across the selected period',
                    child: _lineChart(lineSpots, filteredDocs),
                  ),

                  // =================================================
                  // SCORE DISTRIBUTION
                  // =================================================
                  _section(
                    title: 'Score Distribution',
                    description: 'Accuracy for each quiz attempt',
                    child: _barChart(barGroups, filteredDocs),
                  ),

                  // =================================================
                  // PERFORMANCE BREAKDOWN
                  // =================================================
                  _section(
                    title: 'Performance Breakdown',
                    description: 'Overall classification of quiz performance',
                    child: _pieChart(excellent, average, poor),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =============================================================
  // FILTER CARD
  // =============================================================

  Widget _buildFilterCard() {
    String displayText = selectedFilter;

    if (selectedFilter == 'Custom Range' &&
        customStartDate != null &&
        customEndDate != null) {
      displayText =
          '${customStartDate!.day}/${customStartDate!.month}/${customStartDate!.year}'
          ' - '
          '${customEndDate!.day}/${customEndDate!.month}/${customEndDate!.year}';
    }

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Performance Period',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            const Text(
              'Choose the time period for your quiz performance',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 14),

            InkWell(
              borderRadius: BorderRadius.circular(10),

              onTap: () async {
                final result = await showModalBottomSheet<String>(
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
                                'Select Time Period',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          _filterOption(context, 'Today', Icons.today),

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
                            'Custom Range',
                            Icons.calendar_today,
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                );

                if (result == null) return;

                if (result == 'Custom Range') {
                  await _selectCustomRange();
                } else {
                  setState(() {
                    selectedFilter = result;
                    customStartDate = null;
                    customEndDate = null;
                  });
                }
              },

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade50,
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      color: Colors.lightBlue,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        displayText,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.lightBlue),

      title: Text(title),

      trailing: selectedFilter == title
          ? const Icon(Icons.check, color: Colors.lightBlue)
          : null,

      onTap: () {
        Navigator.pop(context, title);
      },
    );
  }

  // =============================================================
  // NO DATA CARD
  // =============================================================

  Widget _buildNoDataCard() {
    String periodText;

    switch (selectedFilter) {
      case 'Last 7 Days':
        periodText = 'the last 7 days';
        break;

      case 'Last 28 Days':
        periodText = 'the last 28 days';
        break;

      case 'Custom Range':
        periodText = 'the selected date range';
        break;

      case 'Today':
      default:
        periodText = 'today';
    }

    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 55,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 12),

              const Text(
                'No Quiz Attempts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'You have no quiz attempts $periodText.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SUMMARY CARD
  // =============================================================

  Widget _summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              Icon(icon, color: Colors.blue),

              const SizedBox(height: 8),

              Text(
                title,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SECTION
  // =============================================================

  Widget _section({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,

      margin: const EdgeInsets.only(bottom: 20),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(description, style: const TextStyle(color: Colors.black54)),

            const SizedBox(height: 16),

            child,
          ],
        ),
      ),
    );
  }

  // =============================================================
  // ACCURACY PROGRESS
  // =============================================================

  Future<void> _showAttemptDetails(
    BuildContext context,
    Map<String, dynamic> data,
    int attemptNumber,
  ) async {
    final timestamp = data['attemptedAt'];

    String dateTimeText = 'Unknown date';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      dateTimeText =
          '${date.day}/${date.month}/${date.year}'
          ' • '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    final subject = data['subject']?.toString() ?? 'Quiz';

    final score = data['score']?.toString() ?? '0';
    final total = data['total']?.toString() ?? '0';

    final accuracy = int.tryParse(data['accuracy']?.toString() ?? '') ?? 0;

    final university = data['university']?.toString() ?? '';

    final department = data['department']?.toString() ?? '';

    final semester = data['semester']?.toString() ?? '';

    final campus = data['location']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.lightBlue,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Quiz Attempt $attemptNumber',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(Icons.menu_book_outlined, 'Subject', subject),

                _detailRow(Icons.access_time, 'Date & Time', dateTimeText),

                _detailRow(Icons.star_outline, 'Score', '$score / $total'),

                _detailRow(Icons.percent, 'Accuracy', '$accuracy%'),

                if (university.isNotEmpty)
                  _detailRow(
                    Icons.account_balance_outlined,
                    'University',
                    university,
                  ),

                if (department.isNotEmpty)
                  _detailRow(Icons.school_outlined, 'Department', department),

                if (semester.isNotEmpty)
                  _detailRow(Icons.layers_outlined, 'Semester', semester),

                if (campus.isNotEmpty)
                  _detailRow(Icons.location_on_outlined, 'Campus', campus),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 19, color: Colors.lightBlue),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineChart(List<FlSpot> spots, List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      physics: const BouncingScrollPhysics(),

      child: Padding(
        padding: const EdgeInsets.all(8),

        child: SizedBox(
          width: spots.length * 70,
          height: 250,

          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,

              gridData: FlGridData(
                show: true,
                horizontalInterval: 20,

                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),

              lineTouchData: LineTouchData(
                enabled: true,

                handleBuiltInTouches: true,

                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    final spots = response?.lineBarSpots;

                    if (spots == null || spots.isEmpty) {
                      return;
                    }

                    final index = spots.first.x.toInt();

                    if (index < 0 || index >= docs.length) {
                      return;
                    }

                    final data = docs[index].data() as Map<String, dynamic>;

                    _showAttemptDetails(context, data, index + 1);
                  }
                },
              ),

              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,

                    getTitlesWidget: (value, meta) {
                      final index = value.isFinite ? value.toInt() : 0;

                      if (index >= spots.length) {
                        return const SizedBox();
                      }

                      return Text(
                        '${spots[index].y.toInt()}%',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,

                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,

                    getTitlesWidget: (value, _) {
                      final index = value.isFinite ? value.toInt() : 0;

                      if (index < 0 || index >= docs.length) {
                        return const SizedBox();
                      }

                      final data = docs[index].data() as Map<String, dynamic>;

                      final timestamp = data['attemptedAt'];

                      if (timestamp is Timestamp) {
                        final date = timestamp.toDate();

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(show: false),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  barWidth: 3.5,
                  color: Colors.blue,

                  dotData: FlDotData(
                    show: true,

                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: Colors.blue,
                    ),
                  ),

                  belowBarData: BarAreaData(
                    show: true,

                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.blue.withOpacity(0.2),
                      ],

                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SCORE DISTRIBUTION
  // A1 + DATE
  // =============================================================

  Widget _barChart(
    List<BarChartGroupData> bars,
    List<QueryDocumentSnapshot> docs,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      physics: const BouncingScrollPhysics(),

      child: SizedBox(
        width: bars.length * 75,
        height: 270,

        child: BarChart(
          BarChartData(
            maxY: 100,

            alignment: BarChartAlignment.spaceAround,

            gridData: FlGridData(
              show: true,
              horizontalInterval: 20,

              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
            ),

            barTouchData: BarTouchData(
              enabled: true,

              touchCallback: (event, response) {
                if (event is FlTapUpEvent) {
                  final spots = response?.spot;

                  if (spots == null) {
                    return;
                  }

                  final index = spots.touchedBarGroupIndex;

                  if (index < 0 || index >= docs.length) {
                    return;
                  }

                  final data = docs[index].data() as Map<String, dynamic>;

                  _showAttemptDetails(context, data, index + 1);
                }
              },
            ),

            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,

                  getTitlesWidget: (value, meta) {
                    final index = value.isFinite ? value.toInt() : 0;

                    if (index < 0 || index >= bars.length) {
                      return const SizedBox();
                    }

                    final y = bars[index].barRods.first.toY;

                    return Text(
                      '${y.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),

              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 40,

                  getTitlesWidget: (value, _) => Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,

                  getTitlesWidget: (value, _) {
                    final index = value.isFinite ? value.toInt() : 0;

                    if (index < 0 || index >= docs.length) {
                      return const SizedBox();
                    }

                    final data = docs[index].data() as Map<String, dynamic>;

                    final timestamp = data['attemptedAt'];

                    String dateText = '';

                    if (timestamp is Timestamp) {
                      final date = timestamp.toDate();

                      dateText = '${date.day}/${date.month}';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 5),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Text(
                            'A${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          if (dateText.isNotEmpty)
                            Text(
                              dateText,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            borderData: FlBorderData(show: false),

            barGroups: bars.map((group) {
              final y = group.barRods.first.toY;

              final double safeY = y.isFinite ? (y == 0 ? 2 : y) : 0;

              Color barColor;

              if (y >= 75) {
                barColor = Colors.blueAccent;
              } else if (y >= 50) {
                barColor = Colors.orange;
              } else {
                barColor = Colors.red;
              }

              return BarChartGroupData(
                x: group.x,

                barRods: [
                  BarChartRodData(
                    toY: safeY,
                    width: 20,

                    borderRadius: BorderRadius.circular(8),

                    gradient: LinearGradient(
                      colors: [
                        barColor.withAlpha(230),
                        barColor.withAlpha(128),
                      ],

                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // PIE CHART
  // =============================================================

  Widget _pieChart(int excellent, int average, int poor) {
    return Column(
      children: [
        SizedBox(
          height: 220,

          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 4,

              sections: [
                PieChartSectionData(
                  value: excellent.toDouble(),
                  title: '$excellent',
                  color: Colors.green,
                  radius: 50,
                ),

                PieChartSectionData(
                  value: average.toDouble(),
                  title: '$average',
                  color: Colors.orange,
                  radius: 50,
                ),

                PieChartSectionData(
                  value: poor.toDouble(),
                  title: '$poor',
                  color: Colors.red,
                  radius: 50,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,

          children: [
            _legend('Excellent', Colors.green),

            _legend('Average', Colors.orange),

            _legend('Poor', Colors.red),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // LEGEND
  // =============================================================

  Widget _legend(String text, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),

        const SizedBox(width: 4),

        Text(text),
      ],
    );
  }
}
