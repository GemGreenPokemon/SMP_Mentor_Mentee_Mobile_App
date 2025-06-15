# Cloud Function Name Mapping Guide

## Important: Function Export Names vs Implementation Names

When calling Firebase Cloud Functions from the Flutter app, you must use the **exported names** from `functions/src/index.ts`, NOT the implementation function names.

## The Issue

The Cloud Functions are implemented with one set of names but exported with different names in `index.ts`. The Flutter app must use the exported names when calling these functions.

### Example of the Problem
```typescript
// In functions/src/meetings/management.ts
export const setMentorAvailability = functions.https.onCall(async (data) => { ... });

// In functions/src/index.ts
export const setAvailability = setMentorAvailability;  // ← Exported with different name!
```

```dart
// ❌ WRONG - This will fail with CORS/internal errors
final callable = _functions.httpsCallable('setMentorAvailability');

// ✅ CORRECT - Use the exported name
final callable = _functions.httpsCallable('setAvailability');
```

## Complete Function Name Mapping

### Meeting Management Functions
| Implementation Name | Exported Name | Used For |
|-------------------|---------------|----------|
| createMeeting | scheduleMeeting | Creating new meetings |
| updateMeeting | updateMeetingDetails | Updating meeting details |
| cancelMeeting | deleteMeeting | Canceling/deleting meetings |
| acceptMeeting | approveMeeting | Mentor accepts meeting |
| rejectMeeting | declineMeeting | Mentor rejects meeting |

### Availability Management Functions
| Implementation Name | Exported Name | Used For |
|-------------------|---------------|----------|
| setMentorAvailability | setAvailability | Setting mentor's available slots |
| getMentorAvailability | getAvailability | Getting mentor's availability |
| getAvailableSlots | getBookableSlots | Getting available slots for booking |
| requestMeeting | requestMeetingTime | Requesting custom meeting time |

### Announcement Functions (Working correctly)
| Implementation Name | Exported Name | Used For |
|-------------------|---------------|----------|
| createAnnouncement | postAnnouncement | Creating announcements |
| updateAnnouncement | updateAnnouncementDetails | Updating announcements |
| deleteAnnouncement | removeAnnouncement | Deleting announcements |
| getAnnouncements | getAnnouncementsList | Fetching announcements |

### User Management Functions
| Implementation Name | Exported Name | Used For |
|-------------------|---------------|----------|
| createUser | createUserAccount | Creating user accounts |
| updateUser | updateUserAccount | Updating user accounts |
| deleteUser | deleteUserAccount | Deleting user accounts |
| getAllUsers | getUsersList | Getting all users |
| bulkCreateUsers | bulkCreateUserAccounts | Bulk user creation |
| bulkAssignMentors | bulkAssignMentorAccounts | Bulk mentor assignment |

## Why This Matters

1. **CORS Errors**: Using the wrong function name results in CORS errors that look like: `"has been blocked by CORS policy"`
2. **Internal Errors**: You'll see errors like `[firebase_functions/internal] internal`
3. **Confusing Debugging**: The error doesn't clearly indicate it's a naming issue

## How to Check Function Names

1. Always check `functions/src/index.ts` for the exported names
2. The exported name (left side of assignment) is what you use in Flutter
3. The implementation name (right side) is internal to the functions

## Best Practices

1. **Consistency**: Consider using the same names for implementation and export to avoid confusion
2. **Documentation**: Document any name differences clearly
3. **Testing**: When adding new functions, test the exported name immediately

## Quick Reference for Developers

When you see these errors:
- CORS policy blocking requests
- Internal function errors
- Function working in some places but not others

**First check**: Are you using the exported function name from `index.ts`?

## Example Fix

```dart
// In CloudFunctionService.dart
Future<Map<String, dynamic>> setMentorAvailability(...) async {
  final HttpsCallable callable = _functions.httpsCallable(
    'setAvailability',  // ← Use exported name, not 'setMentorAvailability'
  );
  // ... rest of the code
}
```