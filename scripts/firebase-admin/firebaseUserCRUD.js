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

async function getUserCollections(userId) {
  try {
    const db = admin.firestore();
    
    // First, check if the user document exists
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`📄 User document does not exist for user ${userId}`);
      return [];
    }
    
    console.log(`📄 User document exists for user ${userId}`);
    console.log(`📋 Document fields: ${Object.keys(userDoc.data()).join(', ')}`);
    
    // Then check for subcollections
    const collections = await db.collection('users').doc(userId).listCollections();
    const collectionNames = collections.map(col => col.id);
    
    if (collectionNames.length > 0) {
      console.log(`📁 Subcollections: ${collectionNames.join(', ')}`);
    } else {
      console.log(`📁 No subcollections found`);
    }
    
    return collectionNames;
  } catch (error) {
    console.log(`⚠️  Could not get collections for user ${userId}: ${error.message}`);
    return [];
  }
}

async function deleteUserCollections(userId, collections) {
  try {
    const db = admin.firestore();
    let deletedCount = 0;
    
    for (const collectionName of collections) {
      const shouldDelete = await promptUser(`🗂️  Delete collection '${collectionName}' for user ${userId}? (y/N): `);
      if (shouldDelete) {
        await db.collection('users').doc(userId).collection(collectionName).delete();
        console.log(`✅ Deleted collection '${collectionName}' for user: ${userId}`);
        deletedCount++;
      } else {
        console.log(`⏭️  Skipped collection '${collectionName}' for user: ${userId}`);
      }
    }
    
    return deletedCount;
  } catch (error) {
    console.log(`⚠️  Error deleting collections for user ${userId}: ${error.message}`);
    return 0;
  }
}

async function promptUser(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

async function displayUserInfo(userRecord) {
  console.log('\n' + '='.repeat(60));
  console.log(`👤 User ID: ${userRecord.uid}`);
  console.log(`📧 Email: ${userRecord.email || 'No email'}`);
  console.log(`📝 Display Name: ${userRecord.displayName || 'No display name'}`);
  console.log(`📱 Phone: ${userRecord.phoneNumber || 'No phone'}`);
  console.log(`📅 Created: ${userRecord.metadata.creationTime}`);
  console.log(`🔄 Last Sign In: ${userRecord.metadata.lastSignInTime}`);
  console.log(`🔐 Provider: ${userRecord.providerData.length > 0 ? userRecord.providerData[0].providerId : 'Anonymous'}`);
  console.log(`✅ Email Verified: ${userRecord.emailVerified}`);
  console.log(`🚫 Disabled: ${userRecord.disabled}`);
}

async function processUser(userRecord) {
  // Display user information
  await displayUserInfo(userRecord);
  
  // Get user's collections
  const collections = await getUserCollections(userRecord.uid);
  
  if (collections.length > 0) {
    console.log(`📋 Collections: ${collections.join(', ')}`);
  } else {
    console.log(`📋 Collections: None found`);
  }
  
  // Ask if user wants to delete this user
  const shouldDeleteUser = await promptUser(`🗑️  Delete user ${userRecord.uid}? (y/N): `);
  
  if (shouldDeleteUser) {
    try {
      // If user has collections, ask about deleting them
      if (collections.length > 0) {
        const shouldDeleteCollections = await promptUser(`🗂️  Delete all collections for user ${userRecord.uid}? (y/N): `);
        
        if (shouldDeleteCollections) {
          await deleteUserCollections(userRecord.uid, collections);
        } else {
          console.log(`⚠️  User will be deleted but collections will remain (orphaned data)`);
        }
      }
      
      // Delete the user from Firebase Auth
      await admin.auth().deleteUser(userRecord.uid);
      console.log(`✅ Deleted user: ${userRecord.uid}`);
      return { deleted: true, collectionsDeleted: collections.length > 0 };
      
    } catch (error) {
      console.error(`❌ Error deleting user ${userRecord.uid}:`, error.message);
      return { deleted: false, error: error.message };
    }
  } else {
    console.log(`⏭️  Skipped user: ${userRecord.uid}`);
    return { deleted: false, skipped: true };
  }
}

async function main() {
  console.log('🔍 Firebase User CRUD Script');
  console.log('============================\n');
  
  let totalUsers = 0;
  let deletedUsers = 0;
  let skippedUsers = 0;
  let errorUsers = 0;
  let nextPageToken;

  try {
    do {
      // List users (max 1000 per page)
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      
      // Process each user
      for (const userRecord of listUsersResult.users) {
        totalUsers++;
        const result = await processUser(userRecord);
        
        if (result.deleted) {
          deletedUsers++;
        } else if (result.skipped) {
          skippedUsers++;
        } else {
          errorUsers++;
        }
      }
      
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 SUMMARY');
    console.log('='.repeat(60));
    console.log(`👥 Total users processed: ${totalUsers}`);
    console.log(`✅ Users deleted: ${deletedUsers}`);
    console.log(`⏭️  Users skipped: ${skippedUsers}`);
    if (errorUsers > 0) {
      console.log(`❌ Users with errors: ${errorUsers}`);
    }
    console.log('🎉 Script completed!');
    
  } catch (error) {
    console.error('💥 Error listing users:', error.message);
    process.exit(1);
  }
  
  process.exit(0);
}

// Run the main function
main().catch((error) => {
  console.error('💥 Script failed:', error);
  process.exit(1);
}); 