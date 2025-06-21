import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/resource.dart';
import '../models/resource_category.dart';
import '../models/quick_link.dart';
import 'resource_constants.dart';

class ResourceHelpers {
  static final DateFormat dateFormat = DateFormat('MMM d, yyyy');
  
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  static IconData getFileIcon(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf;
      case ResourceType.docx:
        return Icons.description;
      case ResourceType.xlsx:
        return Icons.table_chart;
      case ResourceType.link:
        return Icons.link;
    }
  }
  
  static Color getFileColor(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return ResourceConstants.pdfColor;
      case ResourceType.docx:
        return ResourceConstants.docxColor;
      case ResourceType.xlsx:
        return ResourceConstants.xlsxColor;
      case ResourceType.link:
        return ResourceConstants.linkColor;
    }
  }
  
  static bool matchesFilter(Resource resource, String searchQuery, ResourceCategory category, 
      bool isMentor, bool isCoordinator) {
    // Check category filter
    final matchesCategory = category == ResourceCategory.all || 
                          resource.category == category.displayName;
    
    // Check search query
    final matchesSearch = searchQuery.isEmpty ||
                        resource.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        resource.description.toLowerCase().contains(searchQuery.toLowerCase());
    
    // Check role-based access
    final matchesRole = isCoordinator ||
                      (isMentor && resource.audience != 'Coordinators') ||
                      (!isMentor && (resource.audience == 'All' || resource.audience == 'Mentees'));
    
    return matchesCategory && matchesSearch && matchesRole;
  }
  
  // Quick Links Data
  static List<QuickLink> getQuickLinks() {
    return [
      QuickLink(
        title: 'Academic Calendar',
        description: 'Important dates and deadlines',
        icon: Icons.calendar_today,
        color: Colors.blue,
      ),
      QuickLink(
        title: 'Campus Resources',
        description: 'Links to various campus support services',
        icon: Icons.school,
        color: Colors.green,
      ),
      QuickLink(
        title: 'Student Success Center',
        description: 'Academic support and tutoring services',
        icon: Icons.psychology,
        color: Colors.orange,
      ),
      QuickLink(
        title: 'Library Resources',
        description: 'Access to digital libraries and research tools',
        icon: Icons.local_library,
        color: Colors.purple,
      ),
    ];
  }
  
  static List<QuickLink> getProgramResources() {
    return [
      QuickLink(
        title: 'Program Overview',
        description: 'Introduction to the Student Mentorship Program',
        icon: Icons.info_outline,
        color: Colors.teal,
      ),
      QuickLink(
        title: 'Academic Success Guide',
        description: 'Essential tips and strategies for excellence',
        icon: Icons.school,
        color: Colors.indigo,
      ),
      QuickLink(
        title: 'Goal Setting Workshop',
        description: 'Resources from the goal setting workshops',
        icon: Icons.track_changes,
        color: Colors.amber,
      ),
      QuickLink(
        title: 'Campus Life Guide',
        description: 'Making the most of your university experience',
        icon: Icons.emoji_people,
        color: Colors.pink,
      ),
    ];
  }
  
  // Mock Data Generators
  static List<Resource> generateMockResources() {
    final now = DateTime.now();
    return [
      Resource(
        id: '1',
        title: 'Program Handbook 2023',
        description: 'Complete guide to the mentorship program including policies and procedures.',
        type: ResourceType.pdf,
        category: ResourceCategory.programDocuments.displayName,
        dateAdded: DateTime(2023, 1, 15),
        audience: 'All',
        url: 'assets/documents/handbook.pdf',
        assignedTo: [],
      ),
      Resource(
        id: '2',
        title: 'Mentorship Agreement Template',
        description: 'Standard agreement to be signed by mentors and mentees at the beginning of the program.',
        type: ResourceType.docx,
        category: ResourceCategory.templates.displayName,
        dateAdded: DateTime(2023, 2, 3),
        audience: 'Mentors',
        url: 'assets/documents/agreement.docx',
        assignedTo: ['Alice Johnson'],
      ),
      Resource(
        id: '3',
        title: 'Monthly Progress Report',
        description: 'Template for tracking mentee progress on a monthly basis.',
        type: ResourceType.xlsx,
        category: ResourceCategory.templates.displayName,
        dateAdded: DateTime(2023, 2, 10),
        audience: 'Mentors',
        url: 'assets/documents/progress.xlsx',
        assignedTo: [],
      ),
      Resource(
        id: '4',
        title: 'Goal Setting Worksheet',
        description: 'Worksheet to help mentees set SMART goals for their development.',
        type: ResourceType.pdf,
        category: ResourceCategory.worksheets.displayName,
        dateAdded: DateTime(2023, 3, 5),
        audience: 'Mentees',
        url: 'assets/documents/goals.pdf',
        assignedTo: ['Alice Johnson', 'Bob Wilson'],
      ),
      Resource(
        id: '5',
        title: 'Effective Communication Guide',
        description: 'Resource for improving communication skills in mentorship relationships.',
        type: ResourceType.pdf,
        category: ResourceCategory.studyMaterials.displayName,
        dateAdded: DateTime(2023, 4, 12),
        audience: 'All',
        url: 'assets/documents/communication.pdf',
        assignedTo: [],
      ),
      Resource(
        id: '6',
        title: 'Mentor Training Slides',
        description: 'Presentation slides from the mentor training workshop.',
        type: ResourceType.pdf,
        category: ResourceCategory.mentorMaterials.displayName,
        dateAdded: DateTime(2023, 5, 20),
        audience: 'Mentors',
        url: 'assets/documents/training.pdf',
        assignedTo: [],
      ),
      Resource(
        id: '7',
        title: 'Career Development Resources',
        description: 'Collection of resources for career planning and professional development.',
        type: ResourceType.link,
        category: ResourceCategory.studyMaterials.displayName,
        dateAdded: DateTime(2023, 8, 22),
        audience: 'Mentees',
        url: 'https://example.com/career-resources',
        assignedTo: ['Bob Wilson'],
      ),
    ];
  }
  
  static List<String> getCategories() {
    return ResourceCategory.values
        .where((cat) => cat != ResourceCategory.all)
        .map((cat) => cat.displayName)
        .toList();
  }
}