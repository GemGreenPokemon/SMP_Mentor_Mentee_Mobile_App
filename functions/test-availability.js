// Quick test script for availability function
// Run with: node test-availability.js

const fetch = require('node-fetch');

async function testSetAvailability() {
  console.log('Testing setAvailability function...\n');
  
  // Replace with your actual emulator URL and a valid auth token
  const EMULATOR_URL = 'http://127.0.0.1:5001/smp-mobile-app-462206/us-central1/setAvailability';
  
  // Test data
  // Create auth header for emulator
  const mockAuth = {
    uid: 'WkP9Mpc3IXSEG97sdRgIzEK19NWX',
    token: {
      role: 'mentor',
      university_path: 'california_merced_uc_merced',
      email: 'enash3@ucmerced.edu',
      email_verified: true
    }
  };
  
  const testData = {
    data: {
      universityPath: 'california_merced_uc_merced',
      mentor_id: 'WkP9Mpc3IXSEG97sdRgIzEK19NWX', // Your actual mentor UID
      day: '2025-06-27',
      slots: [
        { slot_start: '09:00', slot_end: '10:00' },
        { slot_start: '10:00', slot_end: '11:00' },
        { slot_start: '14:00', slot_end: '15:00' }
      ]
    }
  };
  
  try {
    console.log('Sending request to:', EMULATOR_URL);
    console.log('Request data:', JSON.stringify(testData, null, 2));
    
    const response = await fetch(EMULATOR_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // Add auth context for emulator
        'x-callable-context-auth': JSON.stringify(mockAuth)
      },
      body: JSON.stringify(testData)
    });
    
    const result = await response.json();
    
    if (response.ok) {
      console.log('\n✅ SUCCESS! Availability set successfully:');
      console.log(JSON.stringify(result, null, 2));
    } else {
      console.log('\n❌ ERROR:', response.status);
      console.log(JSON.stringify(result, null, 2));
    }
    
  } catch (error) {
    console.error('\n❌ Request failed:', error.message);
  }
}

// Also test the debug function
async function testDebugTimestamp() {
  console.log('\n\nTesting debugTimestamp function...\n');
  
  const DEBUG_URL = 'http://127.0.0.1:5001/smp-mobile-app-462206/us-central1/debugTimestamp';
  
  try {
    const response = await fetch(DEBUG_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ data: {} })
    });
    
    const result = await response.json();
    
    console.log('Debug results:');
    console.log(JSON.stringify(result, null, 2));
    
  } catch (error) {
    console.error('Debug test failed:', error.message);
  }
}

// Run the tests
async function runTests() {
  await testDebugTimestamp();
  await testSetAvailability();
}

runTests();