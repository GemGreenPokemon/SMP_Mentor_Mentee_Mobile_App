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
import '../models/mentee_goal.dart';
import '../models/action_item.dart';
import '../models/notification.dart' as app_notification;
import '../models/meeting_note.dart';
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

  static const List<String> _departments = [
    'Computer Science', 'Engineering', 'Biology', 'Chemistry', 
    'Mathematics', 'Physics', 'Psychology', 'Business'
  ];

  static const List<String> _years = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate'
  ];

  static const List<String> _majors = [
    'Computer Science', 'Electrical Engineering', 'Mechanical Engineering',
    'Bioengineering', 'Applied Mathematics', 'Data Science', 'Chemistry', 'Physics'
  ];

  static const List<String> _goalTitles = [
    'Complete research project proposal',
    'Improve GPA to 3.5 or higher',
    'Apply for summer internships',
    'Join professional organizations',
    'Develop networking skills',
    'Master advanced programming concepts',
    'Publish first research paper',
    'Prepare for graduate school applications'
  ];

  static const List<String> _actionTasks = [
    'Schedule weekly check-in meetings',
    'Review and update resume',
    'Complete online certification course',
    'Attend career fair',
    'Submit internship applications',
    'Practice technical interview questions',
    'Join study group for difficult course',
    'Meet with academic advisor'
  ];

  static const List<String> _mentorNotes = [
    'Student showed great enthusiasm for the project. We discussed potential research opportunities and identified three areas of interest.',
    'Reviewed midterm grades and developed a study plan for the remaining semester. Student is struggling with calculus but making progress.',
    'Excellent progress on resume development. Added two new projects and updated skills section. Ready for internship applications.',
    'Discussed career goals and potential graduate school options. Student is interested in pursuing a PhD in computer science.',
    'Student presented their research proposal. Needs to narrow down the scope and add more technical details.',
    'Great meeting discussing time management strategies. Student has been overwhelmed but now has a clear weekly schedule.',
    'Explored networking opportunities and professional development resources. Set up LinkedIn profile and joined relevant organizations.',
    'Student is excelling in coursework and showing leadership potential. Discussed opportunities to mentor other students.'
  ];

  static const List<String> _menteeNotes = [
    'Found the discussion about research methods very helpful. Will follow up on the resources suggested and prepare a draft.',
    'Appreciate the guidance on study strategies. The techniques discussed should help with upcoming exams.',
    'Great feedback on my resume. The suggested changes make it much stronger for internship applications.',
    'Valuable insights about graduate school requirements. Now have a clear timeline for applications.',
    'The research presentation feedback was constructive. Will revise the proposal based on the suggestions.',
    'Time management tips are already making a difference. Feeling more organized and less stressed.',
    'Networking advice was extremely helpful. Already connected with several professionals in my field.',
    'Inspired by the mentorship opportunities discussed. Excited to give back to younger students.'
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
            department: 'Student Affairs',
            yearMajor: 'Staff',
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
          final randomMajor = _majors[_random.nextInt(_majors.length)];
          final mentor = User(
            id: _localDb.generateId(),
            name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
            email: 'mentor${i + 1}@ucmerced.edu',
            userType: 'mentor',
            studentId: 'M${(2000 + i).toString()}',
            department: _departments[_random.nextInt(_departments.length)],
            yearMajor: '${_years[2 + _random.nextInt(3)]}, $randomMajor Major',
            createdAt: DateTime.now().subtract(Duration(days: 300 - i * 20)),
          );
          await _localDb.createUser(mentor);
          mentors.add(mentor);

          // Generate availability for each mentor
          await _generateAvailabilityForMentor(mentor);
        } else {
          mentors.add(existingMentor);
          // Generate availability for existing mentor if they don't have any
          final existingAvailability = await _localDb.getAvailabilityByMentor(existingMentor.id);
          if (existingAvailability.isEmpty) {
            await _generateAvailabilityForMentor(existingMentor);
          }
        }
      }
    } else {
      // Load existing mentors for relationships
      mentors = await _localDb.getUsersByType('mentor');
      // Generate availability for existing mentors if they don't have any
      for (final mentor in mentors) {
        final existingAvailability = await _localDb.getAvailabilityByMentor(mentor.id);
        if (existingAvailability.isEmpty) {
          await _generateAvailabilityForMentor(mentor);
        }
      }
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
            final randomMajor = _majors[_random.nextInt(_majors.length)];
            final mentee = User(
              id: _localDb.generateId(),
              name: '${_firstNames[_random.nextInt(_firstNames.length)]} ${_lastNames[_random.nextInt(_lastNames.length)]}',
              email: 'mentee${menteeCounter}@ucmerced.edu',
              userType: 'mentee',
              studentId: 'S${(3000 + menteeCounter).toString()}',
              mentor: mentor.studentId,
              acknowledgmentSigned: _random.nextBool() ? 'yes' : 'no',
              department: _departments[_random.nextInt(_departments.length)],
              yearMajor: '${_years[_random.nextInt(2)]}, $randomMajor Major',
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
              assignedBy: coordinators.isNotEmpty ? coordinators[0].id : null,
              overallProgress: _random.nextDouble() * 100, // Random progress 0-100
              createdAt: mentee.createdAt,
            );
            await _localDb.createMentorship(mentorship);

            // Generate mentee goals for this mentorship
            for (int g = 0; g < 3 + _random.nextInt(3); g++) {
              final goal = MenteeGoal(
                id: _localDb.generateId(),
                mentorshipId: mentorship.id,
                title: _goalTitles[_random.nextInt(_goalTitles.length)],
                progress: _random.nextDouble() * 100,
                createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(60))),
                updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(7))),
              );
              await _localDb.createMenteeGoal(goal);
            }

            // Generate action items for this mentorship
            for (int a = 0; a < 2 + _random.nextInt(4); a++) {
              final dueDate = DateTime.now().add(Duration(days: _random.nextInt(30)));
              final actionItem = ActionItem(
                id: _localDb.generateId(),
                mentorshipId: mentorship.id,
                task: _actionTasks[_random.nextInt(_actionTasks.length)],
                description: 'Additional details for this task',
                dueDate: dueDate.toIso8601String(),
                completed: _random.nextDouble() < 0.3, // 30% chance of being completed
                createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(14))),
              );
              await _localDb.createActionItem(actionItem);
            }

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
      await _generateMeetingsWithAvailability(mentors, mentees);
    }

    // Generate meeting notes for existing meetings
    if (mentors.isNotEmpty && mentees.isNotEmpty) {
      final allMeetings = await _localDb.getTableData('meetings');
      
      for (final meetingMap in allMeetings) {
        final meeting = Meeting.fromMap(meetingMap);
        final meetingDate = DateTime.tryParse(meeting.startTime);
        
        // Only create notes for past meetings (meetings that have happened)
        if (meetingDate != null && meetingDate.isBefore(DateTime.now())) {
          // Get mentor and mentee for this meeting
          final mentor = mentors.firstWhere((m) => m.id == meeting.mentorId, orElse: () => mentors.first);
          final mentee = mentees.firstWhere((m) => m.id == meeting.menteeId, orElse: () => mentees.first);
          
          // 70% chance of having mentor notes
          if (_random.nextDouble() < 0.7) {
            final mentorNote = MeetingNote(
              id: _localDb.generateId(),
              meetingId: meeting.id,
              authorId: mentor.id,
              isMentor: true,
              isShared: _random.nextBool(), // 50% chance of being shared
              rawNote: _mentorNotes[_random.nextInt(_mentorNotes.length)],
              organizedNote: _random.nextBool() ? 'AI-organized version of the meeting notes with key points highlighted.' : null,
              isAiGenerated: _random.nextDouble() < 0.3, // 30% chance of AI generation
              createdAt: meetingDate.add(Duration(minutes: 15 + _random.nextInt(120))), // Created 15-135 minutes after meeting
              updatedAt: _random.nextBool() ? meetingDate.add(Duration(hours: 1 + _random.nextInt(24))) : null,
            );
            await _localDb.createMeetingNote(mentorNote);
          }
          
          // 60% chance of having mentee notes
          if (_random.nextDouble() < 0.6) {
            final menteeNote = MeetingNote(
              id: _localDb.generateId(),
              meetingId: meeting.id,
              authorId: mentee.id,
              isMentor: false,
              isShared: _random.nextDouble() < 0.8, // 80% chance of sharing mentee notes
              rawNote: _menteeNotes[_random.nextInt(_menteeNotes.length)],
              organizedNote: null, // Mentees typically don't use AI organization
              isAiGenerated: false,
              createdAt: meetingDate.add(Duration(minutes: 30 + _random.nextInt(180))), // Created 30-210 minutes after meeting
              updatedAt: _random.nextBool() ? meetingDate.add(Duration(hours: 2 + _random.nextInt(48))) : null,
            );
            await _localDb.createMeetingNote(menteeNote);
          }
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

    // Generate messages between mentors and mentees (only if we have mentors)
    if (mentors.isNotEmpty) {
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
    }

    // Generate events (only if we have coordinators)
    if (coordinators.isNotEmpty) {
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

    // Generate notifications for all users
    final allUsers = [...coordinators, ...mentors, ...mentees];
    for (final user in allUsers) {
      // Generate 2-5 notifications per user
      for (int i = 0; i < 2 + _random.nextInt(4); i++) {
        final notificationType = ['meeting', 'report', 'announcement', 'task'][_random.nextInt(4)];
        String title;
        String message;
        
        switch (notificationType) {
          case 'meeting':
            title = 'Upcoming Meeting Reminder';
            message = 'You have a meeting scheduled tomorrow at 2:00 PM';
            break;
          case 'report':
            title = 'Progress Report Due';
            message = 'Your monthly progress report is due in 3 days';
            break;
          case 'announcement':
            title = 'New Announcement';
            message = 'A new announcement has been posted for your program';
            break;
          case 'task':
            title = 'Task Reminder';
            message = 'You have 2 pending tasks due this week';
            break;
          default:
            title = 'Notification';
            message = 'You have a new notification';
        }
        
        final notification = app_notification.Notification(
          id: _localDb.generateId(),
          userId: user.id,
          title: title,
          message: message,
          type: notificationType,
          priority: ['high', 'medium', 'low'][_random.nextInt(3)],
          read: _random.nextDouble() < 0.6, // 60% chance of being read
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(14))),
        );
        await _localDb.createNotification(notification);
      }
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

  // Generate realistic availability slots for a mentor
  static Future<void> _generateAvailabilityForMentor(User mentor) async {
    final timeSlots = [
      '9:00 AM', '10:00 AM', '11:00 AM', 
      '2:00 PM', '3:00 PM', '4:00 PM'
    ];
    
    // Generate availability for next 30 days (starting from today)
    final now = DateTime.now();
    for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
      final currentDate = now.add(Duration(days: dayOffset));
      final dayOfWeek = currentDate.weekday;
      
      // Skip weekends
      if (dayOfWeek == 6 || dayOfWeek == 7) continue;
      
      // Format date as YYYY-MM-DD
      final dateString = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      
      // Randomly select 2-4 time slots for this day
      final numSlots = 2 + _random.nextInt(3);
      final selectedSlots = List<String>.from(timeSlots)..shuffle(_random);
      
      for (int i = 0; i < numSlots && i < selectedSlots.length; i++) {
        final availability = Availability(
          id: _localDb.generateId(),
          mentorId: mentor.id,
          day: dateString,
          slotStart: selectedSlots[i],
          slotEnd: _getEndTime(selectedSlots[i]), // Add end time
          isBooked: false, // Initially all slots are available
          menteeId: null,
          updatedAt: DateTime.now(),
        );
        await _localDb.createAvailability(availability);
      }
    }
  }

  // Generate meetings that properly link to availability slots
  static Future<void> _generateMeetingsWithAvailability(List<User> mentors, List<User> mentees) async {
    final now = DateTime.now();
    
    // Create past meetings (for testing meeting history)
    print('DEBUG: Creating ${10} past meetings...');
    for (int i = 0; i < 10; i++) {
      final mentor = mentors[_random.nextInt(mentors.length)];
      final mentorshipList = await _localDb.getMentorshipsByMentor(mentor.id);
      if (mentorshipList.isNotEmpty) {
        final mentorship = mentorshipList[_random.nextInt(mentorshipList.length)];
        final startTime = now.subtract(Duration(days: _random.nextInt(30) + 1)); // Past dates
        
        final meeting = Meeting(
          id: _localDb.generateId(),
          mentorId: mentorship.mentorId,
          menteeId: mentorship.menteeId,
          startTime: startTime.toIso8601String(),
          endTime: startTime.add(Duration(hours: 1)).toIso8601String(),
          topic: _meetingTopics[_random.nextInt(_meetingTopics.length)],
          location: _random.nextBool() ? 'Room ${100 + _random.nextInt(400)}' : 'Virtual - Zoom',
          status: 'accepted', // Past meetings are accepted
          availabilityId: null, // Past meetings don't link to availability slots
          createdAt: startTime.subtract(Duration(days: _random.nextInt(5))),
        );
        print('DEBUG: Created past meeting ${meeting.id} with topic: ${meeting.topic}, location: ${meeting.location}');
        await _localDb.createMeeting(meeting);
      }
    }
    
    // Create future meetings by booking availability slots
    final allAvailability = await _localDb.getTableData('availability');
    print('DEBUG: Found ${allAvailability.length} total availability slots in database');
    
    final availableSlots = allAvailability.where((slot) {
      final slotDate = DateTime.tryParse(slot['day']);
      final isAfterNow = slotDate != null && slotDate.isAfter(now);
      final isNotBooked = slot['is_booked'] == 0;
      print('DEBUG: Slot ${slot['id']} on ${slot['day']} at ${slot['slot_start']}: afterNow=$isAfterNow, notBooked=$isNotBooked');
      return isAfterNow && isNotBooked;
    }).toList();
    
    // Book some availability slots with meetings
    final numMeetingsToCreate = (availableSlots.length * 0.3).round(); // Book 30% of available slots
    print('DEBUG: Selected ${availableSlots.length} available slots for future meetings, will create ${numMeetingsToCreate} meetings');
    availableSlots.shuffle(_random);
    
    for (int i = 0; i < numMeetingsToCreate && i < availableSlots.length; i++) {
      final slot = availableSlots[i];
      final mentorId = slot['mentor_id'];
      
      print('DEBUG: Creating meeting for availability slot: ${slot['id']} on ${slot['day']} at ${slot['slot_start']}');
      
      // Find a mentee for this mentor
      final mentorshipList = await _localDb.getMentorshipsByMentor(mentorId);
      if (mentorshipList.isNotEmpty) {
        final mentorship = mentorshipList[_random.nextInt(mentorshipList.length)];
        
        // Parse the slot date and start time
        final slotDate = DateTime.parse(slot['day']);
        final startTimeStr = slot['slot_start'];
        final startTime = _parseDateTime(slotDate, startTimeStr);
        
        // Determine meeting status
        final statuses = ['pending', 'accepted'];
        final status = statuses[_random.nextInt(statuses.length)];
        
        final meeting = Meeting(
          id: _localDb.generateId(),
          mentorId: mentorship.mentorId,
          menteeId: mentorship.menteeId,
          startTime: startTime.toIso8601String(),
          endTime: startTime.add(Duration(hours: 1)).toIso8601String(),
          topic: _meetingTopics[_random.nextInt(_meetingTopics.length)],
          location: _random.nextBool() ? 'Room ${100 + _random.nextInt(400)}' : 'Virtual - Zoom',
          status: status,
          availabilityId: slot['id'],
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(5))),
        );
        
        print('DEBUG: Created meeting ${meeting.id} with availabilityId: ${meeting.availabilityId}, topic: ${meeting.topic}, location: ${meeting.location}, status: ${meeting.status}');
        await _localDb.createMeeting(meeting);
        
        // Update the availability slot to mark it as booked
        if (status == 'accepted') {
          print('DEBUG: Booking availability slot ${slot['id']} for mentee ${mentorship.menteeId}');
          await _localDb.bookAvailabilitySlot(slot['id'], mentorship.menteeId);
        } else {
          print('DEBUG: Leaving slot ${slot['id']} unbooked (pending status)');
        }
      } else {
        print('DEBUG: No mentorships found for mentor ${mentorId}, skipping meeting creation');
      }
    }
  }
  
  // Helper function to get end time for a time slot
  static String _getEndTime(String startTime) {
    final timeSlotDuration = {'9:00 AM': '10:00 AM', '10:00 AM': '11:00 AM', '11:00 AM': '12:00 PM',
                             '2:00 PM': '3:00 PM', '3:00 PM': '4:00 PM', '4:00 PM': '5:00 PM'};
    return timeSlotDuration[startTime] ?? '${startTime.replaceAll(RegExp(r'\d+'), '${int.parse(startTime.split(':')[0]) + 1}')}:00 ${startTime.contains('AM') ? 'AM' : 'PM'}';
  }
  
  // Helper function to parse date and time string into DateTime
  static DateTime _parseDateTime(DateTime date, String timeStr) {
    final parts = timeStr.split(' ');
    final timePart = parts[0].split(':');
    int hour = int.parse(timePart[0]);
    final minute = int.parse(timePart[1]);
    final isAM = parts[1] == 'AM';
    
    if (!isAM && hour != 12) hour += 12;
    if (isAM && hour == 12) hour = 0;
    
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}