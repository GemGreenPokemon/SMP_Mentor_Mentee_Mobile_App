import 'package:flutter/material.dart';
import 'announcement_constants.dart';

class AnnouncementHelpers {
  static Color getPriorityColor(String priority) {
    final config = AnnouncementConstants.priorityConfig[priority] ?? 
                   AnnouncementConstants.priorityConfig['none']!;
    final baseColor = config['color'] as MaterialColor;
    final colorValue = config['colorValue'] as int;
    return baseColor[colorValue]!;
  }

  static String getPriorityText(String priority) {
    final config = AnnouncementConstants.priorityConfig[priority] ?? 
                   AnnouncementConstants.priorityConfig['none']!;
    return config['displayText'] as String;
  }

  static List<Map<String, dynamic>> filterAnnouncements(
    List<Map<String, dynamic>> announcements,
    String searchQuery,
    List<String> selectedFilters,
    String sortBy,
  ) {
    var filtered = List<Map<String, dynamic>>.from(announcements);
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((a) =>
        a['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
        a['content'].toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply priority filters
    if (!selectedFilters.contains('All') && selectedFilters.isNotEmpty) {
      filtered = filtered.where((a) {
        final priority = a['priority'] ?? 'none';
        if (selectedFilters.contains('High Priority') && priority == 'high') return true;
        if (selectedFilters.contains('Medium Priority') && priority == 'medium') return true;
        if (selectedFilters.contains('Low Priority') && priority == 'low') return true;
        if (selectedFilters.contains('General') && (priority == 'none' || priority == null)) return true;
        return false;
      }).toList();
    }
    
    // Apply sorting
    switch (sortBy) {
      case 'oldest':
        filtered.sort((a, b) => a['time'].compareTo(b['time']));
        break;
      case 'priority':
        filtered.sort((a, b) {
          final aPriority = AnnouncementConstants.priorityOrder[a['priority'] ?? 'none'] ?? 3;
          final bPriority = AnnouncementConstants.priorityOrder[b['priority'] ?? 'none'] ?? 3;
          return aPriority.compareTo(bPriority);
        });
        break;
      default: // newest
        filtered.sort((a, b) => b['time'].compareTo(a['time']));
    }
    
    return filtered;
  }

  static Map<String, int> calculateStatistics(List<Map<String, dynamic>> announcements) {
    return {
      'total': announcements.length,
      'high': announcements.where((a) => a['priority'] == 'high').length,
      'medium': announcements.where((a) => a['priority'] == 'medium').length,
      'low': announcements.where((a) => a['priority'] == 'low').length,
      'general': announcements.where((a) => a['priority'] == null || a['priority'] == 'none').length,
    };
  }
}