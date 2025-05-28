import 'dart:math';
import 'dart:convert';
import '../models/user.dart';
import '../models/mentorship.dart';
import '../models/availability.dart';
import '../models/meeting.dart';
import '../models/announcement.dart';
import '../models/checklist.dart';
import '../models/message.dart';
import '../models/event.dart';
import 'local_database_service.dart';

class MockDataGenerator {
  static final _random = Random();
  static final _localDb = LocalDatabaseService.instance;

  static const List<String> _firstNames = [
    'John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'Robert', 'Lisa',
    'James', 'Mary', 'William', 'Jennifer', 'Richard', 'Maria', 'Thomas'
  ];

  static const List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez'
  ];

  static const List<String> _meetingTopics = [
    'Career Planning', 'Academic Progress', 'Research Opportunities',
    'Course Selection', 'Internship Preparation', 'Networking Strategies',
    'Skill Development', 'Goal Setting', 'Time Management'
  ];

  static const List<String> _checklistCategories = [
    'Onboarding', 'Semester Goals', 'Professional Development',
    'Academic Requirements', 'Career Preparation'
  ];

  static const List<String> _eventTypes = [
    'workshop', 'meeting', 'social', 'training', 'other'
  ];

  static Future<void> generateMockData({
    bool includeCoordinators = true,
    bool includeMentors = true,
    bool includeMentees = true,
    bool clearExisting = true,
  }) async {
    // Clear existing data if requested
    if (clearExisting) {
      await _localDb.clearAllTables();
    }

    // Generate coordinators
    List<User> coordinators = [];
    if (includeCoordinators) {
      for (int i = 0; i < 2; i++) {
        // Check if coordinator already exists
        final existingCoordinator = await _localDb.getUserByEmail('coordinator${i + 1}@ucmerced.edu');
        if (existingCoordinator == null) {
          final coordinator = User(
            id: _localDb.generateId(),
            name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
            email: 'coordinator${i + 1}@ucmerced.edu',
            userType: 'coordinator',
            studentId: 'COORD${(1000 + i).toString()}',
            createdAt: DateTime.now().subtract(Duration(days: 365 - i * 30)),
          );
          await _localDb.createUser(coordinator);
          coordinators.add(coordinator);
        } else {
          coordinators.add(existingCoordinator);
        }
      }
    } else {
      // Load existing coordinators for announcements/events
      coordinators = await _localDb.getUsersByType('coordinator');
    }

    // Generate mentors
    List<User> mentors = [];
    if (includeMentors) {
      for (int i = 0; i < 5; i++) {
        // Check if mentor already exists
        final existingMentor = await _localDb.getUserByEmail('mentor${i + 1}@ucmerced.edu');
        if (existingMentor == null) {
          final mentor = User(
            id: _localDb.generateId(),
            name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
            email: 'mentor${i + 1}@ucmerced.edu',
            userType: 'mentor',
            studentId: 'M${(2000 + i).toString()}',
            createdAt: DateTime.now().subtract(Duration(days: 300 - i * 20)),
          );
          await _localDb.createUser(mentor);
          mentors.add(mentor);

          // Generate availability for each mentor
          final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
          for (int j = 0; j < 3; j++) {
            final availability = Availability(
              id: _localDb.generateId(),
              mentorId: mentor.id,
              day: days[_random.nextInt(days.length)],
              slotStart: '${9 + _random.nextInt(8)}:00',
              slotEnd: '${10 + _random.nextInt(8)}:00',
              isBooked: _random.nextBool(),
              updatedAt: DateTime.now(),
            );
            await _localDb.createAvailability(availability);
          }
        } else {
          mentors.add(existingMentor);
        }
      }
    } else {
      // Load existing mentors for relationships
      mentors = await _localDb.getUsersByType('mentor');
    }

    // Generate mentees and create mentorships
    List<User> mentees = [];
    if (includeMentees && mentors.isNotEmpty) {
      int menteeCounter = 0;
      
      // Assign mentees to mentors (0-3 mentees per mentor)
      for (int mentorIndex = 0; mentorIndex < mentors.length; mentorIndex++) {
        final mentor = mentors[mentorIndex];
        
        // Randomly decide how many mentees this mentor will have (0-3)
        final menteesForThisMentor = _random.nextInt(4); // 0, 1, 2, or 3
        
        // Track mentee IDs for this mentor
        List<String> menteeIds = [];
        
        for (int j = 0; j < menteesForThisMentor; j++) {
          menteeCounter++;
          
          // Check if mentee already exists
          final existingMentee = await _localDb.getUserByEmail('mentee${menteeCounter}@ucmerced.edu');
          if (existingMentee == null) {
            final mentee = User(
              id: _localDb.generateId(),
              name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
              email: 'mentee${menteeCounter}@ucmerced.edu',
              userType: 'mentee',
              studentId: 'S${(3000 + menteeCounter).toString()}',
              mentor: mentor.studentId,
              acknowledgmentSigned: _random.nextBool() ? 'yes' : 'no',
              createdAt: DateTime.now().subtract(Duration(days: 200 - menteeCounter * 10)),
            );
            await _localDb.createUser(mentee);
            mentees.add(mentee);
            menteeIds.add(mentee.studentId!);

            // Create mentorship relationship
            final mentorship = Mentorship(
              id: _localDb.generateId(),
              mentorId: mentor.id,
              menteeId: mentee.id,
              createdAt: mentee.createdAt,
            );
            await _localDb.createMentorship(mentorship);

            // Generate checklist items for each mentee
            for (int k = 0; k < 5; k++) {
              final checklist = Checklist(
                id: _localDb.generateId(),
                userId: mentee.id,
                title: 'Task ${k + 1} for ${mentee.name.split(' ')[0]}',
                isCompleted: _random.nextBool(),
                category: _checklistCategories[_random.nextInt(_checklistCategories.length)],
                dueDate: DateTime.now().add(Duration(days: _random.nextInt(60))).toIso8601String(),
                assignedBy: mentor.studentId,
                createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
              );
              await _localDb.createChecklist(checklist);
            }
          } else {
            mentees.add(existingMentee);
            menteeIds.add(existingMentee.studentId!);
          }
        }
        
        // Update mentor's mentee list if they have mentees
        if (menteeIds.isNotEmpty) {
          // Update the mentor with their mentee list
          final updatedMentor = mentor.copyWith(
            mentee: json.encode(menteeIds),
          );
          await _localDb.updateUser(updatedMentor);
        }
      }
    } else {
      // Load existing mentees
      mentees = await _localDb.getUsersByType('mentee');
    }

    // Generate meetings (only if we have both mentors and mentees)
    if (mentors.isNotEmpty && mentees.isNotEmpty) {
      for (int i = 0; i < 20; i++) {
        final mentor = mentors[_random.nextInt(mentors.length)];
        final mentorshipList = await _localDb.getMentorshipsByMentor(mentor.id);
        if (mentorshipList.isNotEmpty) {
          final mentorship = mentorshipList[_random.nextInt(mentorshipList.length)];
          final startTime = DateTime.now().subtract(Duration(days: _random.nextInt(30)));
          
          final meeting = Meeting(
            id: _localDb.generateId(),
            mentorId: mentorship.mentorId,
            menteeId: mentorship.menteeId,
            startTime: startTime.toIso8601String(),
            endTime: startTime.add(Duration(hours: 1)).toIso8601String(),
            topic: _meetingTopics[_random.nextInt(_meetingTopics.length)],
            status: ['pending', 'accepted', 'rejected'][_random.nextInt(3)],
            createdAt: startTime.subtract(Duration(days: _random.nextInt(5))),
          );
          await _localDb.createMeeting(meeting);
        }
      }
    }

    // Generate announcements (only if we have coordinators)
    if (coordinators.isNotEmpty) {
      for (int i = 0; i < 10; i++) {
        final createdAt = DateTime.now().subtract(Duration(days: _random.nextInt(30)));
        final announcement = Announcement(
          id: _localDb.generateId(),
          title: 'Announcement ${i + 1}',
          content: 'This is the content for announcement ${i + 1}. Important information for all participants.',
          time: _getRelativeTime(createdAt),
          priority: ['high', 'medium', 'low', 'none'][_random.nextInt(4)],
          targetAudience: ['mentors', 'mentees', 'both'][_random.nextInt(3)],
          createdAt: createdAt,
          createdBy: coordinators[_random.nextInt(coordinators.length)].id,
        );
        await _localDb.createAnnouncement(announcement);
      }
    }

    // Generate messages between mentors and mentees
    for (final mentorship in await _localDb.getMentorshipsByMentor(mentors[0].id)) {
      final chatId = '${mentorship.mentorId}__${mentorship.menteeId}';
      for (int i = 0; i < 10; i++) {
        final message = Message(
          id: _localDb.generateId(),
          chatId: chatId,
          senderId: _random.nextBool() ? mentorship.mentorId : mentorship.menteeId,
          message: 'Message ${i + 1} in this conversation',
          sentAt: DateTime.now().subtract(Duration(hours: _random.nextInt(72))),
        );
        await _localDb.createMessage(message);
      }
    }

    // Generate events
    for (int i = 0; i < 8; i++) {
      final startTime = DateTime.now().add(Duration(days: _random.nextInt(60)));
      final event = Event(
        id: _localDb.generateId(),
        title: 'Event ${i + 1}: ${_eventTypes[i % _eventTypes.length].toUpperCase()} Session',
        description: 'Description for event ${i + 1}. Join us for this important session.',
        location: _random.nextBool() ? 'Room ${100 + _random.nextInt(400)}' : 'Virtual - Zoom Link',
        startTime: startTime,
        endTime: startTime.add(Duration(hours: 2)),
        createdBy: coordinators[_random.nextInt(coordinators.length)].id,
        eventType: _eventTypes[i % _eventTypes.length],
        targetAudience: ['mentors', 'mentees', 'both', 'all'][_random.nextInt(4)],
        maxParticipants: _random.nextBool() ? 20 + _random.nextInt(80) : null,
        requiredRegistration: _random.nextBool(),
        createdAt: DateTime.now(),
      );
      await _localDb.createEvent(event);
    }
  }

  static String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}