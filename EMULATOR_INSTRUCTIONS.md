# Firebase Emulator Instructions

## Starting the Emulators

### Windows
```bash
# Run from project root
start-emulators.bat
```

### Mac/Linux
```bash
# Run from project root
chmod +x start-emulators.sh
./start-emulators.sh
```

### Manual Start
```bash
# 1. Build functions first
cd functions
npm run build
cd ..

# 2. Start emulators
firebase emulators:start
```

## Running the Flutter App with Emulators

### Web Development
```bash
# Make sure to use localhost (not 127.0.0.1)
flutter run -d chrome --web-hostname localhost --web-port 5000
```

### Important Notes

1. **Always use localhost**: When running on web, access the app via `http://localhost:5000` (or your chosen port), NOT `http://127.0.0.1:5000`

2. **Build functions before starting**: The functions must be built before starting the emulators:
   ```bash
   cd functions && npm run build && cd ..
   ```

3. **Check emulator status**: Visit `http://localhost:4000` to see the Emulator UI and verify all services are running

4. **CORS Issues**: If you encounter CORS errors:
   - Make sure you're accessing via `localhost` not `127.0.0.1`
   - Ensure emulators are running before starting the Flutter app
   - Check that functions are built and deployed to emulator

## Troubleshooting

### CORS Errors
- Error: "has been blocked by CORS policy"
- Solution: 
  1. Stop the Flutter app
  2. Restart emulators: `firebase emulators:start`
  3. Run Flutter with: `flutter run -d chrome --web-hostname localhost --web-port 5000`

### Functions Not Found
- Error: "Function not found"
- Solution:
  1. Build functions: `cd functions && npm run build`
  2. Restart emulators

### Authentication Issues
- Make sure Auth emulator is running (port 9099)
- Check that your app is configured to use the auth emulator

## Emulator Ports
- Auth: 9099
- Functions: 5001
- Firestore: 8080
- Emulator UI: 4000