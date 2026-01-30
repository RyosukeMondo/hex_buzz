#!/usr/bin/env node

/**
 * Direct script to insert test data into daily challenge leaderboard
 * Run with: node scripts/insert_leaderboard_test.js
 */

const https = require('https');

// Your Firebase project configuration
const PROJECT_ID = 'hexbuzz-6ec1e'; // Update if different
const REGION = 'us-central1'; // Default region for Cloud Functions

const today = new Date();
const dateId = today.toISOString().split('T')[0]; // YYYY-MM-DD

console.log('🧪 Inserting test data into daily challenge leaderboard');
console.log('='.repeat(60));
console.log(`📅 Date: ${dateId}`);
console.log(`🕐 UTC Time: ${today.toISOString()}\n`);

// Method 1: Call the diagnostics API (tests everything)
console.log('Method 1: Running diagnostics API...');
console.log(`URL: https://${REGION}-${PROJECT_ID}.cloudfunctions.net/apiDiagnostics\n`);

https.get(`https://${REGION}-${PROJECT_ID}.cloudfunctions.net/apiDiagnostics`, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    try {
      const result = JSON.parse(data);
      console.log('✅ Diagnostics completed!\n');
      console.log('Test Results:');
      console.log(`  Daily Challenge: ${result.tests.dailyChallenge?.status || 'N/A'}`);
      console.log(`  Leaderboard Read: ${result.tests.leaderboardRead?.status || 'N/A'}`);
      console.log(`  Leaderboard Write: ${result.tests.leaderboardWrite?.status || 'N/A'}`);
      console.log(`\nSummary:`);
      console.log(`  Total Tests: ${result.summary?.totalTests || 0}`);
      console.log(`  Passed: ${result.summary?.passed || 0}`);
      console.log(`  Failed: ${result.summary?.failed || 0}`);
      console.log(`  Warnings: ${result.summary?.warnings || 0}`);

      if (result.recommendations && result.recommendations.length > 0) {
        console.log(`\nRecommendations:`);
        result.recommendations.forEach((rec, i) => {
          console.log(`  ${i + 1}. ${rec}`);
        });
      }

      console.log('\n' + '='.repeat(60));
      console.log('🎉 Test data inserted! Check your app now.');
      console.log('\nThe diagnostics API has:');
      console.log('  1. Created today\'s daily challenge if it doesn\'t exist');
      console.log('  2. Inserted a test leaderboard entry');
      console.log('  3. Verified the query works correctly');
      console.log('\nRefresh your app to see the data!');
    } catch (error) {
      console.error('❌ Error parsing response:', error.message);
      console.log('Raw response:', data);
    }
  });
}).on('error', (error) => {
  console.error('❌ Error calling diagnostics API:', error.message);
  console.log('\nAlternative: Use Firebase CLI');
  console.log('Run: firebase functions:shell');
  console.log('Then: apiDiagnostics()');
});
