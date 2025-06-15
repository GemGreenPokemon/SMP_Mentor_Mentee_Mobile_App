# Firebase Emulator Setup Guide

## Prerequisites
- Firebase CLI installed
- Node.js installed
- Firebase emulators initialized

## Running the Emulators

1. Start the Firebase emulators:
   ```bash
   firebase emulators:start
   ```

2. The following emulators will start:
   - **Auth**: http://localhost:9099
   - **Firestore**: http://localhost:8080
   - **Functions**: http://localhost:5001
   - **Emulator UI**: http://localhost:4000

## Setting up Super Admin User

Since the Auth emulator starts with an empty database, you need to create a super-admin user:

### Method 1: Using the Setup Script (Recommended)

1. Make sure your emulators are running
2. Navigate to the functions directory:
   ```bash
   cd functions
   ```

3. Run the setup script:
   ```bash
   node emulator-setup.js
   ```

This will create:
- **Primary Super Admin Account**:
  - Email: `sunsetcoding.dev@gmail.com`
  - Password: `admin123456`
  - Role: `super_admin`
  
- **Secondary Admin Account**:
  - Email: `admin@smp-mobile-app.com`
  - Password: `admin123456`
  - Role: `super_admin`

### Method 2: Manual Setup via Emulator UI

1. Go to http://localhost:4000
2. Navigate to the Authentication tab
3. Click "Add user"
4. Create a user with your desired email/password
5. Note the UID
6. Set custom claims using the Admin SDK or Cloud Functions

## Important Notes

- The emulator data is ephemeral - it's cleared when you stop the emulators
- To persist data between sessions, use:
  ```bash
  firebase emulators:start --export-on-exit=./emulator-data --import=./emulator-data
  ```
- Super-admin users have `university_path: null` in their custom claims
- Regular users get their roles from the Firestore database

## Troubleshooting

### "User already exists" error
This happens when you're connected to production Auth instead of the emulator. Make sure:
1. The Auth emulator is configured in `firebase.json`
2. Your app is connecting to the emulator (check for the 🔐 emoji in console logs)

### Custom claims not working
- Custom claims are stored in the JWT token
- You may need to force a token refresh after setting claims
- Sign out and sign back in to get the updated token

### Cannot connect to emulator
- Check that the emulator is running on the correct port (9099 for Auth)
- Ensure no firewall is blocking localhost connections
- Try using `127.0.0.1` instead of `localhost` if issues persist