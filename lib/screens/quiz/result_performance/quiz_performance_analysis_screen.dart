import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class QuizPerformanceScreen extends StatelessWidget {
  const QuizPerformanceScreen({super.key});

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

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No quiz attempts found'));
          }

          final List<FlSpot> lineSpots = [];
          final List<BarChartGroupData> barGroups = [];

          int excellent = 0, average = 0, poor = 0;
          int totalAccuracy = 0;

          for (int i = 0; i < docs.length; i++) {
            final data = docs[i].data() as Map<String, dynamic>;
            final int accuracy =
                int.tryParse(data['accuracy'].toString()) ?? 0;

            totalAccuracy += accuracy;
            lineSpots.add(FlSpot(i.toDouble(), accuracy.toDouble()));

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: accuracy.toDouble(),
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
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

          final avgAccuracy = (totalAccuracy / docs.length).round();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Summary Cards
                Row(
                  children: [
                    _summaryCard(
                      'Attempts',
                      docs.length.toString(),
                      Icons.assignment,
                    ),
                    const SizedBox(width: 12),
                    _summaryCard(
                      'Avg Accuracy',
                      '$avgAccuracy%',
                      Icons.trending_up,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _section(
                  title: 'Accuracy Progress',
                  description:
                  'Trend of performance across all quiz attempts',
                  child: _lineChart(lineSpots),
                ),

                _section(
                  title: 'Score Distribution',
                  description:
                  'Comparison of accuracy for each quiz attempt',
                  child: _barChart(barGroups),
                ),

                _section(
                  title: 'Performance Breakdown',
                  description:
                  'Overall classification of quiz performance',
                  child: _pieChart(excellent, average, poor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

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
              style:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // ================= CHARTS =================

  Widget _lineChart(List<FlSpot> spots) {
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
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
                getTitlesWidget: (value, _) => Text(
                  'Atmp${value.toInt() + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
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
                    Colors.blue.withValues(alpha: 0.2),
                    Colors.blue.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart(List<BarChartGroupData> bars) {
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: 100,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  'Atmp${value.toInt() + 1}', // Attempt label
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars.map((group) {
            final y = group.barRods.first.toY;

            // Force visibility for 0%
            final double safeY = y == 0 ? 2 : y;

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
                  width: 18,
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
    );
  }

  Widget _pieChart(int excellent, int average, int poor) {
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 4,
          sections: [
            PieChartSectionData(
              value: excellent.toDouble(),
              title: 'Excellent',
              color: Colors.green,
              radius: 50,
            ),
            PieChartSectionData(
              value: average.toDouble(),
              title: 'Average',
              color: Colors.orange,
              radius: 50,
            ),
            PieChartSectionData(
              value: poor.toDouble(),
              title: 'Poor',
              color: Colors.red,
              radius: 50,
            ),
          ],
        ),
      ),
    );
  }
}
