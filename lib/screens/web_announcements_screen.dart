import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_function_service.dart';
import 'package:intl/intl.dart';

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

  final List<String> _filterOptions = ['All', 'High Priority', 'Medium Priority', 'Low Priority', 'General'];
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'newest', 'label': 'Newest First', 'icon': Icons.arrow_downward},
    {'value': 'oldest', 'label': 'Oldest First', 'icon': Icons.arrow_upward},
    {'value': 'priority', 'label': 'Priority', 'icon': Icons.priority_high},
  ];

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
    var announcements = _announcementService.announcements;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      announcements = announcements.where((a) =>
        a['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a['content'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply priority filters
    if (!_selectedFilters.contains('All') && _selectedFilters.isNotEmpty) {
      announcements = announcements.where((a) {
        final priority = a['priority'] ?? 'none';
        if (_selectedFilters.contains('High Priority') && priority == 'high') return true;
        if (_selectedFilters.contains('Medium Priority') && priority == 'medium') return true;
        if (_selectedFilters.contains('Low Priority') && priority == 'low') return true;
        if (_selectedFilters.contains('General') && (priority == 'none' || priority == null)) return true;
        return false;
      }).toList();
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'oldest':
        announcements.sort((a, b) => a['time'].compareTo(b['time']));
        break;
      case 'priority':
        announcements.sort((a, b) {
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2, 'none': 3};
          final aPriority = priorityOrder[a['priority'] ?? 'none'] ?? 3;
          final bPriority = priorityOrder[b['priority'] ?? 'none'] ?? 3;
          return aPriority.compareTo(bPriority);
        });
        break;
      default: // newest
        announcements.sort((a, b) => b['time'].compareTo(a['time']));
    }
    
    return announcements;
  }

  Map<String, int> get _statistics {
    final announcements = _announcementService.announcements;
    return {
      'total': announcements.length,
      'high': announcements.where((a) => a['priority'] == 'high').length,
      'medium': announcements.where((a) => a['priority'] == 'medium').length,
      'low': announcements.where((a) => a['priority'] == 'low').length,
      'general': announcements.where((a) => a['priority'] == null || a['priority'] == 'none').length,
    };
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
                        _buildHeader(),
                        if (announcementService.error != null) _buildErrorBanner(announcementService),
                        if (announcementService.isLoading) _buildLoadingIndicator(),
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
                    child: _buildFloatingActionButton(announcementService),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
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
                onPressed: () => Navigator.pop(context),
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
              onChanged: (value) => setState(() => _searchQuery = value),
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
          _buildStatisticsCards(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final stats = _statistics;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard('Total', stats['total']!, Colors.blue[600]!, Icons.campaign),
          const SizedBox(width: 16),
          _buildStatCard('High Priority', stats['high']!, Colors.red[600]!, Icons.priority_high),
          const SizedBox(width: 16),
          _buildStatCard('Medium', stats['medium']!, Colors.orange[600]!, Icons.warning_amber),
          const SizedBox(width: 16),
          _buildStatCard('Low', stats['low']!, Colors.green[600]!, Icons.low_priority),
          const SizedBox(width: 16),
          _buildStatCard('General', stats['general']!, Colors.grey[600]!, Icons.info_outline),
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

  Widget _buildContent(AnnouncementService announcementService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _buildFiltersAndSort(),
          const SizedBox(height: 24),
          Expanded(
            child: _filteredAnnouncements.isEmpty && !announcementService.isLoading
                ? _buildEmptyState()
                : _buildAnnouncementsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSort() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilters.contains(filter);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
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
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF0F2D52),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: const Color(0xFF0F2D52).withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButton<String>(
            value: _sortBy,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F2D52)),
            items: _sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'] as String,
                child: Row(
                  children: [
                    Icon(option['icon'] as IconData, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(option['label'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: _filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = _filteredAnnouncements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> announcement) {
    final priority = announcement['priority'] ?? 'none';
    final priorityColor = _getPriorityColor(priority);
    final priorityText = _getPriorityText(priority);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAnnouncementDetails(announcement),
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Priority accent strip
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  announcement['title'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2D52),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: priorityColor, width: 1),
                                ),
                                child: Text(
                                  priorityText,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              announcement['content'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF0F2D52).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Color(0xFF0F2D52),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    announcement['time'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              FutureBuilder<bool>(
                                future: _announcementService.canEditAnnouncement(announcement['created_by'] ?? ''),
                                builder: (context, snapshot) {
                                  if (snapshot.data == true) {
                                    return Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: Colors.grey[600],
                                          onPressed: () => _showEditAnnouncementDialog(announcement),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: Colors.red[400],
                                          onPressed: () => _confirmDelete(announcement),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No announcements found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search or filters'
                : 'Create your first announcement to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(AnnouncementService announcementService) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2D52),
                  Color(0xFF1A4A7F),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2D52).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton.large(
              onPressed: () => _showAddAnnouncementDialog(announcementService),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(AnnouncementService announcementService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              announcementService.error!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: () => announcementService.clearError(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: const LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F2D52)),
      ),
    );
  }

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        announcement['title'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2D52),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(announcement['priority'] ?? 'none').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getPriorityText(announcement['priority'] ?? 'none'),
                    style: TextStyle(
                      color: _getPriorityColor(announcement['priority'] ?? 'none'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  announcement['content'],
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      announcement['time'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAnnouncementDialog(AnnouncementService announcementService) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'none';
    String targetAudience = 'both';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Announcement',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2D52),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter announcement title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      hintText: 'Enter announcement content',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Priority Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Wrap(
                        spacing: 12,
                        children: [
                          {'value': 'high', 'label': 'High', 'color': Colors.red[600]!},
                          {'value': 'medium', 'label': 'Medium', 'color': Colors.orange[600]!},
                          {'value': 'low', 'label': 'Low', 'color': Colors.green[600]!},
                          {'value': 'none', 'label': 'General', 'color': Colors.blue[600]!},
                        ].map((option) {
                          final isSelected = priority == option['value'];
                          return ChoiceChip(
                            label: Text(option['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => priority = option['value'] as String);
                            },
                            selectedColor: (option['color'] as Color).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? option['color'] as Color : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final success = await announcementService.createAnnouncement(
                            title: titleController.text,
                            content: contentController.text,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2D52),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAnnouncementDialog(Map<String, dynamic> announcement) {
    final titleController = TextEditingController(text: announcement['title']);
    final contentController = TextEditingController(text: announcement['content']);
    String priority = announcement['priority'] ?? 'none';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Announcement',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2D52),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter announcement title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      hintText: 'Enter announcement content',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F2D52), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Priority Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F2D52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return Wrap(
                        spacing: 12,
                        children: [
                          {'value': 'high', 'label': 'High', 'color': Colors.red[600]!},
                          {'value': 'medium', 'label': 'Medium', 'color': Colors.orange[600]!},
                          {'value': 'low', 'label': 'Low', 'color': Colors.green[600]!},
                          {'value': 'none', 'label': 'General', 'color': Colors.blue[600]!},
                        ].map((option) {
                          final isSelected = priority == option['value'];
                          return ChoiceChip(
                            label: Text(option['label'] as String),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => priority = option['value'] as String);
                            },
                            selectedColor: (option['color'] as Color).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? option['color'] as Color : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final success = await _announcementService.updateAnnouncement(
                            announcementId: announcement['id'],
                            title: titleController.text,
                            content: contentController.text,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2D52),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Announcement'),
          content: Text('Are you sure you want to delete "${announcement['title']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.green[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'HIGH PRIORITY';
      case 'medium':
        return 'MEDIUM PRIORITY';
      case 'low':
        return 'LOW PRIORITY';
      default:
        return 'GENERAL';
    }
  }
}