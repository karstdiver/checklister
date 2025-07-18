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

// Add the names of top-level collections that reference userId
const userLinkedCollections = ['sessions', 'checklists']; // Add more as needed

async function deleteUserTopLevelDocs(userId) {
  const db = admin.firestore();
  let totalDeleted = 0;
  for (const collectionName of userLinkedCollections) {
    console.log(`🔍 Checking collection '${collectionName}' for documents belonging to user ${userId}...`);
    const snapshot = await db.collection(collectionName).where('userId', '==', userId).get();
    if (snapshot.empty) {
      console.log(`ℹ️  No documents found in '${collectionName}' for user ${userId}`);
      continue;
    }
    for (const doc of snapshot.docs) {
      await doc.ref.delete();
      totalDeleted++;
      console.log(`✅ Deleted document ${doc.id} from '${collectionName}' for user ${userId}`);
    }
    console.log(`🗑️  Deleted ${snapshot.size} documents from '${collectionName}' for user ${userId}`);
  }
  return totalDeleted;
}

async function deleteUserDocument(userId) {
  const db = admin.firestore();
  const userDocRef = db.collection('users').doc(userId);
  const userDoc = await userDocRef.get();
  if (userDoc.exists) {
    await userDocRef.delete();
    console.log(`✅ Deleted user document for user: ${userId}`);
    return true;
  } else {
    console.log(`ℹ️  No user document found for user: ${userId}`);
    return false;
  }
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
    
    const shouldDelete = await promptUser(`🗑️  Delete ${files.length} profile image(s) for user ${userId}? (y/N): `);
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
    
    const shouldDelete = await promptUser(`🗑️  Delete ${allPhotos.length} item photo(s) for user ${userId}? (y/N): `);
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

async function processUser(userRecord) {
  // Display user information
  await displayUserInfo(userRecord);
  
  // Get user's collections
  const collections = await getUserCollections(userRecord.uid);
  
  if (collections.length > 0) {
    console.log(`📋 Subcollections: ${collections.join(', ')}`);
  } else {
    console.log(`📋 Subcollections: None found`);
  }

  // Info: Top-level collections to be checked
  console.log(`📋 Top-level collections to be checked for userId: ${userLinkedCollections.join(', ')}`);

  // Ask if user wants to delete this user
  const shouldDeleteUser = await promptUser(`🗑️  Delete user ${userRecord.uid}? (y/N): `);
  
  if (shouldDeleteUser) {
    try {
      // If user has subcollections, ask about deleting them
      if (collections.length > 0) {
        const shouldDeleteCollections = await promptUser(`🗂️  Delete all subcollections for user ${userRecord.uid}? (y/N): `);
        if (shouldDeleteCollections) {
          await deleteUserCollections(userRecord.uid, collections);
        } else {
          console.log(`⚠️  User will be deleted but subcollections will remain (orphaned data)`);
        }
      }
      // Delete user's storage files first
      const storageFilesDeleted = await deleteUserStorage(userRecord.uid);
      // Delete user document in 'users' collection
      await deleteUserDocument(userRecord.uid);
      // Delete all top-level docs in user-linked collections
      await deleteUserTopLevelDocs(userRecord.uid);
      // Delete the user from Firebase Auth
      await admin.auth().deleteUser(userRecord.uid);
      console.log(`✅ Deleted user: ${userRecord.uid}`);
      return { deleted: true, collectionsDeleted: collections.length > 0, storageFilesDeleted };
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
  let totalStorageFilesDeleted = 0;
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
          if (result.storageFilesDeleted) {
            totalStorageFilesDeleted += result.storageFilesDeleted;
          }
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
    if (totalStorageFilesDeleted > 0) {
      console.log(`🗂️  Storage files deleted: ${totalStorageFilesDeleted}`);
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