// To run this script, you need to have the firebase-admin SDK installed.
// brew install node
// npm install firebase-admin
// npm install readline
// node --version
// npm --version
// node scripts/firebase-admin/deleteAnonymousUsers.js

// Check if Node.js is installed
try {
  const nodeVersion = process.version;
  console.log(`✅ Node.js version: ${nodeVersion}`);
} catch (error) {
  console.log('❌ Node.js is not installed or not accessible.');
  console.log('\n To install Node.js:');
  console.log('   Option 1 (macOS with Homebrew):');
  console.log('     brew install node');
  console.log('\n   Option 2 (Download from website):');
  console.log('     Visit https://nodejs.org/ and download the LTS version');
  console.log('\n   After installation, verify with:');
  console.log('     node --version');
  console.log('     npm --version');
  process.exit(1);
}

// Check if required packages are installed
try {
  require('firebase-admin');
  console.log('✅ firebase-admin package is installed');
} catch (error) {
  console.log('❌ firebase-admin package is not installed.');
  console.log('\n📦 To install required packages:');
  console.log('   npm install firebase-admin');
  console.log('\n   Or if you haven\'t initialized the project:');
  console.log('   npm init -y');
  console.log('   npm install firebase-admin');
  process.exit(1);
}

const admin = require('firebase-admin');
const readline = require('readline');

// Check if service account key exists
try {
  const serviceAccount = require('./serviceAccountKey.json');
  console.log('✅ Service account key found');
} catch (error) {
  console.log('❌ Service account key not found.');
  console.log('\n📋 To get your service account key:');
  console.log('   1. Go to Firebase Console: https://console.firebase.google.com/');
  console.log('   2. Select your project');
  console.log('   3. Go to Project Settings > Service Accounts');
  console.log('   4. Click "Generate new private key"');
  console.log('   5. Save the JSON file as "serviceAccountKey.json" in this directory');
  process.exit(1);
}

// Initialize Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function deleteUserData(userId) {
  try {
    const db = admin.firestore();
    
    // Delete user's collections (add more as needed)
    await db.collection('users').doc(userId).delete();
    // Add other collections here when you create them:
    // await db.collection('checklists').doc(userId).delete();
    // await db.collection('items').doc(userId).delete();
    
    console.log(`✅ Deleted Firestore data for user: ${userId}`);
    return true;
  } catch (error) {
    console.log(`⚠️  No Firestore data found for user: ${userId} (or error: ${error.message})`);
    return false;
  }
}

async function deleteAnonymousUsers() {
  console.log('🔍 Starting to scan for anonymous users...');
  
  let deletedCount = 0;
  let errorCount = 0;
  let dataDeletedCount = 0;
  let nextPageToken;

  try {
    do {
      // List users (max 1000 per page)
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      
      // Check each user
      for (const userRecord of listUsersResult.users) {
        // Anonymous users have no provider data
        if (userRecord.providerData.length === 0) {
          try {
            // Delete the user from Firebase Auth
            await admin.auth().deleteUser(userRecord.uid);
            console.log(`✅ Deleted anonymous user: ${userRecord.uid}`);
            deletedCount++;
            
            // Ask if user wants to delete associated data
            const shouldDeleteData = await confirmDataDeletion(userRecord.uid);
            if (shouldDeleteData) {
              const dataDeleted = await deleteUserData(userRecord.uid);
              if (dataDeleted) {
                dataDeletedCount++;
              }
            }
            
          } catch (error) {
            console.error(`❌ Error deleting user ${userRecord.uid}:`, error.message);
            errorCount++;
          }
        }
      }
      
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log('\n📊 Summary:');
    console.log(`✅ Successfully deleted: ${deletedCount} anonymous users`);
    console.log(`🗂️  User data deleted: ${dataDeletedCount} users`);
    if (errorCount > 0) {
      console.log(`❌ Errors encountered: ${errorCount}`);
    }
    
  } catch (error) {
    console.error('❌ Error listing users:', error.message);
  }
}

async function confirmDeletion() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question('⚠️  This will delete ALL anonymous users. Are you sure? (yes/No): ', (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'yes');
    });
  });
}

async function confirmDataDeletion(userId) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`🗂️  Delete associated data for user ${userId}? (Y/n): `, (answer) => {
      rl.close();
      // Default to 'yes' if user just presses Enter
      resolve(answer.toLowerCase() !== 'n' && answer.toLowerCase() !== 'no');
    });
  });
}

async function main() {
  console.log('�� Firebase Anonymous User Cleanup Script');
  console.log('==========================================\n');
  
  const confirmed = await confirmDeletion();
  if (confirmed) {
    await deleteAnonymousUsers();
    console.log('🎉 Script completed!');
  } else {
    console.log('❌ Operation cancelled.');
  }
  process.exit(0);
}

// Run the main function
main().catch((error) => {
  console.error('💥 Script failed:', error);
  process.exit(1);
});