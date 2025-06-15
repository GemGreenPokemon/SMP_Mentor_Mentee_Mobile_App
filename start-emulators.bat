@echo off
REM Start Firebase emulators with proper configuration
echo Starting Firebase emulators...

REM Export environment variable to indicate emulator mode
set FUNCTIONS_EMULATOR=true

REM Navigate to functions directory and build
cd functions
call npm run build

REM Go back to root directory
cd ..

REM Start emulators with all services
firebase emulators:start --import=./emulator-data --export-on-exit