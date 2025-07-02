# SMP Mentor-Mentee Mobile App - Overview & Documentation

## Table of Contents
1. [Overview](#overview)
2. [Core Features](#core-features)
3. [User Roles & Permissions](#user-roles--permissions)
4. [Technical Architecture](#technical-architecture)
5. [Security Features](#security-features)
6. [Development Status](#development-status)

## Overview

The SMP (Student Mentorship Program) Mentor-Mentee Mobile App is a comprehensive cross-platform application built with Flutter that facilitates mentorship relationships in an educational setting. Originally designed for UC Merced's mentorship program, the app provides tools for communication, scheduling, progress tracking, and resource sharing between mentors and mentees.

### Key Objectives
- Streamline mentor-mentee communication
- Facilitate meeting scheduling and management
- Track mentee progress and program requirements
- Provide centralized access to program resources
- Ensure secure, role-based access to features

## Core Features

### 1. **Messaging System**
- **Real-time Chat**: 
  - Direct messaging between mentors and assigned mentees
  - Direct line for mentors to message program coordinators
- **Message History**: Persistent conversation history with timestamps
- **Status Indicators**: Visual indicators for sent/received messages
- **Offline Support**: Local database caching for offline access
- **File Attachments**: Support for document sharing (in development)
- **Conversation Management**: Clear chat history, block users functionality

### 2. **Meeting Scheduling & Calendar**
#### For Mentors:
- Set weekly availability time slots
- Create recurring meeting schedules
- Review and approve/reject meeting requests
- Cancel meetings with automated notifications
- View all upcoming meetings in calendar format

#### For Mentees:
- View mentor's available time slots
- Request meetings at available times
- Propose custom meeting times
- Track meeting request status
- Cancel or reschedule requests

#### Shared Features:
- **Calendar View**: Visual calendar with color-coded meeting statuses
- **Location Selection**: Choose from predefined locations or add custom
- **Day Schedule View**: Detailed daily meeting information
- **Status Indicators**: 
  - Green: Available slots
  - Yellow: Pending requests
  - Blue: Confirmed meetings
  - Red: Rejected/Cancelled

### 3. **Checklist & Progress Tracking**
- **Task Assignment**: Mentors create and assign tasks to mentees
- **Priority Levels**: High, Medium, Low with visual indicators
- **Progress Monitoring**: Percentage-based completion tracking
- **Due Date Management**: Track deadlines and overdue items
- **Proof Submission System**: 
  - Mentees submit proof of completion
  - Mentors review and approve/reject
  - Feedback on rejections
  - Resubmission capability
- **Focus Mode**: Highlights most urgent tasks

### 4. **Announcements System**
- **Role-based Creation**: 
  - Coordinators: Create program-wide announcements
  - Mentors: Create announcements for their mentees
  - Mentees: View-only access
- **Priority Levels**: Mark important announcements
- **Targeted Distribution**: Send to specific user groups
- **Real-time Updates**: Instant notification of new announcements

### 5. **Progress Reports & Analytics**
- **Mentee Progress Tracking**: Overall completion percentages
- **Meeting Analytics**: Frequency and attendance tracking
- **Goal Progress**: Track achievement of mentorship goals
- **Academic Performance**: Integration with academic data
- **Export Capabilities**: Generate reports for program evaluation

### 6. **Resource Hub**
- **Document Repository**: Centralized storage for program materials
- **File Management**: Upload/download PDFs, DOCX, XLSX files
- **Version Control**: Track document updates
- **Access Control**: Role-based document permissions
- **Quick Links**: Curated external resources
- **Mentor Resources**: Mentors can upload custom materials for mentees

### 7. **Additional Features**
- **Newsletter System**: Regular program updates
- **Meeting Notes**: Document discussion points and action items
- **Check-in/Check-out**: Meeting attendance tracking
- **Acknowledgment System**: Mentee agreement to program terms
- **Email Verification**: Account verification process
- **Settings Dashboard**: User preferences and account management

## User Roles & Permissions

### 1. **Mentee**
- View assigned mentor information
- Message their assigned mentor
- Request and manage meetings
- Complete assigned tasks and submit proof
- Access program resources
- View announcements
- Track personal progress

### 2. **Mentor**
- View assigned mentees (up to 3)
- Message all assigned mentees
- Direct messaging line to program coordinator
- Set availability and manage meetings
- Create and assign tasks to mentees
- Review and approve task completions
- Upload resources for mentees
- Create announcements for their mentees
- Track mentee progress
- Request coordinator assistance when needed

### 3. **Coordinator**
- Full administrative access
- View and monitor all mentors and mentees
- Create program-wide announcements
- Manage program resources
- Access analytics and reports
- Review escalated issues
- Manage user accounts and permissions
- **Meeting Management**:
  - Can reschedule meetings for any mentor-mentee pair
  - Override meeting decisions
  - Resolve scheduling conflicts
- **Mentorship Assignment**:
  - Assign mentees to mentors
  - Reassign mentees when needed
  - Balance mentor workloads
- **Communication**:
  - Receive direct messages from mentors
  - Monitor program-wide communication
  - Intervene when necessary

### 4. **Developer** (Special Role)
- Access to testing tools
- Database management interface
- Debug features
- Emulator configuration
- Test data generation

## Technical Architecture

### Frontend Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider pattern
- **UI/UX**: Material Design 3
- **Platforms**: iOS, Android, Web
- **Responsive Design**: Adaptive layouts for all screen sizes

### Backend Stack
- **Database**: Firebase Firestore (NoSQL)
- **Authentication**: Firebase Auth
- **Cloud Functions**: Node.js/TypeScript
- **File Storage**: Firebase Storage
- **Local Storage**: SQLite for offline support

### Architecture Patterns
- **Modular Architecture**: Clear separation of concerns
- **Repository Pattern**: Centralized data access layer
- **Service Layer**: Business logic with singleton pattern
- **Feature-based Organization**: Screens organized by feature/role
- **Stream-based Updates**: Real-time data synchronization

### Key Services
- **AuthService**: Authentication and authorization
- **MeetingService**: Meeting scheduling and management
- **MessagingService**: Chat functionality
- **AnnouncementService**: Announcement management
- **CloudFunctionService**: Backend API integration
- **LocalDatabaseService**: Offline data persistence

## Security Features

### 1. **Authentication & Authorization**
- **Firebase Authentication**: Secure user authentication
- **Email Verification**: Required for account activation
- **Custom Claims**: Role-based access control through Firebase custom claims
- **Session Management**: Secure token-based sessions

### 2. **Access Control**
- **Whitelist System**: Only pre-approved email addresses can register
- **Role-based Permissions**: Features restricted based on user role
- **Cloud Function Validation**: Server-side permission checks
- **Firebase Security Rules**: Database-level access control

### 3. **Data Protection**
- **Encryption**: Data encrypted in transit and at rest
- **Secure Communication**: HTTPS/TLS for all API calls
- **Input Validation**: Client and server-side validation
- **SQL Injection Prevention**: Parameterized queries

### 4. **Planned Security Enhancements**
- **Two-Factor Authentication (2FA)**: Additional security layer (in development)
- **Audit Logging**: Track sensitive operations
- **Rate Limiting**: Prevent abuse of API endpoints
- **Password Policies**: Enforce strong password requirements

### 5. **Privacy Features**
- **Data Isolation**: Users only access their assigned relationships
- **Message Privacy**: Conversations limited to participants
- **Secure File Storage**: Role-based file access
- **GDPR Compliance**: User data management capabilities

## Development Status

### Completed Features ✅
- User authentication and role management
- Basic messaging functionality
- Meeting scheduling system
- Checklist creation and management
- Announcement system
- Web and mobile responsive design
- Local database for offline support
- Firebase emulator integration

### In Progress 🚧
- File attachment in messaging
- Two-factor authentication
- Advanced analytics dashboard
- Push notifications
- Meeting transcription feature
- Comprehensive test coverage

### Planned Features 📋
- Video call integration
- Advanced reporting tools
- Bulk user import
- Mobile app offline sync
- Internationalization support
- Dark mode theme

## Development Environment

### Prerequisites
- Flutter SDK 3.6.0+
- Firebase CLI
- Node.js (for Cloud Functions)
- Android Studio / Xcode

### Key Dependencies
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Real-time database
- **cloud_functions**: Backend integration
- **provider**: State management
- **sqflite**: Local database
- **table_calendar**: Calendar UI
- **fl_chart**: Analytics charts

### Running the App
```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run

# Run with emulators
flutter run --dart-define=USE_EMULATOR=true
```

---

*This document provides an overview of the SMP Mentor-Mentee Mobile App as of the current development state. Features and specifications may evolve as development continues.*