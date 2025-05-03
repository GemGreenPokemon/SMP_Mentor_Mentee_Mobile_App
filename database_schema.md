# SMP Mentor Mentee Mobile App Database Schema

## Introduction

This schema serves dual purposes:
1. It defines the local SQLite database structure for offline functionality
2. It provides a blueprint for our Firestore database collections and documents

The design ensures compatibility between local and cloud storage, with a synchronization mechanism via the `synced` flag to maintain data consistency. Each entity includes a unique ID field that will be consistent across both SQLite and Firestore.

## Tables

### 🔹 users
```sql
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
```
**Note:** In Firestore, the document ID for each user will be the same as this `id` (often referred to as `index_id`), allowing direct `.doc(index_id)` lookups without scanning the collection.

### 🔹 mentorships
```sql
CREATE TABLE mentorships (
  id TEXT PRIMARY KEY,
  mentor_id TEXT NOT NULL,
  mentee_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (mentor_id) REFERENCES users(id),
  FOREIGN KEY (mentee_id) REFERENCES users(id),
  UNIQUE(mentor_id, mentee_id)
);
```

### 🔹 availability
```sql
CREATE TABLE availability (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,                     -- Mentor ID
  day TEXT NOT NULL,                         -- 'Monday', 'Tuesday', etc.
  slot_start TEXT NOT NULL,                  -- '13:00'
  slot_end TEXT,                             -- Nullable
  is_booked INTEGER DEFAULT 0,
  mentee_id TEXT,                            -- ID of mentee who has booked this slot
  synced INTEGER DEFAULT 0,
  updated_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```
**Note:** In Firestore, each availability document under `users/{mentorId}/availability` includes `user_id`, `day`, `slot_start`, `slot_end`, `is_booked`, and `mentee_id` when a mentee has booked that slot.

### 🔹 meetings
```sql
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
```

### 🔹 resources
```sql
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
```

### 🔹 messages (optional local cache for chat)
```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  chat_id TEXT NOT NULL,                     -- e.g., 'mentor__mentee'
  sender_id TEXT NOT NULL,
  message TEXT NOT NULL,
  sent_at INTEGER NOT NULL,
  synced INTEGER DEFAULT 0,
  FOREIGN KEY (sender_id) REFERENCES users(id)
);
```

### 🔹 meeting_notes
```sql
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
```

### 🔹 meeting_ratings
```sql
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
``` 