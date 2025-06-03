import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
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

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  final _uuid = const Uuid();

  LocalDatabaseService._init();

  Future<Database> get database async => DatabaseHelper.instance.database;

  // ========== USER OPERATIONS ==========
  Future<User> createUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
    return user;
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Alias for getUser to match naming convention
  Future<User?> getUserById(String id) => getUser(id);

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<List<User>> getUsersByType(String userType) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'userType = ?',
      whereArgs: [userType],
    );
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getUsersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int;
  }

  // ========== MENTORSHIP OPERATIONS ==========
  Future<Mentorship> createMentorship(Mentorship mentorship) async {
    final db = await database;
    await db.insert('mentorships', mentorship.toMap());
    return mentorship;
  }

  Future<List<Mentorship>> getMentorshipsByMentor(String mentorId) async {
    final db = await database;
    final result = await db.query(
      'mentorships',
      where: 'mentor_id = ?',
      whereArgs: [mentorId],
    );
    return result.map((map) => Mentorship.fromMap(map)).toList();
  }

  Future<List<Mentorship>> getMentorshipsByMentee(String menteeId) async {
    final db = await database;
    final result = await db.query(
      'mentorships',
      where: 'mentee_id = ?',
      whereArgs: [menteeId],
    );
    return result.map((map) => Mentorship.fromMap(map)).toList();
  }

  Future<int> getMentorshipsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM mentorships');
    return result.first['count'] as int;
  }

  // ========== AVAILABILITY OPERATIONS ==========
  Future<Availability> createAvailability(Availability availability) async {
    final db = await database;
    await db.insert('availability', availability.toMap());
    return availability;
  }

  Future<List<Availability>> getAvailabilityByMentor(String mentorId) async {
    final db = await database;
    final result = await db.query(
      'availability',
      where: 'mentor_id = ?',
      whereArgs: [mentorId],
    );
    return result.map((map) => Availability.fromMap(map)).toList();
  }

  Future<int> updateAvailability(Availability availability) async {
    final db = await database;
    return db.update(
      'availability',
      availability.toMap(),
      where: 'id = ?',
      whereArgs: [availability.id],
    );
  }

  Future<int> getAvailabilityCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM availability');
    return result.first['count'] as int;
  }

  // ========== MEETING OPERATIONS ==========
  Future<Meeting> createMeeting(Meeting meeting) async {
    final db = await database;
    await db.insert('meetings', meeting.toMap());
    return meeting;
  }

  Future<List<Meeting>> getMeetingsByMentee(String menteeId) async {
    final db = await database;
    final result = await db.query(
      'meetings',
      where: 'mentee_id = ?',
      whereArgs: [menteeId],
    );
    return result.map((map) => Meeting.fromMap(map)).toList();
  }

  Future<int> updateMeeting(Meeting meeting) async {
    final db = await database;
    return db.update(
      'meetings',
      meeting.toMap(),
      where: 'id = ?',
      whereArgs: [meeting.id],
    );
  }

  /// Cancel a meeting and free up the availability slot
  Future<bool> cancelMeeting(String meetingId) async {
    final db = await database;
    
    try {
      // First get the meeting to find the availability slot
      final meetingMaps = await db.query(
        'meetings',
        where: 'id = ?',
        whereArgs: [meetingId],
      );
      
      if (meetingMaps.isEmpty) return false;
      
      final meeting = Meeting.fromMap(meetingMaps.first);
      
      // Update meeting status to cancelled
      final updatedMeeting = meeting.copyWith(status: 'cancelled');
      await db.update(
        'meetings',
        updatedMeeting.toMap(),
        where: 'id = ?',
        whereArgs: [meetingId],
      );
      
      // If there's an associated availability slot, free it up
      if (meeting.availabilityId != null) {
        await unbookAvailabilitySlot(meeting.availabilityId!);
      }
      
      return true;
    } catch (e) {
      print('Error cancelling meeting: $e');
      return false;
    }
  }

  Future<int> getMeetingsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM meetings');
    return result.first['count'] as int;
  }

  Future<List<Meeting>> getMeetingsByMentorship(String mentorId, String menteeId) async {
    final db = await database;
    final maps = await db.query(
      'meetings',
      where: 'mentor_id = ? AND mentee_id = ?',
      whereArgs: [mentorId, menteeId],
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => Meeting.fromMap(map)).toList();
  }
  
  Future<List<Meeting>> getMeetingsByMentor(String mentorId) async {
    final db = await database;
    final maps = await db.query(
      'meetings',
      where: 'mentor_id = ?',
      whereArgs: [mentorId],
      orderBy: 'start_time ASC',
    );
    return maps.map((map) => Meeting.fromMap(map)).toList();
  }

  // ========== ANNOUNCEMENT OPERATIONS ==========
  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final db = await database;
    await db.insert('announcements', announcement.toMap());
    return announcement;
  }

  Future<List<Announcement>> getAnnouncements({String? targetAudience}) async {
    final db = await database;
    if (targetAudience != null) {
      final result = await db.query(
        'announcements',
        where: 'target_audience = ? OR target_audience = ?',
        whereArgs: [targetAudience, 'both'],
        orderBy: 'created_at DESC',
      );
      return result.map((map) => Announcement.fromMap(map)).toList();
    } else {
      final result = await db.query('announcements', orderBy: 'created_at DESC');
      return result.map((map) => Announcement.fromMap(map)).toList();
    }
  }

  Future<List<Announcement>> getAnnouncementsByAudience(List<String> audiences) async {
    final db = await database;
    final placeholders = audiences.map((_) => '?').join(', ');
    final result = await db.query(
      'announcements',
      where: 'target_audience IN ($placeholders)',
      whereArgs: audiences,
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Announcement.fromMap(map)).toList();
  }

  // ========== CHECKLIST OPERATIONS ==========
  Future<Checklist> createChecklist(Checklist checklist) async {
    final db = await database;
    await db.insert('checklists', checklist.toMap());
    return checklist;
  }

  Future<List<Checklist>> getChecklistsByUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'checklists',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Checklist.fromMap(map)).toList();
  }

  Future<int> updateChecklist(Checklist checklist) async {
    final db = await database;
    return db.update(
      'checklists',
      checklist.toMap(),
      where: 'id = ?',
      whereArgs: [checklist.id],
    );
  }

  // ========== MESSAGE OPERATIONS ==========
  Future<Message> createMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
    return message;
  }

  Future<List<Message>> getMessagesByChat(String chatId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'sent_at ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }
  
  /// Get messages for a chat, excluding those hidden by the user
  Future<List<Message>> getVisibleMessagesByChat(String chatId, String userId) async {
    final db = await database;
    // Get all messages that are NOT hidden by this user
    final result = await db.rawQuery('''
      SELECT m.* FROM messages m
      LEFT JOIN message_visibility mv ON m.id = mv.message_id AND mv.user_id = ?
      WHERE m.chat_id = ? AND mv.id IS NULL
      ORDER BY m.sent_at ASC
    ''', [userId, chatId]);
    return result.map((map) => Message.fromMap(map)).toList();
  }
  
  /// Hide messages for a specific user (clear chat for me)
  Future<void> hideMessagesForUser(String chatId, String userId) async {
    final db = await database;
    
    // Get all messages in the chat
    final messages = await getMessagesByChat(chatId);
    
    // Mark all messages as hidden for this user
    final batch = db.batch();
    final hiddenAt = DateTime.now().millisecondsSinceEpoch;
    
    for (final message in messages) {
      batch.insert(
        'message_visibility',
        {
          'user_id': userId,
          'message_id': message.id,
          'hidden_at': hiddenAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  /// Clear all hidden messages for a user in a chat
  Future<void> unhideMessagesForUser(String chatId, String userId) async {
    final db = await database;
    
    // Get message IDs for this chat
    final messages = await getMessagesByChat(chatId);
    final messageIds = messages.map((m) => m.id).toList();
    
    if (messageIds.isNotEmpty) {
      final placeholders = messageIds.map((_) => '?').join(', ');
      await db.delete(
        'message_visibility',
        where: 'user_id = ? AND message_id IN ($placeholders)',
        whereArgs: [userId, ...messageIds],
      );
    }
  }

  // ========== EVENT OPERATIONS ==========
  Future<Event> createEvent(Event event) async {
    final db = await database;
    await db.insert('events', event.toMap());
    return event;
  }

  Future<List<Event>> getUpcomingEvents() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await db.query(
      'events',
      where: 'start_time > ?',
      whereArgs: [now],
      orderBy: 'start_time ASC',
    );
    return result.map((map) => Event.fromMap(map)).toList();
  }

  // ========== TABLE OPERATIONS ==========
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<int> getTableCount(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }

  // ========== MENTEE GOALS OPERATIONS ==========
  Future<MenteeGoal> createMenteeGoal(MenteeGoal goal) async {
    final db = await database;
    await db.insert('mentee_goals', goal.toMap());
    return goal;
  }

  Future<List<MenteeGoal>> getGoalsByMentorship(String mentorshipId) async {
    final db = await database;
    final maps = await db.query(
      'mentee_goals',
      where: 'mentorship_id = ?',
      whereArgs: [mentorshipId],
    );
    return maps.map((map) => MenteeGoal.fromMap(map)).toList();
  }

  Future<int> updateGoalProgress(String goalId, double progress) async {
    final db = await database;
    return db.update(
      'mentee_goals',
      {'progress': progress, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<int> deleteGoal(String id) async {
    final db = await database;
    return db.delete(
      'mentee_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== ACTION ITEMS OPERATIONS ==========
  Future<ActionItem> createActionItem(ActionItem item) async {
    final db = await database;
    await db.insert('action_items', item.toMap());
    return item;
  }

  Future<List<ActionItem>> getActionItemsByMentorship(String mentorshipId) async {
    final db = await database;
    final maps = await db.query(
      'action_items',
      where: 'mentorship_id = ?',
      whereArgs: [mentorshipId],
    );
    return maps.map((map) => ActionItem.fromMap(map)).toList();
  }

  Future<int> completeActionItem(String itemId) async {
    final db = await database;
    return db.update(
      'action_items',
      {'completed': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> updateActionItem(ActionItem item) async {
    final db = await database;
    return db.update(
      'action_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteActionItem(String id) async {
    final db = await database;
    return db.delete(
      'action_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== NOTIFICATIONS OPERATIONS ==========
  Future<app_notification.Notification> createNotification(app_notification.Notification notification) async {
    final db = await database;
    await db.insert('notifications', notification.toMap());
    return notification;
  }

  Future<List<app_notification.Notification>> getNotificationsByUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => app_notification.Notification.fromMap(map)).toList();
  }

  Future<List<app_notification.Notification>> getUnreadNotifications(String userId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'user_id = ? AND read = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => app_notification.Notification.fromMap(map)).toList();
  }

  Future<int> markNotificationAsRead(String notificationId) async {
    final db = await database;
    return db.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<int> deleteNotification(String id) async {
    final db = await database;
    return db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== MEETING NOTES OPERATIONS ==========
  Future<MeetingNote> createMeetingNote(MeetingNote note) async {
    final db = await database;
    await db.insert('meeting_notes', note.toMap());
    return note;
  }

  Future<List<MeetingNote>> getMeetingNotesByMeeting(String meetingId) async {
    final db = await database;
    final maps = await db.query(
      'meeting_notes',
      where: 'meeting_id = ?',
      whereArgs: [meetingId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => MeetingNote.fromMap(map)).toList();
  }

  Future<List<MeetingNote>> getMeetingNotesByAuthor(String authorId) async {
    final db = await database;
    final maps = await db.query(
      'meeting_notes',
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => MeetingNote.fromMap(map)).toList();
  }

  Future<List<MeetingNote>> getMeetingNotesByMentorship(String mentorId, String menteeId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT mn.* FROM meeting_notes mn
      INNER JOIN meetings m ON mn.meeting_id = m.id
      WHERE m.mentor_id = ? AND m.mentee_id = ?
      ORDER BY mn.created_at DESC
    ''', [mentorId, menteeId]);
    return maps.map((map) => MeetingNote.fromMap(map)).toList();
  }

  Future<List<MeetingNote>> getSharedMeetingNotes(String meetingId) async {
    final db = await database;
    final maps = await db.query(
      'meeting_notes',
      where: 'meeting_id = ? AND is_shared = 1',
      whereArgs: [meetingId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => MeetingNote.fromMap(map)).toList();
  }

  Future<int> updateMeetingNote(MeetingNote note) async {
    final db = await database;
    return db.update(
      'meeting_notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> shareMeetingNote(String noteId, bool isShared) async {
    final db = await database;
    return db.update(
      'meeting_notes',
      {
        'is_shared': isShared ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<int> deleteMeetingNote(String id) async {
    final db = await database;
    return db.delete(
      'meeting_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getMeetingNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM meeting_notes');
    return result.first['count'] as int;
  }

  // The missing availability methods that were added below
  Future<List<Availability>> getAvailabilityByDay(String mentorId, String day) async {
    final db = await database;
    final maps = await db.query(
      'availability',
      where: 'mentor_id = ? AND day = ?',
      whereArgs: [mentorId, day],
      orderBy: 'slot_start ASC',
    );
    return maps.map((map) => Availability.fromMap(map)).toList();
  }

  Future<List<Availability>> getAvailableSlots(String mentorId, {String? day}) async {
    final db = await database;
    String whereClause = 'mentor_id = ? AND is_booked = 0';
    List<dynamic> whereArgs = [mentorId];
    
    if (day != null) {
      whereClause += ' AND day = ?';
      whereArgs.add(day);
    }
    
    final maps = await db.query(
      'availability',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'day ASC, slot_start ASC',
    );
    return maps.map((map) => Availability.fromMap(map)).toList();
  }

  Future<int> bookAvailabilitySlot(String availabilityId, String menteeId) async {
    final db = await database;
    return db.update(
      'availability',
      {
        'is_booked': 1,
        'mentee_id': menteeId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND is_booked = 0',
      whereArgs: [availabilityId],
    );
  }

  Future<int> unbookAvailabilitySlot(String availabilityId) async {
    final db = await database;
    return db.update(
      'availability',
      {
        'is_booked': 0,
        'mentee_id': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [availabilityId],
    );
  }

  Future<int> deleteAvailability(String id) async {
    final db = await database;
    return db.delete(
      'availability',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllAvailabilityForMentor(String mentorId) async {
    final db = await database;
    return db.delete(
      'availability',
      where: 'mentor_id = ?',
      whereArgs: [mentorId],
    );
  }

  // ========== UTILITY OPERATIONS ==========
  Future<void> clearAllTables() async {
    final db = await database;
    final tables = [
      'users', 'mentorships', 'availability', 'meetings',
      'resources', 'messages', 'meeting_notes', 'meeting_ratings',
      'checklists', 'newsletters', 'announcements', 'progress_reports', 'events',
      'mentee_goals', 'action_items', 'notifications'
    ];
    
    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Generate unique ID
  String generateId() => _uuid.v4();
} 