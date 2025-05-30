import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/services/local_database_service.dart';
import 'lib/utils/test_mode_manager.dart';

void main() async {
  // Initialize FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  print('=== Calendar Debug Tool ===\n');
  
  final localDb = LocalDatabaseService.instance;
  
  try {
    // Check test mode user
    await TestModeManager.initialize();
    final currentUser = TestModeManager.currentTestUser;
    print('Current test user: ${currentUser?.name ?? 'None'} (${currentUser?.id ?? 'N/A'})');
    print('User type: ${currentUser?.userType ?? 'N/A'}\n');
    
    // Check total counts
    final userCount = await localDb.getUsersCount();
    final availabilityCount = await localDb.getAvailabilityCount();
    final meetingCount = await localDb.getMeetingsCount();
    
    print('Database counts:');
    print('- Users: $userCount');
    print('- Availability records: $availabilityCount');
    print('- Meetings: $meetingCount\n');
    
    // Get all users
    final users = await localDb.getAllUsers();
    print('Users in database:');
    for (final user in users) {
      print('- ${user.name} (${user.userType}) - ID: ${user.id}');
    }
    print('');
    
    if (currentUser != null) {
      // Check availability for current user
      print('Availability for current user (${currentUser.name}):');
      final availability = await localDb.getAvailabilityByMentor(currentUser.id);
      print('Found ${availability.length} availability records:');
      for (final slot in availability.take(10)) { // Show first 10
        print('- Date: ${slot.day}, Time: ${slot.slotStart}, Booked: ${slot.isBooked}');
      }
      print('');
      
      // Check meetings for current user
      print('Meetings for current user:');
      final meetings = currentUser.userType == 'mentor' 
          ? await localDb.getMeetingsByMentor(currentUser.id)
          : await localDb.getMeetingsByMentee(currentUser.id);
      print('Found ${meetings.length} meetings:');
      for (final meeting in meetings.take(10)) { // Show first 10
        print('- Start: ${meeting.startTime}, Status: ${meeting.status}, Topic: ${meeting.topic}');
      }
      print('');
    }
    
    // Test calendar date parsing
    print('Testing date parsing:');
    final testDate = DateTime(2025, 5, 30);
    final testDateStr = '${testDate.year}-${testDate.month.toString().padLeft(2, '0')}-${testDate.day.toString().padLeft(2, '0')}';
    print('Test date: $testDate');
    print('Formatted as: $testDateStr');
    final parsedDate = DateTime.tryParse(testDateStr);
    print('Parsed back: $parsedDate');
    print('Parsing successful: ${parsedDate != null}\n');
    
    // Check a few specific availability records
    print('Sample availability records (raw data):');
    final rawAvailability = await localDb.getTableData('availability');
    for (final record in rawAvailability.take(5)) {
      print('- ID: ${record['id']}, Day: ${record['day']}, Time: ${record['slot_start']}, Booked: ${record['is_booked']}');
    }
    print('');
    
    // Check a few specific meeting records
    print('Sample meeting records (raw data):');
    final rawMeetings = await localDb.getTableData('meetings');
    for (final record in rawMeetings.take(5)) {
      print('- ID: ${record['id']}, Start: ${record['start_time']}, Status: ${record['status']}');
    }
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\n=== Debug Complete ===');
  exit(0);
}