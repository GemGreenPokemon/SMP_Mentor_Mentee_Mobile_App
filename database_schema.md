# SMP Mentor Mentee Mobile App Database Schema

## Update History
- **5/29/25**: Added missing fields and tables required for mentor dashboard functionality:
  - Added `location` field to meetings table
  - Added `department`, `year_major` fields to users table
  - Added `assigned_by`, `overall_progress` fields to mentorships table
  - Created new tables: `mentee_goals`, `action_items`, `notifications`

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
  acknowledgment_signed TEXT CHECK(acknowledgment_signed IN ('yes', 'no', 'not_applicable')) DEFAULT 'not_applicable', -- For mentees only: 'yes', 'no', 'not_applicable' for non-mentees
  department TEXT,                           -- User's department (e.g., "Computer Science") - Added 5/29/25
  year_major TEXT,                           -- User's year and major (e.g., "3rd Year, Computer Science Major") - Added 5/29/25
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
  assigned_by TEXT,                          -- User ID of who assigned this mentorship - Added 5/29/25
  overall_progress REAL DEFAULT 0.0,         -- Overall progress percentage (0-100) - Added 5/29/25
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
  mentor_id TEXT NOT NULL,                     -- Mentor ID
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
  location TEXT,                             -- Meeting location (physical or virtual) - Added 5/29/25
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

### 🔹 checklists
```sql
CREATE TABLE checklists (
  id TEXT PRIMARY KEY,                         -- Unique ID for the checklist item
  user_id TEXT NOT NULL,                     -- User ID this checklist item belongs to
  title TEXT NOT NULL,                       -- The title or description of the task.
  isCompleted INTEGER DEFAULT 0,             -- Status of the task (0=false, 1=true).
  dueDate TEXT,                              -- Optional due date (ISO 8601 format or similar).
  assignedBy TEXT,                           -- Optional ID of the user who assigned the task.
  category TEXT,                             -- Optional category (e.g., "Onboarding", "Semester Goals", "Admin").
  createdAt INTEGER,                         -- Timestamp (Unix epoch) when the item was created.
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 🔹 newsletters
```sql
CREATE TABLE newsletters (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (meeting_id) REFERENCES meetings(id),
  FOREIGN KEY (mentee_id) REFERENCES users(id)
);
```

### 🔹 announcements
```sql
CREATE TABLE announcements (
  id TEXT PRIMARY KEY,                       -- Unique identifier for the announcement
  title TEXT NOT NULL,                       -- Announcement title
  content TEXT NOT NULL,                     -- Main announcement content
  time TEXT NOT NULL,                        -- When the announcement was posted (human-readable format)
  priority TEXT CHECK(priority IN ('high', 'medium', 'low', 'none')),  -- Priority level matching dashboard UI
  target_audience TEXT CHECK(target_audience IN ('mentors', 'mentees', 'both')),  -- Who should see this announcement
  created_at INTEGER NOT NULL,               -- Timestamp for sorting and filtering
  created_by TEXT,                           -- User ID of announcement creator
  synced INTEGER DEFAULT 0,                  -- Flag for synchronization status
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

### 🔹 progress_reports
```sql
CREATE TABLE progress_reports (
  id TEXT PRIMARY KEY,                       -- Unique identifier for the report
  mentee_id TEXT NOT NULL,                   -- ID of the mentee this report is for
  mentor_id TEXT NOT NULL,                   -- ID of the mentor who created/reviews this report
  report_period TEXT NOT NULL,               -- e.g., "Spring 2024", "Month 3", etc.
  status TEXT NOT NULL CHECK(status IN ('draft', 'submitted', 'reviewed', 'approved')),
  overall_score INTEGER,                     -- Optional numerical assessment (e.g., 1-5)
  submission_date INTEGER,                   -- When the report was submitted
  review_date INTEGER,                       -- When the report was reviewed
  synced INTEGER DEFAULT 0,                  -- Sync status flag
  created_at INTEGER NOT NULL,               -- Report creation timestamp
  updated_at INTEGER,                        -- Last update timestamp
  FOREIGN KEY (mentee_id) REFERENCES users(id),
  FOREIGN KEY (mentor_id) REFERENCES users(id)
);
```

### 🔹 events
```sql
CREATE TABLE events (
  id TEXT PRIMARY KEY,                       -- Unique identifier for the event
  title TEXT NOT NULL,                       -- Event title
  description TEXT,                          -- Detailed description
  location TEXT,                             -- Physical location or virtual meeting link
  start_time INTEGER NOT NULL,               -- Event start time (timestamp)
  end_time INTEGER,                          -- Event end time (timestamp)
  created_by TEXT NOT NULL,                  -- User who created the event
  event_type TEXT CHECK(event_type IN ('workshop', 'meeting', 'social', 'training', 'other')),
  target_audience TEXT CHECK(target_audience IN ('mentors', 'mentees', 'both', 'coordinators', 'all')),
  max_participants INTEGER,                  -- Optional capacity limit
  required_registration INTEGER DEFAULT 0,   -- Whether registration is required (0/1)
  synced INTEGER DEFAULT 0,                  -- Sync status flag
  created_at INTEGER NOT NULL,               -- Creation timestamp
  updated_at INTEGER,                        -- Last update timestamp
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

### 🔹 mentee_goals (Added 5/29/25)
```sql
CREATE TABLE mentee_goals (
  id TEXT PRIMARY KEY,
  mentorship_id TEXT NOT NULL,
  title TEXT NOT NULL,
  progress REAL DEFAULT 0.0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (mentorship_id) REFERENCES mentorships(id)
);
```

### 🔹 action_items (Added 5/29/25)
```sql
CREATE TABLE action_items (
  id TEXT PRIMARY KEY,
  mentorship_id TEXT NOT NULL,
  task TEXT NOT NULL,
  description TEXT,
  due_date TEXT,
  completed INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (mentorship_id) REFERENCES mentorships(id)
);
```

### 🔹 notifications (Added 5/29/25)
```sql
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT CHECK(type IN ('meeting', 'report', 'announcement', 'task')),
  priority TEXT CHECK(priority IN ('high', 'medium', 'low')),
  read INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## Firestore Schema

Describes the collections and data structure in Firestore. **Note:** This mirrors the local SQLite schema, which is the source of truth for synchronization.

1.  **`users`**
    - Description: Stores user profile information synchronized from the local SQLite database.
    - **Document ID**: User's unique ID (`id` field from SQLite, typically Firebase Auth UID or a generated UUID).
    - **Fields**: (Mirrors the `users` table in SQLite)
      - `id`: (String) Primary Key, same as Document ID.
      - `name`: (String) User's full name.
      - `email`: (String) User's email address (unique).
      - `userType`: (String) Role: 'mentor', 'mentee', or 'coordinator'.
      - `student_id`: (String) Human-readable unique identifier (unique, optional).
      - `mentor`: (String) Mentor's `student_id` (for mentees, optional).
      - `mentee`: (String) JSON string representing an array of mentee `student_id`s (for mentors, optional).
      - `acknowledgment_signed`: (String) For mentees only: 'yes', 'no', or 'not_applicable' for non-mentees.
      - `department`: (String) User's department (e.g., "Computer Science") - Added 5/29/25.
      - `year_major`: (String) User's year and major (e.g., "3rd Year, Computer Science Major") - Added 5/29/25.
      - `created_at`: (Timestamp) Timestamp of account creation (mirrors SQLite INTEGER timestamp).

      #### Subcollections of users:

      - **`checklists`**: Stores individual checklist items assigned to or created by the user (mirrors `checklists` table in SQLite).
        - **Document ID**: Auto-generated unique ID (matches `id` in SQLite `checklists` table).
        - **Fields**: (Mirrors the `checklists` table in SQLite)
          - `id`: (String) Unique ID for the checklist item (same as Document ID).
          - `user_id`: (String/Reference) User ID this checklist item belongs to.
          - `title`: (String) The title or description of the task.
          - `isCompleted`: (Boolean) Status of the task (true/false).
          - `dueDate`: (Timestamp/String) Optional due date for the task.
          - `assignedBy`: (String) Optional `student_id` of the user who assigned the task.
          - `category`: (String) Optional category (e.g., "Onboarding", "Semester Goals", "Admin").
          - `createdAt`: (Timestamp) Timestamp when the item was created.
      - **`availability`**: Stores availability slots for the user (mirrors `availability` table in SQLite).
        - **Document ID**: Auto-generated unique ID (matches `id` in SQLite `availability` table).
        - **Note**: Optionally, the Document ID can be constructed as `<userName>_<role>_<date>` (e.g., `TommyDickson_mentor_10_12_2025`) for readability and uniqueness.
        - **Fields**: (Mirrors the `availability` table)
          - `id`: (String) Unique ID for the availability slot.
          - `mentor_id`: (String/Reference) ID of the mentor.
          - `day`: (String) Day of the week (e.g., 'Monday').
          - `slot_start`: (String) Start time of availability (e.g., '13:00').
          - `slot_end`: (String) End time of availability (optional).
          - `is_booked`: (Boolean) Whether this slot is booked.
          - `mentee_id`: (String/Reference, optional) ID of the mentee who booked this slot.
          - `synced`: (Boolean) Flag indicating if the record is synced from Firestore to local DB.
          - `updated_at`: (Timestamp) Timestamp when the slot was last updated in the local DB.

      - **`requestedMeetings`**: Stores meeting requests made by or for the user.
        - **Document ID**: Auto-generated unique ID.
        - **Fields**:
          - `id`: (String) Unique ID for the meeting request.
          - `mentorId`: (String/Reference) ID of the mentor.
          - `menteeId`: (String/Reference) ID of the mentee.
          - `startTime`: (Timestamp) Requested start time.
          - `endTime`: (Timestamp) Requested end time.
          - `topic`: (String) Topic of the requested meeting.
          - `status`: (String) Status of the request ('pending', 'accepted', 'rejected').
          - `createdAt`: (Timestamp) When the request was created.
      - **`messages`**: Stores conversation threads for the user.
        #### Subcollections:
        - **`{otherUserId}`**: Document ID equal to the other participant's ID (e.g., `mentor__mentee`). Represents a chat thread.
          #### Subcollections:
          - **`history`**: Stores individual messages in this conversation (mirrors `messages` table in SQLite).
            - **Document ID**: Unique message `id`.
            - **Fields**:
              - `id`: (String) Unique ID for the message.
              - `chat_id`: (String) Chat identifier (e.g., `mentor__mentee`).
              - `sender_id`: (String/Reference) ID of the sender.
              - `message`: (String) Message content.
              - `sent_at`: (Timestamp) When the message was sent.
              - `synced`: (Boolean) Flag indicating if the record has been synced from local DB.
      - **`notes`**: Stores personal notes attached to the user.
            #### Subcolletions for messages: 
            
        - **Document ID**: Auto-generated unique ID.
        - **Fields**:
          - `id`: (String) Unique ID for the note.
          - `content`: (String) Note content.
          - `createdAt`: (Timestamp) When the note was created.
          - `updatedAt`: (Timestamp) When the note was last updated.
      - **`ratings`**: Stores ratings associated with the user.
        - **Document ID**: Auto-generated unique ID.
        - **Fields**:
          - `id`: (String) Unique ID for the rating.
          - `raterId`: (String/Reference) ID of the user who gave the rating.
          - `rateeId`: (String/Reference) ID of the user who received the rating.
          - `rating`: (Integer) Rating value (1-5).
          - `feedback`: (String) Optional feedback text.
          - `createdAt`: (Timestamp) When the rating was created.

2.  **`meetings`**
    - Description: Stores meeting information between mentors and mentees.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `mentorId`: (String/Reference) ID of the mentor
      - `menteeId`: (String/Reference) ID of the mentee
      - `startTime`: (Timestamp) Start time of the meeting
      - `endTime`: (Timestamp) End time of the meeting
      - `topic`: (String) Topic of the meeting
      - `location`: (String) Meeting location (physical or virtual) - Added 5/29/25
      - `status`: (String) Status of the meeting ('pending', 'accepted', 'rejected')
      - `availabilityId`: (String/Reference) Optional reference to the availability slot
      - `synced`: (Boolean) Flag indicating if the meeting is synced with the local database
      - `createdAt`: (Timestamp) Timestamp when the meeting was created

    #### Subcollections:

    - **`notes`**: Stores meeting notes for each meeting.
      - **Document ID**: Auto-generated unique ID
      - **Fields**:
        - `authorId`: (String/Reference) ID of the author (mentor or mentee)
        - `isShared`: (Boolean) Flag indicating if the note is shared
        - `isMentor`: (Boolean) Flag indicating if the author is a mentor
        - `rawNote`: (String) Raw text of the note
        - `organizedNote`: (String) Organized text of the note (using Gemini Pro formatting)
        - `isAiGenerated`: (Boolean) Flag indicating if the note was generated by AI
        - `createdAt`: (Timestamp) Timestamp when the note was created
        - `updatedAt`: (Timestamp) Timestamp when the note was last updated

    - **`ratings`**: Stores meeting ratings for each meeting.
      - **Document ID**: Auto-generated unique ID
      - **Fields**:
        - `menteeId`: (String/Reference) ID of the mentee who rated the meeting
        - `rating`: (Integer) Rating given by the mentee (1-5)
        - `feedback`: (String) Feedback given by the mentee
        - `createdAt`: (Timestamp) Timestamp when the rating was created

3.  **`announcements`**
    - Description: Stores announcement information for mentors, mentees, or both.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `id`: (String) Primary Key, same as Document ID.
      - `title`: (String) Announcement title.
      - `content`: (String) Main announcement content.
      - `time`: (String) Human-readable time format (e.g., "2 hours ago").
      - `priority`: (String) Priority level: 'high', 'medium', 'low', or 'none'.
      - `target_audience`: (String) Who should see this: 'mentors', 'mentees', or 'both'.
      - `created_at`: (Timestamp) When the announcement was created.
      - `created_by`: (String/Reference) Reference to the user who created the announcement.
      - `synced`: (Boolean) Flag indicating if the announcement is synced with the local database.
      
4.  **`progress_reports`**
    - Description: Stores progress report information for mentees.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `menteeId`: (String/Reference) ID of the mentee this report is for
      - `mentorId`: (String/Reference) ID of the mentor who created/reviews this report
      - `reportPeriod`: (String) The period this report covers (e.g., "Spring 2024", "Month 3")
      - `status`: (String) Status of the report ('draft', 'submitted', 'reviewed', 'approved')
      - `overallScore`: (Number) Optional numerical assessment
      - `submissionDate`: (Timestamp) When the report was submitted
      - `reviewDate`: (Timestamp) When the report was reviewed
      - `synced`: (Boolean) Flag indicating if the report is synced with local DB
      - `createdAt`: (Timestamp) When the report was created
      - `updatedAt`: (Timestamp) When the report was last updated

5.  **`events`**
    - Description: Stores events for mentors, mentees, or both.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `title`: (String) Event title
      - `description`: (String) Detailed description
      - `location`: (String) Physical location or virtual meeting link
      - `startTime`: (Timestamp) Event start time
      - `endTime`: (Timestamp) Event end time
      - `createdBy`: (String/Reference) User who created the event
      - `eventType`: (String) Type of event ('workshop', 'meeting', 'social', 'training', 'other')
      - `targetAudience`: (String) Who should see this: 'mentors', 'mentees', 'both', 'coordinators', 'all'
      - `maxParticipants`: (Number) Optional capacity limit
      - `requiredRegistration`: (Boolean) Whether registration is required
      - `synced`: (Boolean) Flag indicating if the event is synced with local DB
      - `createdAt`: (Timestamp) When the event was created
      - `updatedAt`: (Timestamp) When the event was last updated

6.  **`mentorships`** (Added 5/29/25)
    - Description: Stores mentorship relationships between mentors and mentees.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `mentorId`: (String/Reference) ID of the mentor
      - `menteeId`: (String/Reference) ID of the mentee
      - `assignedBy`: (String/Reference) User ID of who assigned this mentorship
      - `overallProgress`: (Number) Overall progress percentage (0-100)
      - `createdAt`: (Timestamp) When the mentorship was created

7.  **`mentee_goals`** (Added 5/29/25)
    - Description: Stores goals for mentees within their mentorship.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `mentorshipId`: (String/Reference) ID of the mentorship this goal belongs to
      - `title`: (String) Title of the goal
      - `progress`: (Number) Progress percentage (0-100)
      - `createdAt`: (Timestamp) When the goal was created
      - `updatedAt`: (Timestamp) When the goal was last updated

8.  **`action_items`** (Added 5/29/25)
    - Description: Stores tasks and action items for mentees.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `mentorshipId`: (String/Reference) ID of the mentorship this task belongs to
      - `task`: (String) Task description
      - `description`: (String) Detailed description (optional)
      - `dueDate`: (Timestamp/String) Due date for the task
      - `completed`: (Boolean) Whether the task is completed
      - `createdAt`: (Timestamp) When the task was created
      - `updatedAt`: (Timestamp) When the task was last updated

9.  **`notifications`** (Added 5/29/25)
    - Description: Stores notifications for users.
    - **Document ID**: Auto-generated unique ID
    - **Fields**:
      - `userId`: (String/Reference) ID of the user this notification is for
      - `title`: (String) Notification title
      - `message`: (String) Notification message
      - `type`: (String) Type of notification ('meeting', 'report', 'announcement', 'task')
      - `priority`: (String) Priority level ('high', 'medium', 'low')
      - `read`: (Boolean) Whether the notification has been read
      - `createdAt`: (Timestamp) When the notification was created

## Hierarchical State/City/Campus Structure

To ensure scalability and support multiple institutions across California, the Firestore database will be organized using a three-tier hierarchical structure: State → City → Campus.

### Structure: `{State}/{City}/{Campus}/[schema collections]`

**Example Structure:**
```
Firestore Root
├── California/                         (State Collection)
│   ├── Merced/                        (City Collection)
│   │   ├── UC_Merced/                 (Campus - Primary implementation)
│   │   │   ├── users/
│   │   │   ├── meetings/
│   │   │   ├── announcements/
│   │   │   ├── progress_reports/
│   │   │   ├── events/
│   │   │   └── [all other collections as defined in schema above]
│   │   ├── Merced_College/            (Another campus in same city)
│   │   │   └── [same schema structure]
│   │   └── _metadata/                 (Optional: city-level information)
│   ├── Fresno/
│   │   ├── Fresno_State/
│   │   │   └── [same schema structure]
│   │   └── Fresno_City_College/
│   │       └── [same schema structure]
│   ├── Berkeley/
│   │   ├── UC_Berkeley/
│   │   │   └── [same schema structure]
│   │   └── Berkeley_City_College/
│   │       └── [same schema structure]
│   ├── Los_Angeles/
│   │   ├── UCLA/
│   │   ├── USC/
│   │   └── LA_City_College/
│   └── _metadata/                     (Optional: state-level information)
```

### Benefits:
- **State-Level Organization**: Ready for potential expansion beyond California
- **City-Level Aggregation**: Enables city-wide analytics and coordination
- **Campus Isolation**: Each institution's data remains separate and secure
- **Scalability**: Easy to add new states, cities, or campuses
- **Performance**: Queries are scoped to specific geographic and institutional levels
- **Multi-tenancy**: Natural separation for different SMP programs
- **Hierarchical Permissions**: Can implement state, city, or campus-level access controls

### Implementation Notes:
- The current implementation will use `California/Merced/UC_Merced/` as the primary path
- All collection paths in the schema above should be prefixed with this full hierarchical path in production
- The system is designed to initially support California institutions only
- Future expansion to other states would follow the same hierarchical pattern