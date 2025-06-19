import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:smp_mentor_mentee_mobile_app/services/announcement_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/auth_service.dart';
import 'package:smp_mentor_mentee_mobile_app/services/cloud_function_service.dart';
import 'package:intl/intl.dart';

// Import models and utils
import 'models/announcement_filter.dart';
import 'models/announcement_stats.dart';
import 'utils/announcement_helpers.dart';
import 'utils/announcement_constants.dart';

// Import widgets
import 'widgets/announcement_header.dart';
import 'widgets/filters_and_sort.dart';
import 'widgets/announcement_grid.dart';
import 'widgets/empty_state.dart';
import 'widgets/error_banner.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/floating_action_button.dart';

// Import dialogs
import 'widgets/dialogs/announcement_details_dialog.dart';
import 'widgets/dialogs/create_announcement_dialog.dart';
import 'widgets/dialogs/edit_announcement_dialog.dart';
import 'widgets/dialogs/delete_confirmation_dialog.dart';

class WebAnnouncementsScreen extends StatefulWidget {
  const WebAnnouncementsScreen({super.key});

  @override
  State<WebAnnouncementsScreen> createState() => _WebAnnouncementsScreenState();
}

class _WebAnnouncementsScreenState extends State<WebAnnouncementsScreen> 
    with TickerProviderStateMixin {
  final AnnouncementService _announcementService = AnnouncementService();
  String? _userRole;
  String _searchQuery = '';
  List<String> _selectedFilters = ['All'];
  String _sortBy = 'newest';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final authService = AuthService();
    _userRole = await authService.getUserRole();
    await _announcementService.fetchAnnouncements();
    if (mounted) setState(() {});
  }

  bool get _canCreateAnnouncements => _userRole == 'coordinator' || _userRole == 'mentor';

  List<Map<String, dynamic>> get _filteredAnnouncements {
    return AnnouncementHelpers.filterAnnouncements(
      _announcementService.announcements,
      _searchQuery,
      _selectedFilters,
      _sortBy,
    );
  }

  AnnouncementStats get _statistics {
    final statsMap = AnnouncementHelpers.calculateStatistics(_announcementService.announcements);
    return AnnouncementStats.fromMap(statsMap);
  }

  void _handleFilterChange(String filter, bool selected) {
    setState(() {
      if (filter == 'All') {
        _selectedFilters = ['All'];
      } else {
        _selectedFilters.remove('All');
        if (selected) {
          _selectedFilters.add(filter);
        } else {
          _selectedFilters.remove(filter);
        }
        if (_selectedFilters.isEmpty) {
          _selectedFilters.add('All');
        }
      }
    });
  }

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementDetailsDialog(announcement: announcement),
    );
  }

  void _showAddAnnouncementDialog(AnnouncementService announcementService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateAnnouncementDialog(
        onCreatePressed: (title, content, priority, targetAudience) async {
          final success = await announcementService.createAnnouncement(
            title: title,
            content: content,
            priority: priority,
            targetAudience: targetAudience,
          );

          Navigator.pop(context);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Announcement created successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create announcement: ${announcementService.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditAnnouncementDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAnnouncementDialog(
        announcement: announcement,
        onUpdatePressed: (id, title, content, priority) async {
          final success = await _announcementService.updateAnnouncement(
            announcementId: id,
            title: title,
            content: content,
            priority: priority,
          );

          Navigator.pop(context);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Announcement updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update announcement: ${_announcementService.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        announcementTitle: announcement['title'],
        onDeletePressed: () async {
          final success = await _announcementService.deleteAnnouncement(announcement['id']);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Announcement deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete announcement: ${_announcementService.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _announcementService,
      child: Consumer<AnnouncementService>(
        builder: (context, announcementService, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Stack(
              children: [
                // Background gradient
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0F2D52),
                        const Color(0xFF0F2D52).withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                
                // Main content
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        AnnouncementHeader(
                          statistics: _statistics,
                          searchQuery: _searchQuery,
                          onSearchChanged: (value) => setState(() => _searchQuery = value),
                          onClose: () => Navigator.pop(context),
                        ),
                        if (announcementService.error != null) 
                          ErrorBanner(
                            error: announcementService.error!,
                            onDismiss: () => announcementService.clearError(),
                          ),
                        if (announcementService.isLoading) 
                          const LoadingIndicator(),
                        Expanded(
                          child: _buildContent(announcementService),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Floating Action Button
                if (_canCreateAnnouncements)
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: AnnouncementFloatingActionButton(
                      onPressed: () => _showAddAnnouncementDialog(announcementService),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(AnnouncementService announcementService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          FiltersAndSort(
            selectedFilters: _selectedFilters,
            sortBy: _sortBy,
            onFilterChanged: _handleFilterChange,
            onSortChanged: (value) => setState(() => _sortBy = value),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _filteredAnnouncements.isEmpty && !announcementService.isLoading
                ? EmptyState(searchQuery: _searchQuery)
                : AnnouncementGrid(
                    announcements: _filteredAnnouncements,
                    announcementService: _announcementService,
                    onCardTap: _showAnnouncementDetails,
                    onEditTap: _showEditAnnouncementDialog,
                    onDeleteTap: _confirmDelete,
                  ),
          ),
        ],
      ),
    );
  }
}