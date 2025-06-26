# Mentee Acknowledgment Screen Issue

## Problem Summary
The mentee acknowledgment screen is not showing for users with `acknowledgment_signed: "no"`. Instead, the mentee dashboard is displayed even though the system correctly identifies that acknowledgment is needed.

## Project Context
- **Project**: SMP Mentor/Mentee Mobile App
- **Platform**: Flutter Web (also supports mobile)
- **Backend**: Firebase (Firestore + Cloud Functions)
- **Environment**: Using Firebase Emulators locally
- **Authentication**: Firebase Auth with custom claims

## User Data
```json
{
  "name": "Test User",
  "email": "user@gmail.com",
  "userType": "mentee",
  "acknowledgment_signed": "no",
  "student_id": "100381847",
  "department": "Engineering",
  "year_major": "5th yr, Computer Science"
}
```

## Expected Flow
1. Mentee logs in with `acknowledgment_signed: "no"`
2. System checks acknowledgment status
3. Shows acknowledgment screen
4. After signing, sets custom claims and allows access to dashboard

## Actual Flow (From Logs)
1. User logs in successfully
2. System correctly identifies: `acknowledgment_signed = "no"` and `needsAcknowledgment = true`
3. BUT: Dashboard is shown instead of acknowledgment screen

## Implementation Details

### 1. Flow Restructuring Completed
We restructured the authentication flow so that:
- Custom claims are NOT set for mentees until AFTER acknowledgment is signed
- Other user types (mentors, coordinators) get custom claims immediately
- This prevents mentees from accessing the app without acknowledgment

### 2. Files Modified

#### `/lib/services/auth_service.dart`
- Added `_getUserDataByName()` and `_getUserDataByEmail()` helper methods
- Modified registration (line ~150) to check if user is mentee with unsigned acknowledgment
- Modified sign-in (line ~300) with same logic
- Custom claims only set if: user is NOT mentee OR mentee has signed acknowledgment

#### `/lib/widgets/auth_wrapper.dart`
- Added comprehensive debugging with `🔧🔧🔧` markers
- Created `_checkMenteeAcknowledgmentDirect()` method (line ~192)
- Queries Firestore directly for acknowledgment status
- Returns `true` if acknowledgment needed, `false` if already signed
- Added debugging to track widget build flow

#### `/functions/src/users/acknowledgment.ts`
- Modified `submitMenteeAcknowledgment` to set custom claims AFTER acknowledgment
- Removed role check since mentees won't have claims yet
- After successful acknowledgment submission:
  - Updates `acknowledgment_signed` to "yes"
  - Sets custom claims `{role: 'mentee', university_path: '...'}`
  - Returns success with claims info

#### `/lib/screens/web/mentee/web_mentee_acknowledgment/controllers/acknowledgment_controller.dart`
- Added token refresh after successful submission (line ~73)
- Ensures new custom claims are applied immediately

#### `/lib/screens/web/mentee/web_mentee_acknowledgment/web_mentee_acknowledgment_screen.dart`
- Added debug markers `🎯🎯🎯` to track if screen is being created/rendered

### 3. Debugging Added

Key debug markers to look for:
- `🔧🔧🔧` - Critical flow points in AuthWrapper
- `🎯🎯🎯` - Acknowledgment screen lifecycle
- `🔐` - Custom claims setting/checking

### 4. Current Issue

Despite correct acknowledgment check returning `true`, the dashboard is shown. Possible causes:
1. Multiple AuthWrapper rebuilds overriding the decision
2. Navigation/routing issue
3. State management problem
4. Timing issue with FutureBuilder

### 5. Next Steps

1. **Run the app with new debugging** and look for:
   - Whether `🎯🎯🎯 WebMenteeAcknowledgmentScreen initState called!` appears
   - The sequence of `🔧🔧🔧` logs to track widget flow
   - Any unexpected rebuilds or state changes

2. **Check for navigation issues**:
   - Look for any automatic navigation to '/mentee' route
   - Check if acknowledgment screen is created but immediately replaced

3. **Possible solutions to try**:
   - Add a delay before checking acknowledgment
   - Use a different state management approach
   - Check if there's a route guard redirecting to dashboard

### 6. Commands to Run

```bash
# Rebuild cloud functions
cd functions
npm run build

# Start emulators
firebase emulators:start

# Run Flutter app
flutter run -d chrome
```

### 7. Key Code Sections

The main acknowledgment check flow in `/lib/widgets/auth_wrapper.dart`:
```dart
case 'mentee':
  return FutureBuilder<bool>(
    future: _checkMenteeAcknowledgmentDirect(),
    builder: (context, snapshot) {
      if (needsAcknowledgment) {
        return Responsive.isWeb() 
            ? const WebMenteeAcknowledgmentScreen() 
            : const MenteeAcknowledgmentScreen();
      } else {
        return Responsive.isWeb() 
            ? const WebMenteeDashboardScreen() 
            : const MenteeDashboardScreen();
      }
    },
  );
```

The acknowledgment check in `_checkMenteeAcknowledgmentDirect()` correctly returns `true` when `acknowledgment_signed: "no"`, but the dashboard is still shown.

### 8. Key Log Output Showing the Issue

```
🔧 AuthWrapper: Found user in database
🔧 AuthWrapper: User type: mentee
🔧 AuthWrapper: acknowledgment_signed = "no"
🔧 AuthWrapper: needsAcknowledgment = true
🔧 AuthWrapper: Mentee needs acknowledgment
...
[BUT THEN]
BackgroundRefreshManager: Registered controller mentee_dashboard
WebMenteeDashboardScreen: Calling initial load...
```

### 9. Database Structure
```
/california_merced_uc_merced/data/users/{userId}
  - name: string
  - email: string
  - userType: string ("mentee", "mentor", "coordinator")
  - acknowledgment_signed: string ("yes" or "no")
  - firebase_uid: string (added after first login)
```

### 10. Custom Claims Structure
```json
{
  "role": "mentee",
  "university_path": "california_merced_uc_merced"
}
```

### 11. Important Notes
- Custom claims are set via Cloud Functions, not client-side
- The app uses role-based access control based on custom claims
- Email verification is bypassed in debug mode
- The acknowledgment is meant to be a one-time gate for mentees only

### 12. ROOT CAUSE FOUND AND FIXED

The issue was that the **email verification screen** was running a background check and automatically navigating to `/mentee` when it detected the email was verified (which is always true in debug mode).

**The Problem Flow:**
1. User logs in with `acknowledgment_signed: "no"`
2. AuthWrapper correctly shows acknowledgment screen
3. Email verification logic runs in background
4. Since email is "verified" in debug mode, it calls `getUserRole()`
5. It then navigates directly to `/mentee` based on the role
6. This navigation overrides the acknowledgment screen

**The Fix:**
Changed `EmailVerificationScreen._checkEmailVerified()` to navigate back to the AuthWrapper (`/`) instead of directly to role-based routes (`/mentee`, `/mentor`, etc.). This lets the AuthWrapper properly check acknowledgment status and show the correct screen.

```dart
// OLD: VerificationHelpers.navigateToDashboard(context, userRole);
// NEW: Navigator.pushReplacementNamed(context, '/');
```

This ensures the acknowledgment check always happens through AuthWrapper's logic.