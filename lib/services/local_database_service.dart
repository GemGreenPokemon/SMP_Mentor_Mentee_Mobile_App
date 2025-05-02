import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smp_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,                       -- Firebase UID or UUID
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        userType TEXT NOT NULL CHECK(userType IN ('mentor', 'mentee', 'coordinator')),
        student_id TEXT UNIQUE,                    -- Human-readable unique identifier
        mentor TEXT,                               -- Mentor's student_id (for mentees)
        mentee TEXT,                               -- JSON array of mentee student_ids (for mentors, up to 3)
        created_at INTEGER NOT NULL
      );
    ''');

    // Create mentorships table
    await db.execute('''
      CREATE TABLE mentorships (
        id TEXT PRIMARY KEY,
        mentor_id TEXT NOT NULL,
        mentee_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (mentor_id) REFERENCES users(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id),
        UNIQUE(mentor_id, mentee_id)
      );
    ''');

    // Create availability table
    await db.execute('''
      CREATE TABLE availability (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,                     -- Mentor ID
        day TEXT NOT NULL,                         -- 'Monday', 'Tuesday', etc.
        slot_start TEXT NOT NULL,                  -- '13:00'
        slot_end TEXT,                             -- Nullable
        is_booked INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        updated_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      );
    ''');

    // Create meetings table
    await db.execute('''
      CREATE TABLE meetings (
        id TEXT PRIMARY KEY,
        mentor_id TEXT NOT NULL,
        mentee_id TEXT NOT NULL,
        start_time TEXT NOT NULL,                  -- ISO format or UTC
        end_time TEXT,                             -- Nullable
        topic TEXT,
        status TEXT DEFAULT 'pending',             -- 'pending', 'accepted', 'rejected'
        availability_id TEXT,                      -- Optional ref to availability
        synced INTEGER DEFAULT 0,
        created_at INTEGER,
        FOREIGN KEY (mentor_id) REFERENCES users(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id)
      );
    ''');

    // Create resources table
    await db.execute('''
      CREATE TABLE resources (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        box_file_id TEXT NOT NULL,
        box_url TEXT NOT NULL,
        file_type TEXT,                            -- 'pdf', 'docx', 'link', etc.
        category TEXT,
        uploaded_by TEXT NOT NULL,
        assigned_to TEXT,                          -- JSON list of mentee IDs (or separate table if needed)
        downloaded INTEGER DEFAULT 0,
        local_path TEXT,
        synced INTEGER DEFAULT 0,
        created_at INTEGER,
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
      );
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,                     -- e.g., 'mentor__mentee'
        sender_id TEXT NOT NULL,
        message TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (sender_id) REFERENCES users(id)
      );
    ''');

    // Create meeting_notes table
    await db.execute('''
      CREATE TABLE meeting_notes (
        id TEXT PRIMARY KEY,
        meeting_id TEXT NOT NULL,
        author_id TEXT NOT NULL,                   -- Mentor or mentee
        is_shared INTEGER DEFAULT 0,               -- 0 = private, 1 = shared
        is_mentor INTEGER DEFAULT 0,               -- 1 = mentor, 0 = mentee
        raw_note TEXT NOT NULL,
        organized_note TEXT,                       -- Gemini Pro formatted notes
        is_ai_generated INTEGER DEFAULT 0,
        created_at INTEGER,
        updated_at INTEGER,
        FOREIGN KEY (meeting_id) REFERENCES meetings(id),
        FOREIGN KEY (author_id) REFERENCES users(id)
      );
    ''');

    // Create meeting_ratings table
    await db.execute('''
      CREATE TABLE meeting_ratings (
        id TEXT PRIMARY KEY,
        meeting_id TEXT NOT NULL,
        mentee_id TEXT NOT NULL,
        rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
        feedback TEXT,
        created_at INTEGER,
        FOREIGN KEY (meeting_id) REFERENCES meetings(id),
        FOREIGN KEY (mentee_id) REFERENCES users(id)
      );
    ''');
  }

  // Placeholder for future CRUD operations
  // Future close() async {
  //   final db = await instance.database;
  //   db.close();
  // }
} 