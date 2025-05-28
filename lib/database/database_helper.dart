import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smp_mentor_mentee.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const integerTypeNullable = 'INTEGER';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email TEXT UNIQUE NOT NULL,
        userType TEXT NOT NULL CHECK(userType IN ('mentor', 'mentee', 'coordinator')),
        student_id TEXT UNIQUE,
        mentor $textTypeNullable,
        mentee $textTypeNullable,
        acknowledgment_signed TEXT CHECK(acknowledgment_signed IN ('yes', 'no', 'not_applicable')) DEFAULT 'not_applicable',
        created_at $integerType
      )
    ''');

    // Mentorships table
    await db.execute('''
      CREATE TABLE mentorships (
        id $idType,
        mentor_id $textType,
        mentee_id $textType,
        created_at $integerType,
        FOREIGN KEY (mentor_id) REFERENCES users(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id),
        UNIQUE(mentor_id, mentee_id)
      )
    ''');

    // Availability table
    await db.execute('''
      CREATE TABLE availability (
        id $idType,
        mentor_id $textType,
        day $textType,
        slot_start $textType,
        slot_end $textTypeNullable,
        is_booked INTEGER DEFAULT 0,
        mentee_id $textTypeNullable,
        synced INTEGER DEFAULT 0,
        updated_at $integerTypeNullable,
        FOREIGN KEY (mentor_id) REFERENCES users(id)
      )
    ''');

    // Meetings table
    await db.execute('''
      CREATE TABLE meetings (
        id $idType,
        mentor_id $textType,
        mentee_id $textType,
        start_time $textType,
        end_time $textTypeNullable,
        topic $textTypeNullable,
        status TEXT DEFAULT 'pending',
        availability_id $textTypeNullable,
        synced INTEGER DEFAULT 0,
        created_at $integerTypeNullable,
        FOREIGN KEY (mentor_id) REFERENCES users(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id)
      )
    ''');

    // Resources table
    await db.execute('''
      CREATE TABLE resources (
        id $idType,
        title $textType,
        box_file_id $textType,
        box_url $textType,
        file_type $textTypeNullable,
        category $textTypeNullable,
        uploaded_by $textType,
        assigned_to $textTypeNullable,
        downloaded INTEGER DEFAULT 0,
        local_path $textTypeNullable,
        synced INTEGER DEFAULT 0,
        created_at $integerTypeNullable,
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id $idType,
        chat_id $textType,
        sender_id $textType,
        message $textType,
        sent_at $integerType,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users(id)
      )
    ''');

    // Meeting notes table
    await db.execute('''
      CREATE TABLE meeting_notes (
        id $idType,
        meeting_id $textType,
        author_id $textType,
        is_shared INTEGER DEFAULT 0,
        is_mentor INTEGER DEFAULT 0,
        raw_note $textType,
        organized_note $textTypeNullable,
        is_ai_generated INTEGER DEFAULT 0,
        created_at $integerTypeNullable,
        updated_at $integerTypeNullable,
        FOREIGN KEY (meeting_id) REFERENCES meetings(id),
        FOREIGN KEY (author_id) REFERENCES users(id)
      )
    ''');

    // Meeting ratings table
    await db.execute('''
      CREATE TABLE meeting_ratings (
        id $idType,
        meeting_id $textType,
        mentee_id $textType,
        rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
        feedback $textTypeNullable,
        created_at $integerTypeNullable,
        FOREIGN KEY (meeting_id) REFERENCES meetings(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id)
      )
    ''');

    // Checklists table
    await db.execute('''
      CREATE TABLE checklists (
        id $idType,
        user_id $textType,
        title $textType,
        isCompleted INTEGER DEFAULT 0,
        dueDate $textTypeNullable,
        assignedBy $textTypeNullable,
        category $textTypeNullable,
        createdAt $integerTypeNullable,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Newsletters table
    await db.execute('''
      CREATE TABLE newsletters (
        id $idType,
        title $textType,
        content $textType,
        created_at $integerType
      )
    ''');

    // Announcements table
    await db.execute('''
      CREATE TABLE announcements (
        id $idType,
        title $textType,
        content $textType,
        time $textType,
        priority TEXT CHECK(priority IN ('high', 'medium', 'low', 'none')),
        target_audience TEXT CHECK(target_audience IN ('mentors', 'mentees', 'both')),
        created_at $integerType,
        created_by $textTypeNullable,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');

    // Progress reports table
    await db.execute('''
      CREATE TABLE progress_reports (
        id $idType,
        mentee_id $textType,
        mentor_id $textType,
        report_period $textType,
        status TEXT NOT NULL CHECK(status IN ('draft', 'submitted', 'reviewed', 'approved')),
        overall_score $integerTypeNullable,
        submission_date $integerTypeNullable,
        review_date $integerTypeNullable,
        synced INTEGER DEFAULT 0,
        created_at $integerType,
        updated_at $integerTypeNullable,
        FOREIGN KEY (mentee_id) REFERENCES users(id),
        FOREIGN KEY (mentor_id) REFERENCES users(id)
      )
    ''');

    // Events table
    await db.execute('''
      CREATE TABLE events (
        id $idType,
        title $textType,
        description $textTypeNullable,
        location $textTypeNullable,
        start_time $integerType,
        end_time $integerTypeNullable,
        created_by $textType,
        event_type TEXT CHECK(event_type IN ('workshop', 'meeting', 'social', 'training', 'other')),
        target_audience TEXT CHECK(target_audience IN ('mentors', 'mentees', 'both', 'coordinators', 'all')),
        max_participants $integerTypeNullable,
        required_registration INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        created_at $integerType,
        updated_at $integerTypeNullable,
        FOREIGN KEY (created_by) REFERENCES users(id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}