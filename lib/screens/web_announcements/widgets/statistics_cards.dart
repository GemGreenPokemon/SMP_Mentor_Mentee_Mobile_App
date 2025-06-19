import 'package:flutter/material.dart';
import '../models/announcement_stats.dart';

class StatisticsCards extends StatelessWidget {
  final AnnouncementStats statistics;

  const StatisticsCards({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total', statistics.total, Colors.blue[600]!, Icons.campaign),
          const SizedBox(width: 16),
          _buildStatCard('High Priority', statistics.high, Colors.red[600]!, Icons.priority_high),
          const SizedBox(width: 16),
          _buildStatCard('Medium', statistics.medium, Colors.orange[600]!, Icons.warning_amber),
          const SizedBox(width: 16),
          _buildStatCard('Low', statistics.low, Colors.green[600]!, Icons.low_priority),
          const SizedBox(width: 16),
          _buildStatCard('General', statistics.general, Colors.grey[600]!, Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}