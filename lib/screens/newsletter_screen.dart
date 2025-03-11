import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class NewsletterScreen extends StatefulWidget {
  final bool isMentor;
  
  const NewsletterScreen({
    super.key, 
    this.isMentor = false,
  });

  @override
  State<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  String selectedMonth = 'All Time';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Newsletters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search newsletters',
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Time Period',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
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
          
          // Newsletter List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: mockNewsletters.length,
              itemBuilder: (context, index) {
                final newsletter = mockNewsletters[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Newsletter header with gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.newspaper_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    newsletter['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
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
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Download Newsletter',
                              onPressed: () {
                                // TODO: Implement download
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Downloading ${newsletter['title']}...')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Newsletter description
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          newsletter['description'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      
                      // Newsletter highlights
                      if (newsletter['highlights'] != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Highlights:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...newsletter['highlights'].map<Widget>((highlight) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        highlight,
                                        style: const TextStyle(
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.visibility),
                              label: const Text('View Full Details'),
                              onPressed: () {
                                _showFullNewsletter(context, newsletter);
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              onPressed: () {
                                Share.share(
                                  'Check out the ${newsletter['title']} from our Student Mentorship Program!\n\n${newsletter['description']}\n\nHighlights:\n• ${newsletter['highlights'].join('\n• ')}',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Only show FAB for mentors or coordinators to add new newsletters
      floatingActionButton: widget.isMentor ? FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement add newsletter functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add newsletter functionality coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Newsletter'),
      ) : null,
    );
  }

  void _showFullNewsletter(BuildContext context, Map<String, dynamic> newsletter) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Newsletter header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        newsletter['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Newsletter content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            newsletter['date'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        newsletter['description'],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Highlights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...newsletter['highlights'].map<Widget>((highlight) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                highlight,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      
                      // Additional content for full newsletter view
                      const SizedBox(height: 24),
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'For more details about any of these events or resources, please contact your mentor or the program coordinator. We look forward to seeing you at our upcoming events!',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Student Mentorship Program\nEmail: smp@university.edu\nPhone: (123) 456-7890\nOffice: Student Center, Room 234',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading PDF...')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () {
                        Navigator.pop(context);
                        Share.share(
                          'Check out the ${newsletter['title']} from our Student Mentorship Program!\n\n${newsletter['description']}\n\nHighlights:\n• ${newsletter['highlights'].join('\n• ')}',
                        );
                      },
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

  // Mock data for newsletters
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