import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class WebNewsletterScreen extends StatefulWidget {
  final bool isMentor;
  final bool isCoordinator;
  
  const WebNewsletterScreen({
    super.key, 
    this.isMentor = false,
    this.isCoordinator = false,
  });

  @override
  State<WebNewsletterScreen> createState() => _WebNewsletterScreenState();
}

class _WebNewsletterScreenState extends State<WebNewsletterScreen> {
  String selectedMonth = 'All Time';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredNewsletters {
    var newsletters = mockNewsletters;
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      newsletters = newsletters.where((newsletter) {
        final title = newsletter['title'].toString().toLowerCase();
        final description = newsletter['description'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }
    
    // Filter by time period
    // In a real app, you'd filter by actual dates
    // For now, this is mock logic
    
    return newsletters;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final crossAxisCount = isLargeScreen ? 3 : (screenWidth > 800 ? 2 : 1);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Title and Actions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 48.0 : 24.0,
                    vertical: 24.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.newspaper_rounded,
                        size: 32,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Newsletters',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const Spacer(),
                      // Add Newsletter Button (for mentors/coordinators)
                      if (widget.isMentor || widget.isCoordinator) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddNewsletterDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Newsletter'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Search and Filter Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 48.0 : 24.0,
                    vertical: 16.0,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Search Field
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search newsletters...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Time Period Filter
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Time Period',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          value: selectedMonth,
                          items: [
                            'All Time',
                            'This Month',
                            'Last Month',
                            'Last 3 Months',
                            '2024',
                            '2023',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonth = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Newsletter Grid
          Expanded(
            child: filteredNewsletters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.newspaper_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No newsletters found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 48.0 : 24.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: filteredNewsletters.length,
                      itemBuilder: (context, index) {
                        final newsletter = filteredNewsletters[index];
                        return _buildNewsletterCard(newsletter);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsletterCard(Map<String, dynamic> newsletter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showFullNewsletter(context, newsletter),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.newspaper_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const Spacer(),
                      Text(
                        newsletter['date'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    newsletter['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsletter['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (newsletter['highlights'] != null && 
                        (newsletter['highlights'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          Text(
                            '${(newsletter['highlights'] as List).length} highlights',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showFullNewsletter(context, newsletter),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading ${newsletter['title']}...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 18),
                        tooltip: 'Download',
                      ),
                      IconButton(
                        onPressed: () {
                          Share.share(
                            'Check out the ${newsletter['title']} from our Student Mentorship Program!\n\n${newsletter['description']}',
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        tooltip: 'Share',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullNewsletter(BuildContext context, Map<String, dynamic> newsletter) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            newsletter['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            newsletter['date'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsletter['description'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Highlights Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Key Highlights',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...newsletter['highlights'].map<Widget>((highlight) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'For more details about any of these events or resources, please contact your mentor or the program coordinator. We look forward to seeing you at our upcoming events!',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 18, color: Color(0xFF1976D2)),
                                const SizedBox(width: 8),
                                const Text('smp@university.edu'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18, color: Color(0xFF1976D2)),
                                const SizedBox(width: 8),
                                const Text('(123) 456-7890'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Color(0xFF1976D2)),
                                const SizedBox(width: 8),
                                const Text('Student Center, Room 234'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading PDF...')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Share.share(
                          'Check out the ${newsletter['title']} from our Student Mentorship Program!\n\n${newsletter['description']}\n\nHighlights:\n• ${newsletter['highlights'].join('\n• ')}',
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNewsletterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Newsletter'),
        content: const Text(
          'Newsletter creation functionality will be implemented soon. This will allow you to compose and publish new newsletters for the mentorship program.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Mock data - same as mobile version
  final List<Map<String, dynamic>> mockNewsletters = [
    {
      'title': 'February 2024 SMP Newsletter',
      'date': 'Feb 15, 2024',
      'description': 'Important updates and upcoming events for SMP mentees.',
      'highlights': [
        'Academic Success Workshop - Feb 20 at Student Center',
        'Peer Study Groups forming for Biology and Chemistry',
        'Career Development Series starting next month',
        'New tutoring hours available at Learning Commons'
      ]
    },
    {
      'title': 'January 2024 SMP Newsletter',
      'date': 'Jan 15, 2024',
      'description': 'Welcome back! Here\'s what\'s happening in the Student Mentorship Program.',
      'highlights': [
        'Welcome Social - Meet other mentees on Jan 25',
        'Time Management Workshop Series - Starting Feb 1',
        'New Study Resources available in the Resource Hub',
        'Student Success Stories: Meet last semester\'s top achievers'
      ]
    },
    {
      'title': 'December 2023 SMP Newsletter',
      'date': 'Dec 1, 2023',
      'description': 'End of semester updates and preparation for finals.',
      'highlights': [
        'Finals Week Study Sessions - Schedule and Locations',
        'Stress Management Workshop - Dec 5',
        'Holiday Social Event - Dec 8',
        'Spring Semester Program Preview'
      ]
    },
    {
      'title': 'November 2023 SMP Newsletter',
      'date': 'Nov 1, 2023',
      'description': 'Updates and events for November in the Student Mentorship Program.',
      'highlights': [
        'Mid-semester Check-in Sessions - Schedule with your mentor',
        'Research Opportunities Workshop - Nov 10',
        'Thanksgiving Break Study Plan Workshop - Nov 15',
        'Volunteer Opportunities for the Holiday Season'
      ]
    },
    {
      'title': 'October 2023 SMP Newsletter',
      'date': 'Oct 1, 2023',
      'description': 'Fall semester is in full swing! Check out what\'s happening this month.',
      'highlights': [
        'Midterm Preparation Strategies - Oct 5',
        'Campus Resource Fair - Oct 12 at Student Union',
        'Mentor-Mentee Social Mixer - Oct 20',
        'Halloween Study Break Event - Oct 31'
      ]
    }
  ];
}

