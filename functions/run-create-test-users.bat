@echo off

REM Script to create test users in Firebase emulator

echo Creating test users in Firebase emulator...

REM Set emulator environment variables
set FIRESTORE_EMULATOR_HOST=localhost:8080
set FIREBASE_AUTH_EMULATOR_HOST=localhost:9099

REM Navigate to functions directory
cd /d "%~dp0"

REM Compile TypeScript
echo Compiling TypeScript...
call npx tsc src/create-test-users.ts --outDir lib --module commonjs --target es2017 --lib es2017

REM Run the compiled JavaScript
echo Running test user creation...
node lib/create-test-users.js

echo Done!
pause