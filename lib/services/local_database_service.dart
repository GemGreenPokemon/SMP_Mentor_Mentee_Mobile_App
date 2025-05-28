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

  Future<List<Meeting>> getMeetingsByMentor(String mentorId) async {
    final db = await database;
    final result = await db.query(
      'meetings',
      where: 'mentor_id = ?',
      whereArgs: [mentorId],
    );
    return result.map((map) => Meeting.fromMap(map)).toList();
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

  Future<int> getMeetingsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM meetings');
    return result.first['count'] as int;
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

  // ========== UTILITY OPERATIONS ==========
  Future<void> clearAllTables() async {
    final db = await database;
    final tables = [
      'users', 'mentorships', 'availability', 'meetings',
      'resources', 'messages', 'meeting_notes', 'meeting_ratings',
      'checklists', 'newsletters', 'announcements', 'progress_reports', 'events'
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