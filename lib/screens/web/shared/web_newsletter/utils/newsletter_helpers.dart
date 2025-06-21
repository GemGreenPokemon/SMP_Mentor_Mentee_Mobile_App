import 'package:intl/intl.dart';
import '../models/newsletter.dart';

class NewsletterHelpers {
  static final DateFormat dateFormat = DateFormat('MMM d, yyyy');
  
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  static String generateShareText(Newsletter newsletter) {
    final highlights = newsletter.highlights.isNotEmpty 
        ? '\n\nHighlights:\n• ${newsletter.highlights.join('\n• ')}'
        : '';
    
    return 'Check out the ${newsletter.title} from our Student Mentorship Program!'
        '\n\n${newsletter.description}$highlights';
  }
  
  static String generateDownloadMessage(String title) {
    return 'Downloading $title...';
  }
  
  // Mock data generator for development
  static List<Newsletter> generateMockNewsletters() {
    final now = DateTime.now();
    return [
      Newsletter(
        id: '1',
        title: 'February 2024 SMP Newsletter',
        date: DateTime(2024, 2, 15),
        description: 'Important updates and upcoming events for SMP mentees.',
        highlights: [
          'Academic Success Workshop - Feb 20 at Student Center',
          'Peer Study Groups forming for Biology and Chemistry',
          'Career Development Series starting next month',
          'New tutoring hours available at Learning Commons'
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Newsletter(
        id: '2',
        title: 'January 2024 SMP Newsletter',
        date: DateTime(2024, 1, 15),
        description: 'Welcome back! Here\'s what\'s happening in the Student Mentorship Program.',
        highlights: [
          'Welcome Social - Meet other mentees on Jan 25',
          'Time Management Workshop Series - Starting Feb 1',
          'New Study Resources available in the Resource Hub',
          'Student Success Stories: Meet last semester\'s top achievers'
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Newsletter(
        id: '3',
        title: 'December 2023 SMP Newsletter',
        date: DateTime(2023, 12, 1),
        description: 'End of semester updates and preparation for finals.',
        highlights: [
          'Finals Week Study Sessions - Schedule and Locations',
          'Stress Management Workshop - Dec 5',
          'Holiday Social Event - Dec 8',
          'Spring Semester Program Preview'
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Newsletter(
        id: '4',
        title: 'November 2023 SMP Newsletter',
        date: DateTime(2023, 11, 1),
        description: 'Updates and events for November in the Student Mentorship Program.',
        highlights: [
          'Mid-semester Check-in Sessions - Schedule with your mentor',
          'Research Opportunities Workshop - Nov 10',
          'Thanksgiving Break Study Plan Workshop - Nov 15',
          'Volunteer Opportunities for the Holiday Season'
        ],
        createdAt: now,
        updatedAt: now,
      ),
      Newsletter(
        id: '5',
        title: 'October 2023 SMP Newsletter',
        date: DateTime(2023, 10, 1),
        description: 'Fall semester is in full swing! Check out what\'s happening this month.',
        highlights: [
          'Midterm Preparation Strategies - Oct 5',
          'Campus Resource Fair - Oct 12 at Student Union',
          'Mentor-Mentee Social Mixer - Oct 20',
          'Halloween Study Break Event - Oct 31'
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}