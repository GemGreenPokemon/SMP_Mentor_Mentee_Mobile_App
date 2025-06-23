#!/bin/bash

# Script to create test users in Firebase emulator

echo "🚀 Creating test users in Firebase emulator..."

# Set emulator environment variables
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export FIREBASE_AUTH_EMULATOR_HOST="localhost:9099"

# Navigate to functions directory
cd "$(dirname "$0")"

# Compile TypeScript
echo "📦 Compiling TypeScript..."
npx tsc src/create-test-users.ts --outDir lib --module commonjs --target es2017 --lib es2017

# Run the compiled JavaScript
echo "🏃 Running test user creation..."
node lib/create-test-users.js

echo "✅ Done!"