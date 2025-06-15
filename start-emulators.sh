#!/bin/bash

# Start Firebase emulators with proper configuration
echo "Starting Firebase emulators..."

# Export environment variable to indicate emulator mode
export FUNCTIONS_EMULATOR=true

# Navigate to functions directory and build
cd functions
npm run build

# Go back to root directory
cd ..

# Start emulators with all services
firebase emulators:start --import=./emulator-data --export-on-exit