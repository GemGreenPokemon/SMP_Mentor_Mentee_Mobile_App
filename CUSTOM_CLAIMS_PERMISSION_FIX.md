# Custom Claims Permission Fix Documentation

## Problem Summary

Users were getting "Mentor access required" errors when trying to create announcements, even when logged in as a mentor. The issue was that Firebase Auth custom claims were not being set, so the Cloud Functions couldn't verify user permissions.

## Root Cause

1. **Database vs JWT Token Mismatch**:
   - User roles are stored in Firestore database as `userType` field
   - Cloud Functions check Firebase Auth JWT token for `role` custom claim
   - The custom claims were not being synced from database to JWT token

2. **Authentication Flow Gap**:
   - Users created in the database have `userType` set (mentor/mentee/coordinator)
   - When they log in with Firebase Auth, no custom claims are set
   - Cloud Functions reject requests because `role` is missing from JWT

## Solution Implemented

### 1. Cloud Function for Syncing Claims

Created `syncUserClaimsOnLogin` function that:
- Looks up user in database by firebase_uid or email
- Reads their `userType` field
- Sets custom claims using Firebase Admin SDK
- Returns success/failure status

Location: `functions/src/auth/triggers.ts`

### 2. Automatic Sync on Login

Modified `AuthService.signInWithEmailAndPassword()` to:
- Check if user already has custom claims
- If not, call sync function automatically
- Force token refresh to get updated claims
- Add logging for debugging

Location: `lib/services/auth_service.dart`

### 3. Manual Sync Options

Added two manual sync methods for existing sessions:

**Option A: Sync Button in Announcements**
- Added sync icon (🔄) in announcement screen app bar
- Manually triggers claims sync for current user
- Shows success/error messages

Location: `lib/screens/announcement_screen.dart`

**Option B: Developer Tools Sync**
- Added "Sync Auth Claims" in Settings → Developer Tools
- Shows detailed sync process and results

Location: `lib/screens/settings/dialogs/sync_claims_dialog.dart`

## How Custom Claims Work

```
1. User logs in with email/password
   ↓
2. Firebase Auth creates JWT token (without custom claims)
   ↓
3. Our sync function adds custom claims to token:
   {
     "email": "user@example.com",
     "role": "mentor",              // ← Added by sync
     "university_path": "..."       // ← Added by sync
   }
   ↓
4. Cloud Functions check token.role for permissions
```

## User Types and Permissions

### Super Admin (Developer Account)
- Created manually with custom claims already set
- Not in database - exists only in Firebase Auth
- Has `role: "super_admin"`
- Can access all functions

### Regular Users (Mentor/Mentee/Coordinator)
- Created through app's user management
- Exist in Firestore with `userType` field
- Need claims synced on first login
- Permissions based on role

## Deployment Steps

1. **Build Cloud Functions**:
   ```bash
   cd functions
   npm run build
   ```

2. **Run Functions Emulator**:
   ```bash
   npm run serve
   # OR
   firebase emulators:start
   ```

3. **For Production**:
   ```bash
   npm run deploy
   ```

## Testing the Fix

### For New Users:
1. Create user account in system
2. User logs in → claims sync automatically
3. Can immediately use role-based features

### For Existing Sessions:
1. Click sync button (🔄) in Announcements screen
2. Wait for success message
3. Try creating announcement - should work

### Verify Claims Are Set:
Check browser console for logs showing:
- `🔐 Role in claims AFTER: mentor`
- `🔐 ✅ SUCCESS: Role is now mentor`

## ⚠️ IMPORTANT: Current Status

**The automatic sync fix is NOT currently working.** Users still get "Mentor access required" errors even after:
- The frontend finds the user's role in the database correctly
- The user is confirmed to be a mentor
- Manual sync attempts

### What We Know:
1. Frontend can read `userType: "mentor"` from database ✓
2. Cloud Functions still don't see the `role` claim in JWT ✗
3. Manual sync button was added but needs testing ⚡
4. Auto-sync on login may not be triggering properly ✗

### Temporary Workaround:
Until the root cause is identified:
1. Use the manual sync button (🔄) in Announcements
2. Check Cloud Function logs to see if sync is being called
3. Verify custom claims are actually being set in Firebase Auth

### Next Steps Required:
1. Debug why `syncUserClaimsOnLogin` isn't setting claims properly
2. Check if Cloud Functions are receiving the updated token
3. Verify the token refresh is working after claims are set
4. Consider alternative approaches if custom claims continue to fail

## Troubleshooting

### "Permission Denied" Still Occurs:
1. Ensure cloud functions are rebuilt and running
2. Try manual sync button
3. Check console for sync errors
4. Log out and log back in

### Sync Fails:
1. Check user exists in database
2. Verify `userType` field is set
3. Check cloud function logs for errors
4. Ensure `firebase_uid` matches Auth UID

### Claims Not Persisting:
1. Force token refresh: `await user.getIdToken(true)`
2. Wait 1-2 seconds after sync
3. Verify with `getIdTokenResult()`

## Technical Details

### Custom Claims vs Custom Tokens:
- **Custom Claims**: Metadata added to existing Firebase Auth tokens (what we use)
- **Custom Tokens**: Completely custom JWT tokens (not needed here)

### Performance Benefits:
- No database lookup on every API call
- Claims included in JWT token
- Instant permission verification
- Reduces Firestore read costs

### Security:
- Claims are cryptographically signed
- Cannot be modified client-side
- Set only through Admin SDK
- Automatically included in all API requests

## Future Improvements

1. **App Startup Sync**: Check and sync claims when app initializes
2. **Middleware Pattern**: Ensure claims before any protected API call
3. **Claims Expiry**: Periodically refresh claims for role changes
4. **Batch Sync Tool**: Sync all users' claims at once (coordinator feature)

## Related Files

- `functions/src/auth/triggers.ts` - Sync function
- `functions/src/utils/auth.ts` - Permission verification
- `lib/services/auth_service.dart` - Login with auto-sync
- `lib/services/cloud_function_service.dart` - Sync API calls
- `lib/screens/announcement_screen.dart` - Manual sync button

 +  ## ⚠️ IMPORTANT: Current Status
       127 +  
       128 +  **The automatic sync fix is NOT currently working.** Users still get "Mentor access required" errors even after:
       129 +  - The frontend finds the user's role in the database correctly
       130 +  - The user is confirmed to be a mentor
       131 +  - Manual sync attempts
       132 +  
       133 +  ### What We Know:
       134 +  1. Frontend can read `userType: "mentor"` from database ✓
       135 +  2. Cloud Functions still don't see the `role` claim in JWT ✗
       136 +  3. Manual sync button was added but needs testing ⚡
       137 +  4. Auto-sync on login may not be triggering properly ✗
       138 +  
       139 +  ### Temporary Workaround:
       140 +  Until the root cause is identified:
       141 +  1. Use the manual sync button (🔄) in Announcements
       142 +  2. Check Cloud Function logs to see if sync is being called
       143 +  3. Verify custom claims are actually being set in Firebase Auth
       144 +  
       145 +  ### Next Steps Required:
       146 +  1. Debug why `syncUserClaimsOnLogin` isn't setting claims properly
       147 +  2. Check if Cloud Functions are receiving the updated token
       148 +  3. Verify the token refresh is working after claims are set
       149 +  4. Consider alternative approaches if custom claims continue to fail
       150 +  

        DOM Content Loaded
 flutter.js script tag found
 Window loaded, waiting for Flutter loader...
 serviceWorkerVersion: null
 Flutter load attempt #1
 typeof _flutter: object
 _flutter object: Object
 _flutter.loader: C
 _flutter.buildConfig: undefined
 Setting default buildConfig...
 Flutter loader ready, starting initialization...
 Installing/Activating first service worker.
 Activated new service worker.
 Injecting <script> tag. Using callback.
 Flutter entrypoint loaded, initializing engine...
 engineInitializer: Object
  registerExtension() from dart:developer is only supported in build/run/test environments where the developer event method hooks have been set by package:dwds v11.1.0 or higher.
_registerExtension @ dart_sdk.js:53156
 Flutter engine initialized, running app...
 appRunner: Object
 TrustedTypes available. Creating policy: flutterfire-firebase_core
 Initializing Firebase firebase_core
 TrustedTypes available. Creating policy: flutterfire-firebase_firestore
 Initializing Firebase firebase_firestore
 TrustedTypes available. Creating policy: flutterfire-firebase_functions
 Initializing Firebase firebase_functions
 TrustedTypes available. Creating policy: flutterfire-firebase_auth
 Initializing Firebase firebase_auth
(index):170 Flutter app started successfully!
js_primitives.dart:28 Firebase initialized successfully
js_primitives.dart:28 🔧 DeveloperSession: Initialized with isActive = false
js_primitives.dart:28 Using local Firebase Functions emulator
js_primitives.dart:28 🔧 AuthWrapper: _checkCurrentUser called
js_primitives.dart:28 🔧 AuthWrapper: No user signed in
js_primitives.dart:28 🔧 AuthWrapper build: _isLoading=false, _isCheckingRole=false, _userRole=null
js_primitives.dart:28 🔧 AuthWrapper: Auth state changed - user: null
js_primitives.dart:28 🔧 AuthWrapper: User signed out
js_primitives.dart:28 🔧 AuthWrapper build: _isLoading=false, _isCheckingRole=false, _userRole=null
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
localhost/:1 [DOM] Password field is not contained in a form: (More info: https://www.chromium.org/developers/design-documents/create-amazing-password-forms) <input tabindex=​"-1" type=​"password" autocomplete=​"off" autocorrect=​"on" class=​"flt-text-editing transparentTextEditing" style=​"forced-color-adjust:​ none;​ white-space:​ pre-wrap;​ align-content:​ center;​ position:​ absolute;​ top:​ 0px;​ left:​ 0px;​ padding:​ 0px;​ opacity:​ 1;​ color:​ transparent;​ background:​ transparent;​ caret-color:​ transparent;​ outline:​ none;​ border:​ none;​ resize:​ none;​ text-shadow:​ none;​ overflow:​ hidden;​ transform-origin:​ 0px 0px 0px;​ font:​ 500 16px "Segoe UI", Arial, sans-serif;​ width:​ 280px;​ height:​ 24px;​ transform:​ matrix(1, 0, 0, 1, 1176, 444.5)​;​">​
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
errors.dart:288  Uncaught DartError: Assertion failed: org-dartlang-sdk:///lib/_engine/engine/pointer_binding/event_position_helper.dart:70:10
targetElement == domElement
"The targeted input element must be the active input element"
    at Object.throw_ [as throw] (errors.dart:288:3)
    at Object.assertFailed (profile.dart:110:39)
    at Object._computeOffsetForInputs (profile.dart:110:39)
    at Object.computeEventOffsetToTarget (event_position_helper.dart:38:14)
    at [_convertEventsToPointerData] (pointer_binding.dart:1088:30)
    at pointer_binding.dart:1016:9
    at pointer_binding.dart:948:7
    at loggedHandler (pointer_binding.dart:541:9)
    at Object._callDartFunctionFast1 (js_allow_interop_patch.dart:212:27)
    at ret (js_allow_interop_patch.dart:81:15)
js_primitives.dart:28 🔧 AuthWrapper: Auth state changed - user: enash3@ucmerced.edu
js_primitives.dart:28 🔧 AuthWrapper: User signed in, checking role...
js_primitives.dart:28 🔧 AuthWrapper: _checkCurrentUser called
js_primitives.dart:28 🔧 Checking user: enash3@ucmerced.edu, isDevAccount: false
js_primitives.dart:28 🔥 Starting listener for: california_merced_uc_merced/data/users
js_primitives.dart:28 🔥 Connected to Firestore emulator
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔐 === CUSTOM CLAIMS SYNC START ===
js_primitives.dart:28 🔐 User logged in: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔐 Claims BEFORE sync: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔐 Role in claims BEFORE: NOT SET
js_primitives.dart:28 🔐 No role found, calling syncUserClaimsOnLogin...
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: Starting request
js_primitives.dart:28 🔧 AuthWrapper build: _isLoading=false, _isCheckingRole=true, _userRole=null
js_primitives.dart:28 🔧 AuthWrapper: Still checking role, showing loading screen
js_primitives.dart:28 🔥 Snapshot received with 100 documents
js_primitives.dart:28 🔥 Successfully updated users list with 99 users
js_primitives.dart:28 🔧 Database connected, proceeding with role lookup
js_primitives.dart:28 🔧 Searching in subcollection: california_merced_uc_merced → doc(data) → collection(users)
js_primitives.dart:28 🔧 Looking for firebase_uid: 9x1coMFmqCV2nksjJRO8a91NNzO2
js_primitives.dart:28 🔧 firebase_uid search returned 1 documents
js_primitives.dart:28 🔧 Regular user role from database: mentor
js_primitives.dart:28 🔧 DeveloperSession: Disabled and saved to preferences
js_primitives.dart:28 🔧 AuthWrapper: Setting role to: mentor
js_primitives.dart:28 🔧 AuthWrapper build: _isLoading=false, _isCheckingRole=false, _userRole=mentor
js_primitives.dart:28 🔧 AuthWrapper: _buildDashboardForRole called with role: mentor
js_primitives.dart:28 🔧 AuthWrapper: Mentor role detected, returning mentor dashboard
js_primitives.dart:28 🔥 Dashboard service connected to Firestore emulator
js_primitives.dart:28 🔥 Dashboard: Getting mentor data for user 9x1coMFmqCV2nksjJRO8a91NNzO2
js_primitives.dart:28 🔥 Dashboard: Found mentor data: Emerald Nash
js_primitives.dart:28 🔥 Dashboard: Mentor mentees field: [Dasarathi Narayanan, Justin Moskovics, Kalea Knox]
js_primitives.dart:28 🔥 Dashboard: Raw mentee data type: List<dynamic>
js_primitives.dart:28 🔥 Dashboard: Raw mentee data: [Dasarathi Narayanan, Justin Moskovics, Kalea Knox]
js_primitives.dart:28 🔥 Dashboard: menteeNames is a List with 3 items
js_primitives.dart:28 🔥 Dashboard: Processed mentee names: [Dasarathi Narayanan, Justin Moskovics, Kalea Knox]
js_primitives.dart:28 🔥 Dashboard: Final processing 3 mentees
js_primitives.dart:28 🔥 Dashboard: Final mentee names: [Dasarathi Narayanan, Justin Moskovics, Kalea Knox]
js_primitives.dart:28 🔥 Dashboard: Searching for mentee with name: "Dasarathi Narayanan"
js_primitives.dart:28 🔥 Dashboard: Added mentee: Dasarathi Narayanan (1st year, Computer Science and Engineering(CSE), Computer Science and Engineering(CSE))
js_primitives.dart:28 🔥 Dashboard: Searching for mentee with name: "Justin Moskovics"
js_primitives.dart:28 🔥 Dashboard: Added mentee: Justin Moskovics (1st year, Mechanical Engineering, Mechanical Engineering)
js_primitives.dart:28 🔥 Dashboard: Searching for mentee with name: "Kalea Knox"
js_primitives.dart:28 🔥 Dashboard: Added mentee: Kalea Knox (4th year, Computer Science and Engineering, Computer Science and Engineering)
js_primitives.dart:28 🔍 getAnnouncements: Starting request for userType: mentor
js_primitives.dart:28 🔍 getAnnouncements: Success - received data: {success: true, data: []}
127.0.0.1:5001/smp-mobile-app-462206/us-central1/syncUserClaimsOnLogin:1 
            
            
            Failed to load resource: the server responded with a status of 500 (Internal Server Error)
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: internal, message: Failed to sync user claims
js_primitives.dart:28 🔐 ❌ Error syncing claims: [firebase_functions/internal] Failed to sync user claims


js_primitives.dart:28 🔐 Error type: FirebaseFunctionsException
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: Starting request
127.0.0.1:5001/smp-mobile-app-462206/us-central1/syncUserClaimsOnLogin:1 
            
            
            Failed to load resource: the server responded with a status of 500 (Internal Server Error)
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: internal, message: Failed to sync user claims
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: Starting request
127.0.0.1:5001/smp-mobile-app-462206/us-central1/syncUserClaimsOnLogin:1 
            
            
            Failed to load resource: the server responded with a status of 500 (Internal Server Error)
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: internal, message: Failed to sync user claims
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_allow_interop_patch.dart:81 [Violation] 'requestAnimationFrame' handler took 110ms
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 Error fetching announcements: Exception: User role not found
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: Starting request
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
service.ts:96 
            
            
            POST http://127.0.0.1:5001/smp-mobile-app-462206/us-central1/syncUserClaimsOnLogin 500 (Internal Server Error)
s @ service.ts:96
postJSON @ service.ts:255
callAtURL @ service.ts:345
await in callAtURL
call @ service.ts:196
callable @ service.ts:392
(anonymous) @ functions.dart:80
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ functions.dart:78
(anonymous) @ https_callable_web.dart:54
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ https_callable_web.dart:26
(anonymous) @ https_callable.dart:49
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ https_callable.dart:33
(anonymous) @ cloud_function_service.dart:679
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
syncUserClaimsOnLogin @ cloud_function_service.dart:674
(anonymous) @ announcement_screen.dart:100
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
(anonymous) @ announcement_screen.dart:98
handleTap @ ink_well.dart:1176
invokeCallback @ recognizer.dart:351
handleTapUp @ tap.dart:656
[_checkUp] @ tap.dart:313
acceptGesture @ tap.dart:283
sweep @ arena.dart:169
handleEvent @ binding.dart:506
dispatchEvent @ binding.dart:482
dispatchEvent @ binding.dart:457
[_handlePointerEventImmediately] @ binding.dart:427
handlePointerEvent @ binding.dart:390
[_flushPointerEventQueue] @ binding.dart:337
[_handlePointerDataPacket] @ binding.dart:306
invoke1 @ platform_dispatcher.dart:1423
invokeOnPointerDataPacket @ platform_dispatcher.dart:336
[_sendToFramework] @ pointer_binding.dart:405
onPointerData @ pointer_binding.dart:225
(anonymous) @ pointer_binding.dart:1047
(anonymous) @ pointer_binding.dart:948
loggedHandler @ pointer_binding.dart:541
_callDartFunctionFast1 @ js_allow_interop_patch.dart:212
ret @ js_allow_interop_patch.dart:81
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: internal, message: Failed to sync user claims
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: Starting request
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
service.ts:96 
            
            
            POST http://127.0.0.1:5001/smp-mobile-app-462206/us-central1/syncUserClaimsOnLogin 500 (Internal Server Error)
s @ service.ts:96
postJSON @ service.ts:255
callAtURL @ service.ts:345
await in callAtURL
call @ service.ts:196
callable @ service.ts:392
(anonymous) @ functions.dart:80
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ functions.dart:78
(anonymous) @ https_callable_web.dart:54
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ https_callable_web.dart:26
(anonymous) @ https_callable.dart:49
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
call @ https_callable.dart:33
(anonymous) @ cloud_function_service.dart:679
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
syncUserClaimsOnLogin @ cloud_function_service.dart:674
(anonymous) @ announcement_screen.dart:100
(anonymous) @ async_patch.dart:610
(anonymous) @ async_patch.dart:634
_asyncStartSync @ async_patch.dart:532
(anonymous) @ announcement_screen.dart:98
handleTap @ ink_well.dart:1176
invokeCallback @ recognizer.dart:351
handleTapUp @ tap.dart:656
[_checkUp] @ tap.dart:313
acceptGesture @ tap.dart:283
sweep @ arena.dart:169
handleEvent @ binding.dart:506
dispatchEvent @ binding.dart:482
dispatchEvent @ binding.dart:457
[_handlePointerEventImmediately] @ binding.dart:427
handlePointerEvent @ binding.dart:390
[_flushPointerEventQueue] @ binding.dart:337
[_handlePointerDataPacket] @ binding.dart:306
invoke1 @ platform_dispatcher.dart:1423
invokeOnPointerDataPacket @ platform_dispatcher.dart:336
[_sendToFramework] @ pointer_binding.dart:405
onPointerData @ pointer_binding.dart:225
(anonymous) @ pointer_binding.dart:1047
(anonymous) @ pointer_binding.dart:948
loggedHandler @ pointer_binding.dart:541
_callDartFunctionFast1 @ js_allow_interop_patch.dart:212
ret @ js_allow_interop_patch.dart:81
js_primitives.dart:28 🔐 syncUserClaimsOnLogin: FirebaseFunctionsException - code: internal, message: Failed to sync user claims
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
webchannel_connection.ts:287 
            
            
            POST http://127.0.0.1:8080/google.firestore.v1.Firestore/Listen/channel?VER=8&database=projects%2Fsmp-mobile-app-462206%2Fdatabases%2F(default)&SID=4-ukVcHp84C_akg8sRyvkQ%3D%3D&RID=74518&TYPE=terminate&zx=rkg759qg092o net::ERR_BLOCKED_BY_CLIENT
gc @ webchannel_blob_es2018.js:69
Y.close @ webchannel_blob_es2018.js:83
Mo @ webchannel_connection.ts:287
close @ stream_bridge.ts:86
close @ persistent_stream.ts:416
T_ @ persistent_stream.ts:338
(anonymous) @ persistent_stream.ts:326
(anonymous) @ async_queue.ts:200
(anonymous) @ async_queue_impl.ts:138
(anonymous) @ async_queue_impl.ts:330
Promise.then
vu @ async_queue_impl.ts:189
enqueue @ async_queue_impl.ts:136
enqueueAndForget @ async_queue_impl.ts:97
handleDelayElapsed @ async_queue.ts:194
(anonymous) @ async_queue.ts:168
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 🔧 === GET USER ROLE START ===
js_primitives.dart:28 🔧 Getting role for user: enash3@ucmerced.edu (9x1coMFmqCV2nksjJRO8a91NNzO2)
js_primitives.dart:28 🔧 Token claims: {iss: https://securetoken.google.com/smp-mobile-app-462206, aud: smp-mobile-app-462206, auth_time: 1749932512, user_id: 9x1coMFmqCV2nksjJRO8a91NNzO2, sub: 9x1coMFmqCV2nksjJRO8a91NNzO2, iat: 1749932512, exp: 1749936112, email: enash3@ucmerced.edu, email_verified: true, firebase: {identities: {email: [enash3@ucmerced.edu]}, sign_in_provider: password}}
js_primitives.dart:28 🔧 ⚠️ No role in custom claims, falling back to database lookup
js_primitives.dart:28 🔧 Attempt 1/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 Error fetching announcements: Exception: User role not found
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Database connection not available, attempt 1 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 Attempt 2/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 Error fetching announcements: Exception: User role not found
js_primitives.dart:28 🔧 Database connection not available, attempt 2 failed
js_primitives.dart:28 🔧 Attempt 3/3: Getting user role from database
js_primitives.dart:28 🔧 Database connection not available, attempt 3 failed
js_primitives.dart:28 🔧 All attempts failed - database connection not available
js_primitives.dart:28 Error fetching announcements: Exception: User role not found
