# SMP Mentor-Mentee Cloud Functions

This directory contains the Firebase Cloud Functions for the SMP Mentor-Mentee mobile application.

## Project Structure

```
functions/
├── src/
│   ├── index.ts                 # Main entry point and function exports
│   ├── types/
│   │   └── index.ts            # TypeScript type definitions
│   ├── utils/
│   │   ├── auth.ts             # Authentication utilities
│   │   └── database.ts         # Database helper functions
│   ├── university/
│   │   └── initialization.ts   # University setup and management
│   ├── users/
│   │   └── management.ts       # User CRUD operations
│   ├── meetings/
│   │   └── management.ts       # Meeting scheduling and management
│   ├── messaging/
│   │   └── chat.ts            # Chat and messaging functions
│   ├── announcements/
│   │   └── management.ts       # Announcement management
│   ├── reports/
│   │   └── progress.ts        # Progress report generation
│   └── sync/
│       └── data-sync.ts       # Local to Firestore synchronization
├── package.json               # Node.js dependencies
├── tsconfig.json             # TypeScript configuration
└── .gitignore               # Git ignore rules
```

## Available Functions

### University Management
- `initUniversity` - Initialize a new university database structure
- `getUniversities` - Get list of all universities (super admin only)
- `deleteUniversity` - Delete a university (super admin only)

### User Management
- `createUserAccount` - Create new users (mentors, mentees, coordinators)
- `updateUserAccount` - Update user information
- `deleteUserAccount` - Delete user accounts
- `assignMentor` - Assign mentors to mentees

### Meeting Management
- `scheduleMeeting` - Create new meetings
- `updateMeetingDetails` - Update meeting information
- `cancelMeeting` - Cancel/delete meetings
- `acceptMeeting` - Accept meeting invitations

### Messaging
- `sendChatMessage` - Send messages in mentor-mentee chats
- `getChatMessages` - Retrieve chat history
- `markMessagesAsRead` - Mark messages as read
- `hideMessage` - Hide messages for specific users

### Announcements
- `postAnnouncement` - Create announcements
- `updateAnnouncementDetails` - Update announcements
- `deleteAnnouncement` - Delete announcements
- `getAnnouncements` - Get announcements for target audience

### Progress Reports
- `createProgressReport` - Generate progress reports
- `submitReport` - Submit completed reports
- `reviewProgressReport` - Review reports (coordinator only)
- `getProgressReports` - Get reports for mentorships

### Data Synchronization
- `syncData` - Sync local database changes to Firestore
- `batchSyncToFirestore` - Batch sync multiple documents
- `getSyncStatus` - Check sync status of local documents

### Utility
- `healthCheck` - Health check endpoint

## Security Model

### Authentication Levels
1. **Super Admin** - Can manage universities and global settings
2. **Coordinator** - Can manage users and content within their university
3. **Mentor** - Can manage their mentees and meetings
4. **Mentee** - Can manage their profile and meetings

### Data Isolation
- Each university has isolated data using hierarchical paths: `{state}/{city}/{campus}`
- Security rules ensure users can only access their university's data
- Role-based permissions control what operations users can perform

## Database Structure

### Firestore Collections
Each university has the following collections under `{state}/{city}/{campus}/data/`:

- `users` - User profiles and authentication data
- `mentorships` - Mentor-mentee relationship mappings
- `meetings` - Meeting schedules and details
- `messages` - Chat messages between mentors and mentees
- `announcements` - University-wide announcements
- `progress_reports` - Mentee progress tracking
- `events` - University events and workshops
- `resources` - Shared documents and materials
- `checklists` - Task management for mentees
- `newsletters` - University newsletters
- `notifications` - Push notifications and alerts

## Development Setup

### Prerequisites
- Node.js 18+
- Firebase CLI
- TypeScript

### Installation
```bash
cd functions
npm install
```

### Local Development
```bash
# Build TypeScript
npm run build

# Start Firebase emulators
npm run serve

# Deploy to Firebase
npm run deploy
```

### Environment Variables
Set up the following in your Firebase project:
- `FIREBASE_CONFIG` - Automatically set by Firebase
- Custom environment variables can be added via Firebase functions config

## Deployment

### Production Deployment
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:initUniversity
```

### Staging/Testing
Use Firebase projects for different environments:
```bash
# Switch to staging project
firebase use staging

# Deploy to staging
npm run deploy
```

## Error Handling

All functions use consistent error handling:
- Input validation with descriptive error messages
- Authentication and authorization checks
- Proper Firebase Functions error types
- Comprehensive logging for debugging

## Monitoring

Functions include logging for:
- Authentication events
- Database operations
- Error conditions
- Performance metrics

Use Firebase Console to monitor:
- Function execution logs
- Performance metrics
- Error rates
- Usage statistics

## Contributing

When adding new functions:
1. Follow the existing file structure
2. Add proper TypeScript types
3. Implement authentication checks
4. Add comprehensive error handling
5. Include logging for monitoring
6. Update this README with new functions