# Firebase Cloud Functions Setup & Deployment Guide

A complete step-by-step guide for setting up Firebase Cloud Functions with authentication for Flutter projects.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Project Setup](#firebase-project-setup)
3. [Local Development Setup](#local-development-setup)
4. [Firebase Authentication Setup](#firebase-authentication-setup)
5. [Cloud Functions Development](#cloud-functions-development)
6. [Setting Up Admin Authentication](#setting-up-admin-authentication)
7. [Deployment Process](#deployment-process)
8. [Flutter Web Configuration](#flutter-web-configuration)
9. [Testing the Setup](#testing-the-setup)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Node.js** (version 20.0.0 or higher)
- **npm** (comes with Node.js)
- **Firebase CLI**
- **Flutter SDK**
- **Git**

### Installation Commands
```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Verify installations
node --version
npm --version
firebase --version
flutter --version
```

---

## Firebase Project Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name (e.g., `my-app-project`)
4. Enable Google Analytics (optional)
5. Wait for project creation

### 2. Enable Required Services
In Firebase Console, enable these services:
- **Authentication** (Authentication → Get started)
- **Firestore Database** (Firestore Database → Create database)
- **Cloud Functions** (Functions → Get started)

### 3. Get Firebase Configuration
1. Go to Project Settings (gear icon)
2. Scroll to "Your apps" section
3. Click "Web app" icon `</>`
4. Register your app with a nickname
5. **Copy the Firebase configuration** - you'll need this later

Example config:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123def456"
};
```

---

## Local Development Setup

### 1. Login to Firebase CLI
```bash
firebase login
```
- This opens a browser for Google authentication
- Accept permissions and return to terminal

### 2. Initialize Firebase in Your Project
```bash
# Navigate to your project root
cd /path/to/your/flutter/project

# Initialize Firebase
firebase init
```

### 3. Firebase Init Configuration
When prompted, select:
- **Functions**: TypeScript
- **Firestore**: Yes (for database rules)
- **Use existing project**: Select your Firebase project
- **ESLint**: Yes
- **Install dependencies**: Yes

### 4. Project Structure After Init
```
your-project/
├── firebase.json
├── .firebaserc
├── functions/
│   ├── src/
│   │   └── index.ts
│   ├── package.json
│   ├── tsconfig.json
│   └── .eslintrc.js
└── firestore.rules
```

---

## Firebase Authentication Setup

### 1. Enable Authentication Methods
In Firebase Console → Authentication → Sign-in method:
1. Click "Email/Password"
2. Enable "Email/Password"
3. Save

### 2. Create Admin User
In Firebase Console → Authentication → Users:
1. Click "Add user"
2. Enter email: `admin@yourproject.com`
3. Enter a secure password
4. Click "Add user"
5. **Copy the User UID** - you'll need this for setting admin claims

---

## Cloud Functions Development

### 1. Install Dependencies
```bash
cd functions
npm install firebase-admin cors express
npm install --save-dev @types/cors @types/express
```

### 2. Basic Function Structure
Create organized folders in `functions/src/`:
```
functions/src/
├── index.ts              # Main exports
├── types/
│   └── index.ts          # TypeScript interfaces
├── utils/
│   ├── auth.ts           # Authentication utilities
│   └── database.ts       # Database utilities
├── university/
│   └── initialization.ts # University management
├── users/
│   └── management.ts     # User management
└── ...other modules
```

### 3. Example Auth Utility (`utils/auth.ts`)
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export async function verifySuperAdmin(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
  }

  const claims = context.auth.token;
  if (!claims.role || claims.role !== 'super_admin') {
    throw new functions.https.HttpsError('permission-denied', 'Super admin access required');
  }

  return {
    uid: context.auth.uid,
    email: claims.email,
    role: claims.role
  };
}
```

### 4. Example Function (`university/initialization.ts`)
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { verifySuperAdmin } from '../utils/auth';

export const initializeUniversity = functions.https.onCall(
  async (data: { state: string; city: string; campus: string; universityName: string }, context) => {
    try {
      // Verify authentication
      const authContext = await verifySuperAdmin(context);
      
      const { state, city, campus, universityName } = data;
      
      if (!state || !city || !campus || !universityName) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
      }

      const db = admin.firestore();
      const universityPath = `${state}/${city}/${campus}`;
      
      // Your function logic here...
      
      return {
        success: true,
        universityPath,
        message: `University ${universityName} initialized successfully`
      };
      
    } catch (error) {
      console.error('Error:', error);
      throw new functions.https.HttpsError('internal', 'Failed to initialize university');
    }
  }
);
```

### 5. Main Export File (`index.ts`)
```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Import and export functions
import { initializeUniversity } from './university/initialization';

export const initUniversity = initializeUniversity;
```

---

## Setting Up Admin Authentication

### Method 1: Using Google Cloud Shell (Recommended)

1. **Open Firebase Console**
2. **Click Cloud Shell icon** (top right)
3. **Install Firebase Admin SDK**:
   ```bash
   npm install firebase-admin
   ```
4. **Set admin claims**:
   ```bash
   node -e "
   const admin = require('firebase-admin');
   admin.initializeApp({projectId: 'YOUR_PROJECT_ID'});
   admin.auth().setCustomUserClaims('USER_UID_HERE', {
     role: 'super_admin',
     university_path: null
   }).then(() => {
     console.log('✅ Super admin claims set successfully!');
     process.exit(0);
   }).catch(error => {
     console.error('❌ Error:', error.message);
     process.exit(1);
   });
   "
   ```

### Method 2: Using Local Script

1. **Create script file** (`functions/set-admin.js`):
   ```javascript
   const admin = require('firebase-admin');
   
   admin.initializeApp({
     projectId: 'YOUR_PROJECT_ID'
   });
   
   admin.auth().setCustomUserClaims('USER_UID_HERE', {
     role: 'super_admin',
     university_path: null
   }).then(() => {
     console.log('✅ Super admin claims set!');
     process.exit(0);
   }).catch(console.error);
   ```

2. **Run the script**:
   ```bash
   cd functions
   node set-admin.js
   rm set-admin.js  # Clean up
   ```

---

## Deployment Process

### 1. Build Functions
```bash
cd functions
npm run build
```

### 2. Deploy Functions
```bash
firebase deploy --only functions
```

### 3. Deployment Options
```bash
# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy specific function
firebase deploy --only functions:functionName
```

### 4. Monitor Deployment
Watch for:
- ✅ Successful build completion
- ✅ Function URLs in output
- ✅ All functions deployed successfully

Example successful output:
```
+  functions[initUniversity(us-central1)] Successful update operation.
+  functions[healthCheck(us-central1)] Successful update operation.
Function URL (healthCheck): https://us-central1-your-project.cloudfunctions.net/healthCheck
+  Deploy complete!
```

---

## Flutter Web Configuration

### 1. Update `web/index.html`
Add Firebase SDKs before `</head>`:
```html
<!-- Firebase SDKs -->
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-functions-compat.js"></script>

<!-- Firebase Configuration -->
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "your-project.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "123456789",
    appId: "your-app-id"
  };

  firebase.initializeApp(firebaseConfig);
</script>
```

### 2. Flutter Dependencies
Ensure these are in `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.3
  cloud_firestore: ^5.6.6
  cloud_functions: ^5.4.0
```

### 3. Initialize Firebase in Flutter
In `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

---

## Testing the Setup

### 1. Test Cloud Functions
```bash
# Run Flutter web app
flutter run -d web-server

# Or test functions directly
curl https://us-central1-your-project.cloudfunctions.net/healthCheck
```

### 2. Test Authentication Flow
1. Navigate to your Flutter web app
2. Try accessing admin-protected features
3. Verify login prompts appear
4. Test with admin credentials
5. Verify functions execute successfully

### 3. Firebase Console Monitoring
Monitor in Firebase Console:
- **Functions** → Logs (check for errors)
- **Authentication** → Users (verify login attempts)
- **Firestore** → Data (verify database operations)

---

## Troubleshooting

### Common Issues & Solutions

#### 1. "Firebase app not initialized"
**Problem**: Firebase not properly initialized in Flutter web
**Solution**: 
- Verify `web/index.html` has correct Firebase config
- Check Firebase initialization in `main.dart`

#### 2. "Authentication required" errors
**Problem**: Functions require auth but user not logged in
**Solution**:
- Verify user has admin claims set
- Check authentication flow in Flutter app
- Test with correct admin credentials

#### 3. "Permission denied" errors
**Problem**: User doesn't have required role
**Solution**:
- Verify admin claims are set correctly
- Check user UID is correct
- Re-run admin claims script if needed

#### 4. Functions deployment fails
**Problem**: Various deployment issues
**Solution**:
- Check Node.js version (≥20.0.0)
- Verify `firebase login` is active
- Run `npm run build` first
- Check function syntax for errors

#### 5. CORS errors in web browser
**Problem**: Cross-origin request blocked
**Solution**:
- Ensure Firebase web config is correct
- Check that functions use proper CORS headers
- Verify domain is authorized in Firebase Console

### Useful Commands

```bash
# Check Firebase login status
firebase login:list

# Check current project
firebase projects:list

# View function logs
firebase functions:log

# Run functions locally
npm run serve

# Update Firebase CLI
npm install -g firebase-tools@latest

# Check function URLs
firebase functions:list
```

---

## Security Best Practices

### 1. Environment Variables
Never commit sensitive data:
```bash
# Use Firebase config for sensitive values
firebase functions:config:set someservice.key="THE API KEY"
```

### 2. Function Security
- Always validate input parameters
- Use proper authentication checks
- Implement rate limiting for public functions
- Use TypeScript for type safety

### 3. Database Security
- Configure Firestore security rules
- Use least-privilege access patterns
- Validate data on both client and server

### 4. Authentication
- Use strong passwords for admin accounts
- Regularly rotate admin credentials
- Monitor authentication logs
- Implement proper role-based access

---

## Next Steps

After completing this setup:

1. **Expand Functions**: Add more cloud functions for your app's needs
2. **Improve Security**: Implement more granular role-based access
3. **Add Monitoring**: Set up alerting and logging
4. **Performance**: Optimize function performance and costs
5. **CI/CD**: Set up automated deployment pipelines

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Flutter Firebase Integration](https://firebase.flutter.dev/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

---

*This guide was created based on the SMP Mentor-Mentee Mobile App Firebase setup process.*