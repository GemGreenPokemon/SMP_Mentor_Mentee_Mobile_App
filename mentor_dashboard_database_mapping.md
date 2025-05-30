# Mentor Dashboard to Local Database Mapping Analysis

## Overview
This document maps the Mentor Dashboard features to our local SQLite database tables, identifying how each UI component correlates with database entities.

## Mentor Dashboard Features

### 1. **Mentor Profile** 
**UI Location**: Used in MentorService
**Data Elements**:
- Name
- Role/Year/Major
- Email
- Department
- Join Date

**Database Mapping**:
- **Table**: `users`
- **Fields**: 
  - `name` ✓
  - `email` ✓
  - `userType` = 'mentor' ✓
  - `student_id` ✓
  - `created_at` → maps to joinDate ✓
  - **Missing**: role/year/major, department (could be stored in a JSON field or separate table)

### 2. **Mentees Section**
**UI Features**:
- List of assigned mentees
- Mentee details (name, program, last meeting, progress %)
- "Select Mentee" functionality
- Message button for each mentee
- Assigned by indicator

**Database Mapping**:
- **Primary Table**: `mentorships` (links mentors to mentees)
- **Related Tables**: 
  - `users` (mentee information)
  - `meetings` (for last meeting data)
- **Fields Used**:
  - Mentee name/program from `users` table ✓
  - Mentor-mentee relationship from `mentorships` ✓
  - Last meeting from `meetings` table (need to query latest) ✓
  - **Missing**: progress percentage, assigned by field

### 3. **Announcements**
**UI Features**:
- Title, content, time, priority
- View All button → AnnouncementScreen
- Priority levels: high, medium, low, none

**Database Mapping**:
- **Table**: `announcements` ✓
- **Fields**: All required fields present
  - `title` ✓
  - `content` ✓
  - `time` ✓
  - `priority` ✓
  - `target_audience` ✓
  - `created_by` ✓

### 4. **Quick Actions Grid**
Links to various screens:
- Schedule Meetings → `meetings` table
- Meeting Notes → `meeting_notes` table
- Resources Hub → `resources` table
- Progress Reports → `progress_reports` table
- Assign Check List → `checklists` table
- Newsletters → `newsletters` table

### 5. **Today's Schedule**
**UI Features**:
- List of meetings for today
- Meeting details (title, time, location)
- Check In/Out button for next meeting
- "View Full Schedule" dialog

**Database Mapping**:
- **Table**: `meetings`
- **Fields**:
  - `start_time`, `end_time` ✓
  - `topic` → maps to title ✓
  - `mentor_id`, `mentee_id` ✓
  - **Missing**: location field (could be added or use a JSON field)

### 6. **Notifications System**
**UI Features**:
- Progress report reminders
- Upcoming meeting alerts

**Database Mapping**:
- No dedicated notifications table
- Could be derived from:
  - `progress_reports` (for due dates)
  - `meetings` (for upcoming meetings)
  - **Recommendation**: Add a `notifications` table

## Data Flow Analysis

### Current MentorService Mock Data Structure:
```dart
mentees = [
  {
    'name': String,
    'program': String,
    'lastMeeting': String,
    'progress': double,
    'assignedBy': String,
    'goals': [
      {'title': String, 'progress': double}
    ],
    'upcomingMeetings': [
      {
        'title': String,
        'date': String,
        'time': String,
        'location': String,
        'isNext': bool
      }
    ],
    'actionItems': [
      {
        'task': String,
        'dueDate': String,
        'completed': bool
      }
    ]
  }
]
```

### Database Gaps Identified:

1. **Goals System**: No dedicated table for mentee goals
   - Need: `mentee_goals` table with progress tracking

2. **Action Items**: No table for tracking mentee tasks
   - Need: `action_items` or extend `checklists` table

3. **Progress Tracking**: No overall progress percentage storage
   - Could add to `mentorships` table or create `mentee_progress` table

4. **Meeting Locations**: Not in current `meetings` table
   - Add `location` field to `meetings` table

5. **Assigned By**: Not tracked in mentorship relationships
   - Add `assigned_by` field to `mentorships` table

## Integration Points

### When Test Mode is Active:
1. **Mentor Selection**: Uses `TestModeManager.currentTestUser`
2. **Mentee List**: Query `mentorships` WHERE `mentor_id` = current test user
3. **Meetings**: Filter by `mentor_id` in `meetings` table
4. **Announcements**: Show all where `target_audience` IN ('mentors', 'both')

### Data Loading Pattern:
```dart
// Pseudo-code for loading mentor dashboard with local DB
if (TestModeManager.isTestMode) {
  final mentor = TestModeManager.currentTestUser;
  final mentorships = await LocalDatabaseService.instance
      .getMentorshipsByMentor(mentor.id);
  
  // Load mentees
  for (final mentorship in mentorships) {
    final mentee = await LocalDatabaseService.instance
        .getUser(mentorship.menteeId);
    // Build mentee card data
  }
  
  // Load meetings
  final meetings = await LocalDatabaseService.instance
      .getMeetingsByMentor(mentor.id);
  
  // Load announcements
  final announcements = await LocalDatabaseService.instance
      .getAnnouncements(targetAudience: 'mentors');
}
```

## Required Database Schema Updates

### 1. **Add Missing Fields to Existing Tables**

#### `meetings` table:
```sql
ALTER TABLE meetings ADD COLUMN location TEXT;
```

#### `mentorships` table:
```sql
ALTER TABLE mentorships ADD COLUMN assigned_by TEXT;
ALTER TABLE mentorships ADD COLUMN overall_progress REAL DEFAULT 0.0;
```

#### `users` table (for mentor profile):
```sql
ALTER TABLE users ADD COLUMN department TEXT;
ALTER TABLE users ADD COLUMN year_major TEXT;  -- For "3rd Year, Computer Science Major"
```

### 2. **Create New Tables**

#### `mentee_goals` table:
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

#### `action_items` table:
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

#### `notifications` table (optional but recommended):
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

### 3. **Update DatabaseHelper.dart**

Add these table creations to the `_createDB` method in `database_helper.dart`:

```dart
// After existing table creations, add:

// Mentee goals table
await db.execute('''
  CREATE TABLE mentee_goals (
    id TEXT PRIMARY KEY,
    mentorship_id TEXT NOT NULL,
    title TEXT NOT NULL,
    progress REAL DEFAULT 0.0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER,
    FOREIGN KEY (mentorship_id) REFERENCES mentorships(id)
  )
''');

// Action items table
await db.execute('''
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
  )
''');
```

### 4. **Update LocalDatabaseService.dart**

Add CRUD operations for new tables:

```dart
// Mentee Goals operations
Future<MenteeGoal> createMenteeGoal(MenteeGoal goal) async { ... }
Future<List<MenteeGoal>> getGoalsByMentorship(String mentorshipId) async { ... }
Future<int> updateGoalProgress(String goalId, double progress) async { ... }

// Action Items operations  
Future<ActionItem> createActionItem(ActionItem item) async { ... }
Future<List<ActionItem>> getActionItemsByMentorship(String mentorshipId) async { ... }
Future<int> completeActionItem(String itemId) async { ... }
```

### 5. **Create Model Classes**

Create new model files:
- `lib/models/mentee_goal.dart`
- `lib/models/action_item.dart`

## Implementation Priority:

1. **High Priority** (Required for basic functionality):
   - Add `location` field to meetings
   - Add `assigned_by` to mentorships
   - Add `overall_progress` to mentorships

2. **Medium Priority** (Enhances features):
   - Create `mentee_goals` table
   - Create `action_items` table
   - Add department/year_major to users

3. **Low Priority** (Nice to have):
   - Create `notifications` table
   - Add additional tracking fields

## Migration Strategy:

1. **For existing databases**:
   - Increment database version in `DatabaseHelper`
   - Add migration logic in `onUpgrade` callback
   - Use ALTER TABLE for existing tables
   - Create new tables in migration

2. **For new installations**:
   - All changes included in initial schema
   - No migration needed

## Next Steps:
1. Update database schema with high-priority fields
2. Create model classes for new entities
3. Update mock data generator to populate new fields
4. Create LocalMentorService implementation
5. Test integration with mentor dashboard