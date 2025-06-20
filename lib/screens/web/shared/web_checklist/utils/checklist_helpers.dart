import 'package:flutter/material.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/checklist_filter.dart';

class ChecklistHelpers {
  static List<Checklist> filterChecklists(
    List<Checklist> checklists,
    ChecklistFilter filter,
  ) {
    return checklists.where((checklist) {
      // Filter by mentee
      if (filter.menteeId != null && filter.menteeId != 'all') {
        if (checklist.assignedTo != filter.menteeId) {
          return false;
        }
      }

      // Filter by custom/default
      if (filter.showCustomOnly && !checklist.isCustom) {
        return false;
      }
      if (filter.showDefaultOnly && checklist.isCustom) {
        return false;
      }

      // Filter by progress status
      final progress = checklist.progress;
      if (!filter.showCompleted && progress == 1.0) {
        return false;
      }
      if (!filter.showInProgress && progress > 0 && progress < 1.0) {
        return false;
      }
      if (!filter.showNotStarted && progress == 0) {
        return false;
      }

      return true;
    }).toList();
  }

  static String getProgressPercentage(double progress) {
    return '${(progress * 100).round()}%';
  }

  static Color getProgressColor(double progress) {
    if (progress == 1.0) return const Color(0xFF4CAF50);
    if (progress >= 0.7) return const Color(0xFF8BC34A);
    if (progress >= 0.4) return const Color(0xFFFFC107);
    if (progress > 0) return const Color(0xFF03A9F4);
    return const Color(0xFF9E9E9E);
  }

  static Color getProofStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static IconData getProofStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  static List<Checklist> createMockDefaultChecklists() {
    return [
      Checklist(
        id: 'default-1',
        title: 'Initial Mentorship Setup',
        description: 'Essential tasks for starting the mentorship relationship',
        isCustom: false,
        items: [
          ChecklistItem(
            id: 'item-1',
            title: 'First Meeting Completed',
            description: 'Introductory meeting with mentee',
            completed: true,
          ),
          ChecklistItem(
            id: 'item-2',
            title: 'Program Overview Discussed',
            description: 'Review program expectations and guidelines',
            completed: true,
          ),
          ChecklistItem(
            id: 'item-3',
            title: 'Goals Established',
            description: 'Set academic and personal development goals',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-4',
            title: 'Communication Preferences Set',
            description: 'Establish preferred contact methods and times',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-5',
            title: 'Resource Access Confirmed',
            description: 'Ensure access to necessary program resources',
            completed: false,
          ),
        ],
      ),
      Checklist(
        id: 'default-2',
        title: 'Monthly Progress Review',
        description: 'Regular check-in items for tracking progress',
        isCustom: false,
        items: [
          ChecklistItem(
            id: 'item-6',
            title: 'Academic Progress Review',
            description: 'Discuss current academic performance',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-7',
            title: 'Goals Progress Check',
            description: 'Review progress on established goals',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-8',
            title: 'Resource Utilization',
            description: 'Evaluate use of available resources',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-9',
            title: 'Challenges Discussion',
            description: 'Address any current challenges or concerns',
            completed: false,
          ),
        ],
      ),
    ];
  }

  static List<Checklist> createMockCustomChecklists() {
    return [
      Checklist(
        id: 'custom-1',
        title: 'Research Project Guidance',
        description: 'Steps for mentoring through research project',
        isCustom: true,
        createdBy: 'mentor-123',
        items: [
          ChecklistItem(
            id: 'item-10',
            title: 'Topic Selection',
            description: 'Help mentee choose research topic',
            completed: true,
            proof: 'Research proposal document',
            proofStatus: 'approved',
          ),
          ChecklistItem(
            id: 'item-11',
            title: 'Literature Review',
            description: 'Guide through literature review process',
            completed: true,
            proof: 'Literature review draft',
            proofStatus: 'approved',
          ),
          ChecklistItem(
            id: 'item-12',
            title: 'Methodology Planning',
            description: 'Assist with research methodology',
            completed: true,
            proof: 'Methodology section draft',
            proofStatus: 'pending',
          ),
          ChecklistItem(
            id: 'item-13',
            title: 'Data Collection',
            description: 'Support during data collection phase',
            completed: false,
          ),
          ChecklistItem(
            id: 'item-14',
            title: 'Data Analysis',
            description: 'Help with data analysis and interpretation',
            completed: false,
          ),
        ],
      ),
    ];
  }

  static List<Map<String, String>> getMockMentees() {
    return [
      {'id': 'all', 'name': 'All Mentees'},
      {'id': 'mentee-1', 'name': 'Alice Johnson'},
      {'id': 'mentee-2', 'name': 'Bob Wilson'},
      {'id': 'mentee-3', 'name': 'Carlos Rodriguez'},
    ];
  }
}