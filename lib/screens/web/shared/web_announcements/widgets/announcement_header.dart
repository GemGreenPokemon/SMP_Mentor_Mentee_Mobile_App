import 'package:flutter/material.dart';
import 'statistics_cards.dart';
import '../models/announcement_stats.dart';

class AnnouncementHeader extends StatelessWidget {
  final AnnouncementStats statistics;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onClose;

  const AnnouncementHeader({
    super.key,
    required this.statistics,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay updated with the latest news and updates',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0F2D52)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Statistics cards
          StatisticsCards(statistics: statistics),
        ],
      ),
    );
  }
}