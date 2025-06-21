import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/report_constants.dart';

class GoalProgressChart extends StatelessWidget {
  const GoalProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(ReportConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Progress by Mentee',
              style: TextStyle(
                fontSize: ReportConstants.subtitleTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ReportConstants.mediumPadding),
            SizedBox(
              height: ReportConstants.chartHeight,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final names = ['Alice', 'Bob', 'Carlos'];
                          if (value.toInt() < names.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: ReportConstants.tinyPadding),
                              child: Text(
                                names[value.toInt()],
                                style: const TextStyle(fontSize: ReportConstants.captionTextSize),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 85,
                          color: ReportConstants.chartColors[0],
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 72,
                          color: ReportConstants.chartColors[1],
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 90,
                          color: ReportConstants.chartColors[2],
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}