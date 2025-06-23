# Fix Test User Claims Script Guide

This script helps you set or update custom claims for test users in Firebase Authentication.

## Prerequisites

1. Make sure you have installed dependencies:
   ```bash
   cd functions
   npm install
   ```

2. Ensure Firebase Admin SDK is properly initialized (already handled in the script).

## Usage

### Method 1: Using npm script (Recommended)

```bash
# Fix claims for default test user (test@example.com)
npm run fix-claims

# Fix claims for a specific user with custom parameters
npm run fix-claims -- user@example.com mentor universities/test_university

# Parameters: email role university_path
```

### Method 2: Using npx ts-node directly

```bash
# Default usage
npx ts-node src/fix-test-user-claims.ts

# With custom email
npx ts-node src/fix-test-user-claims.ts user@example.com

# With custom email and role
npx ts-node src/fix-test-user-claims.ts user@example.com coordinator

# With all parameters
npx ts-node src/fix-test-user-claims.ts user@example.com developer universities/dev_university
```

## Available Roles

- `mentor`
- `mentee`
- `coordinator`
- `developer`
- `super_admin`

## Important Notes

1. After running the script, the user must sign out and sign back in to receive the updated claims.
2. The script will revoke refresh tokens to force token refresh on next login.
3. Make sure the user exists in Firebase Auth before running the script.
4. The script will show current claims before updating and verify the update after.

## Troubleshooting

If you encounter issues:

1. **User not found error**: Ensure the user exists in Firebase Auth first.
2. **Permission errors**: Make sure you're running with proper Firebase Admin credentials.
3. **TypeScript errors**: Run `npm install` to ensure all dependencies are installed.

## Example Output

```
🚀 Firebase Fix Test User Claims Script
=====================================

🔧 Starting to fix test user claims...
📧 User email: test@example.com
🎯 Claims to set: { role: 'mentor', university_path: 'universities/default_university' }
✅ Found user: AbCdEfGhIjKlMnOp
📋 Current claims: None
✅ Custom claims set successfully
✅ Verified claims: { role: 'mentor', university_path: 'universities/default_university' }
🔄 Revoked refresh tokens - user will get new claims on next login

✨ Success! User claims have been updated.
📝 Note: The user needs to sign out and sign back in to receive the updated claims.

👋 Script completed.
```