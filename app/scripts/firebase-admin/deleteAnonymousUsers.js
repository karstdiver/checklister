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

async function discoverUserCollections(userId) {
  try {
    const db = admin.firestore();
    const collections = await db.collection('users').doc(userId).listCollections();
    
    const collectionNames = collections.map(col => col.id);
    console.log(`📋 Found collections for user ${userId}: ${collectionNames.join(', ')}`);
    
    return collectionNames;
  } catch (error) {
    console.log(`⚠️  Could not discover collections for user ${userId}: ${error.message}`);
    return [];
  }
}

async function confirmCollectionDeletion(userId, collectionName) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`🗂️  Delete collection '${collectionName}' for user ${userId}? (Y/n): `, (answer) => {
      rl.close();
      resolve(answer.toLowerCase() !== 'n' && answer.toLowerCase() !== 'no');
    });
  });
}

async function deleteUserProfileImages(userId) {
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({
      prefix: `profile_images/profile_${userId}_`
    });

    if (files.length === 0) {
      console.log(`ℹ️  No profile images found for user: ${userId}`);
      return 0;
    }

    console.log(`📸 Found ${files.length} profile image(s) for user: ${userId}`);
    
    const shouldDelete = await confirmStorageDeletion(userId, 'profile images', files.length);
    if (!shouldDelete) {
      console.log(`⏭️  Skipped profile image deletion for user: ${userId}`);
      return 0;
    }

    const deletePromises = files.map(file => file.delete());
    await Promise.all(deletePromises);
    
    console.log(`✅ Deleted ${files.length} profile image(s) for user: ${userId}`);
    return files.length;
  } catch (error) {
    console.log(`⚠️  Error deleting profile images for user ${userId}: ${error.message}`);
    return 0;
  }
}

async function deleteUserItemPhotos(userId) {
  try {
    const db = admin.firestore();
    const bucket = admin.storage().bucket();
    
    // First, get all checklist items belonging to this user
    const checklistsSnapshot = await db.collection('checklists')
      .where('userId', '==', userId)
      .get();
    
    if (checklistsSnapshot.empty) {
      console.log(`ℹ️  No checklists found for user: ${userId}`);
      return 0;
    }

    const itemIds = [];
    for (const checklistDoc of checklistsSnapshot.docs) {
      const checklistData = checklistDoc.data();
      if (checklistData.items && Array.isArray(checklistData.items)) {
        checklistData.items.forEach(item => {
          if (item.id) {
            itemIds.push(item.id);
          }
        });
      }
    }

    if (itemIds.length === 0) {
      console.log(`ℹ️  No checklist items found for user: ${userId}`);
      return 0;
    }

    console.log(`📋 Found ${itemIds.length} checklist item(s) for user: ${userId}`);
    
    // Find all item photos for these items
    const allPhotos = [];
    for (const itemId of itemIds) {
      const [files] = await bucket.getFiles({
        prefix: `item_photos/item_${itemId}_`
      });
      allPhotos.push(...files);
    }

    if (allPhotos.length === 0) {
      console.log(`ℹ️  No item photos found for user: ${userId}`);
      return 0;
    }

    console.log(`📸 Found ${allPhotos.length} item photo(s) for user: ${userId}`);
    
    const shouldDelete = await confirmStorageDeletion(userId, 'item photos', allPhotos.length);
    if (!shouldDelete) {
      console.log(`⏭️  Skipped item photo deletion for user: ${userId}`);
      return 0;
    }

    const deletePromises = allPhotos.map(file => file.delete());
    await Promise.all(deletePromises);
    
    console.log(`✅ Deleted ${allPhotos.length} item photo(s) for user: ${userId}`);
    return allPhotos.length;
  } catch (error) {
    console.log(`⚠️  Error deleting item photos for user ${userId}: ${error.message}`);
    return 0;
  }
}

async function deleteUserStorage(userId) {
  console.log(`🗂️  Checking Firebase Storage for user: ${userId}`);
  
  const profileImagesDeleted = await deleteUserProfileImages(userId);
  const itemPhotosDeleted = await deleteUserItemPhotos(userId);
  
  const totalDeleted = profileImagesDeleted + itemPhotosDeleted;
  
  if (totalDeleted > 0) {
    console.log(`📊 Storage cleanup summary for user ${userId}:`);
    console.log(`   - Profile images: ${profileImagesDeleted}`);
    console.log(`   - Item photos: ${itemPhotosDeleted}`);
    console.log(`   - Total files deleted: ${totalDeleted}`);
  } else {
    console.log(`ℹ️  No storage files found for user: ${userId}`);
  }
  
  return totalDeleted;
}

async function deleteUserData(userId) {
  try {
    const db = admin.firestore();
    
    // Discover what collections exist for this user
    const collections = await discoverUserCollections(userId);
    
    if (collections.length === 0) {
      console.log(`ℹ️  No collections found for user ${userId}`);
      return false;
    }
    
    let deletedCount = 0;
    
    // Ask about each collection individually
    for (const collectionName of collections) {
      const shouldDelete = await confirmCollectionDeletion(userId, collectionName);
      if (shouldDelete) {
        await db.collection('users').doc(userId).collection(collectionName).delete();
        console.log(`✅ Deleted collection '${collectionName}' for user: ${userId}`);
        deletedCount++;
      } else {
        console.log(`⏭️  Skipped collection '${collectionName}' for user: ${userId}`);
      }
    }
    
    return deletedCount > 0;
  } catch (error) {
    console.log(`⚠️  Error deleting data for user ${userId}: ${error.message}`);
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
            
            // Delete storage files first
            await deleteUserStorage(userRecord.uid);
            
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

async function confirmStorageDeletion(userId, fileType, count) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(`🗑️  Delete ${count} ${fileType} for user ${userId}? (Y/n): `, (answer) => {
      rl.close();
      // Default to 'yes' if user just presses Enter
      resolve(answer.toLowerCase() !== 'n' && answer.toLowerCase() !== 'no');
    });
  });
}

async function main() {
  console.log('🔍 Firebase Anonymous User Cleanup Script');
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