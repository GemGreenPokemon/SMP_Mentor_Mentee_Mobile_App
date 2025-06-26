# Hardcoded University Path Locations

## Overview
The university path `california_merced_uc_merced` is currently hardcoded throughout the application. This document identifies all locations where this hardcoding occurs and provides code snippets for reference.

## Architecture Context
The app is designed to support multiple universities, with data structured as:
```
/{state}_{city}_{campus}/data/{collection}
```
Example: `/california_merced_uc_merced/data/users`

The university path should ideally come from:
1. Firebase Auth custom claims (`university_path`)
2. User preferences/settings
3. Organization configuration

## Client-Side (Flutter/Dart) Hardcoded Locations

### 1. Cloud Function Service
**File**: `/lib/services/cloud_function_service.dart` (Line ~1032)
```dart
String getCurrentUniversityPath() {
  // TODO: Implement logic to get university path from current user context
  // This would typically come from Firebase Auth custom claims or user preferences
  final universityPath = 'california_merced_uc_merced'; // Default for now
  print('🔍 CloudFunctionService.getCurrentUniversityPath: $universityPath');
  return universityPath;
}
```
**Impact**: Affects all cloud function calls that need university context

### 2. Auth Service
**File**: `/lib/services/auth_service.dart` (Line ~48)
```dart
// Get university path (hardcoded for now, can be made dynamic later)
String get universityPath => 'california_merced_uc_merced';
```
**Impact**: Affects authentication, user registration, and role checking

### 3. Messaging Service
**File**: `/lib/screens/web/shared/web_messaging/services/messaging_service.dart`
Multiple instances:
```dart
// Line ~124
query = _firestore
    .collection('california_merced_uc_merced')
    .doc('data')
    .collection('mentorships')
    .where('mentor_id', isEqualTo: userId);

// Similar patterns on lines 131, 502, 566, 577
```
**Impact**: Affects chat/messaging functionality

### 4. Other Locations
- `/lib/screens/web/shared/old_code/web_schedule_meeting_screen_old.dart` (Line ~259)
- Various test files in `/test/features/mentee_registration/`

## Server-Side (Cloud Functions) Hardcoded Locations

### 1. Auth Triggers
**File**: `/functions/src/auth/triggers.ts` (Lines ~69, 187)
```typescript
// Search for user in database to get their role
const universityPath = 'california_merced_uc_merced'; // Default university for now
```
**Impact**: Affects user authentication and custom claims setting

### 2. Auth Utils
**File**: `/functions/src/utils/auth.ts` (Line ~32)
```typescript
// TEMPORARY FALLBACK: Set default university_path if missing
// TODO: This should be removed once all users have proper university_path claims
universityPath = 'california_merced_uc_merced';
console.log('⚠️ verifyAuth: Using fallback university_path:', universityPath);
```
**Impact**: Affects all authenticated cloud function calls

### 3. User Acknowledgment
**File**: `/functions/src/users/acknowledgment.ts` (Lines ~42, 143)
```typescript
const universityPath = 'california_merced_uc_merced';
```
**Impact**: Affects mentee acknowledgment flow

## Implementation Plan

### Short-term Fix (Quick Win)
1. Create a configuration file/service that centralizes the university path
2. Replace all hardcoded instances with references to this configuration
3. Keep the default as UC Merced for now

### Long-term Solution
1. **User Registration**: Capture university selection during registration
2. **Custom Claims**: Add `university_path` to Firebase Auth custom claims
3. **Client Storage**: Store selected university in local preferences
4. **Dynamic Routing**: Update all database queries to use dynamic paths
5. **Multi-tenancy**: Implement proper multi-university support

### Priority Areas to Fix
1. **Auth Service** - Critical for proper user context
2. **Cloud Function Service** - Affects all server interactions
3. **Messaging Service** - Multiple hardcoded instances
4. **Cloud Functions** - Server-side path resolution

## Notes
- The database structure already supports multiple universities
- Custom claims infrastructure exists but needs university_path added
- Some functions already check for university_path in claims but fall back to hardcoded value
- Test files can keep hardcoded values for testing purposes