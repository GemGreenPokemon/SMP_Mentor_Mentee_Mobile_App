@echo off
echo.
echo 🧪 Running Firebase Integration Tests
echo ====================================
echo.
echo ⚠️  Prerequisites:
echo    - Firebase emulator must be running
echo    - Run: firebase emulators:start
echo.
echo Press Ctrl+C to cancel or any key to continue...
pause >nul

echo.
echo 🚀 Starting integration tests with Firebase emulator...
echo.

REM Run the integration tests with emulator configuration
flutter test test/integration/mentee_registration_firebase_test.dart --dart-define=USE_EMULATOR=true -v

echo.
echo ✅ Integration tests completed!
echo.
pause