/**
 * Firebase User CRUD Script with Admin Role and User Tier Management
 * 
 * This script allows you to:
 * - View all users in Firebase Auth
 * - Create new users with default settings
 * - Delete users and their associated data
 * - Manage admin roles for users
 * - Manage user tiers (affects TTL periods)
 * 
 * Usage:
 * - (y) - Delete the user and all associated data
 * - (N) - Skip the user
 * - (a) - Manage admin role for the user
 * - (t) - Manage user tier for the user
 * - (c) - Create a new user
 * 
 * Admin Roles:
 * - none: No admin privileges
 * - moderator: View analytics, basic admin panel
 * - admin: Full system management, TTL management
 * - superAdmin: Complete system control, user management
 * 
 * User Tiers:
 * - anonymous: 7 days TTL, basic features
 * - free: 30 days TTL, standard features
 * - premium: 365 days TTL, enhanced features
 * - pro: Unlimited TTL, all features
 */

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
      const lowerAnswer = answer.toLowerCase();
      if (lowerAnswer === 'y' || lowerAnswer === 'yes') {
        resolve('yes');
      } else if (lowerAnswer === 'a' || lowerAnswer === 'admin') {
        resolve('admin');
      } else if (lowerAnswer === 't' || lowerAnswer === 'tier') {
        resolve('tier');
      } else if (lowerAnswer === 'p' || lowerAnswer === 'password') {
        resolve('password');
      } else if (lowerAnswer === 'c' || lowerAnswer === 'create') {
        resolve('create');
      } else {
        resolve('no');
      }
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
  
  // Display admin role and user tier information
  await displayAdminRoleInfo(userRecord.uid);
  await displayUserTierInfo(userRecord.uid);
}

async function displayAdminRoleInfo(userId) {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      const adminRole = userData.adminRole || 'none';
      const adminRoleAssignedBy = userData.adminRoleAssignedBy || 'N/A';
      const adminRoleAssignedAt = userData.adminRoleAssignedAt ? 
        new Date(userData.adminRoleAssignedAt.toDate()).toLocaleString() : 'N/A';
      const adminRoleNotes = userData.adminRoleNotes || 'N/A';
      
      console.log(`👑 Admin Role: ${adminRole.toUpperCase()}`);
      console.log(`👤 Assigned By: ${adminRoleAssignedBy}`);
      console.log(`📅 Assigned At: ${adminRoleAssignedAt}`);
      if (adminRoleNotes !== 'N/A') {
        console.log(`📝 Notes: ${adminRoleNotes}`);
      }
    } else {
      console.log(`👑 Admin Role: NONE (no user document found)`);
    }
  } catch (error) {
    console.log(`⚠️  Could not retrieve admin role info: ${error.message}`);
  }
}

async function displayUserTierInfo(userId) {
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      const userTier = userData.tier || 'anonymous';
      const subscriptionStatus = userData.subscriptionStatus || 'N/A';
      const subscriptionExpiry = userData.subscriptionExpiry ? 
        new Date(userData.subscriptionExpiry.toDate()).toLocaleString() : 'N/A';
      
      console.log(`💎 User Tier: ${userTier.toUpperCase()}`);
      console.log(`📊 Subscription Status: ${subscriptionStatus}`);
      if (subscriptionExpiry !== 'N/A') {
        console.log(`📅 Subscription Expiry: ${subscriptionExpiry}`);
      }
      
      // Show TTL information based on tier
      const ttlInfo = getTTLInfoForTier(userTier);
      console.log(`⏰ TTL Period: ${ttlInfo}`);
      
      // Note: User documents don't have TTL fields - TTL is applied to checklists and sessions
      console.log(`🕒 Firestore TTL: Applied to checklists/sessions, not user document`);
    } else {
      console.log(`💎 User Tier: ANONYMOUS (no user document found)`);
      console.log(`⏰ TTL Period: 7 days (default for anonymous)`);
      console.log(`🕒 Firestore TTL: Not available (no document)`);
    }
  } catch (error) {
    console.log(`⚠️  Could not retrieve user tier info: ${error.message}`);
  }
}

function getTTLInfoForTier(tier) {
  switch (tier.toLowerCase()) {
    case 'anonymous':
      return '7 days';
    case 'free':
      return '30 days';
    case 'premium':
      return '365 days (1 year)';
    case 'pro':
      return 'Unlimited (no expiration)';
    default:
      return '7 days (default)';
  }
}

async function manageUserTier(userId) {
  console.log(`\n💎 User Tier Management for user: ${userId}`);
  console.log('='.repeat(50));
  
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`❌ User document not found for ${userId}. Cannot manage user tier.`);
      return false;
    }
    
    const userData = userDoc.data();
    const currentTier = userData.tier || 'anonymous';
    
    console.log(`📋 Current user tier: ${currentTier.toUpperCase()}`);
    console.log(`⏰ Current TTL: ${getTTLInfoForTier(currentTier)}`);
    console.log('\n🔄 Available user tiers:');
    console.log('  1. anonymous - 7 days TTL, basic features');
    console.log('  2. free - 30 days TTL, standard features');
    console.log('  3. premium - 365 days TTL, enhanced features');
    console.log('  4. pro - Unlimited TTL, all features');
    console.log('  5. cancel - Cancel tier change');
    
    const tierChoice = await promptUserChoice('Select new user tier (1-5): ', ['1', '2', '3', '4', '5']);
    
    let newTier;
    switch (tierChoice) {
      case '1':
        newTier = 'anonymous';
        break;
      case '2':
        newTier = 'free';
        break;
      case '3':
        newTier = 'premium';
        break;
      case '4':
        newTier = 'pro';
        break;
      case '5':
        console.log('⏭️  User tier change cancelled.');
        return false;
      default:
        console.log('❌ Invalid choice. User tier change cancelled.');
        return false;
    }
    
    if (newTier === currentTier) {
      console.log(`ℹ️  User already has tier: ${currentTier.toUpperCase()}`);
      return false;
    }
    
    // Get notes for the tier change
    const notes = await promptUserText('Enter notes for this tier change (optional): ');
    
    // Confirm the change
    const confirmChange = await promptUser(`🗳️  Change user tier from ${currentTier.toUpperCase()} to ${newTier.toUpperCase()}? (y/N): `);
    
    if (confirmChange === 'yes') {
      const updateData = {
        tier: newTier,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };
      
      // Add tier change notes if provided
      if (notes) {
        updateData.tierChangeNotes = notes;
        updateData.tierChangedAt = admin.firestore.FieldValue.serverTimestamp();
        updateData.tierChangedBy = 'firebase-admin-script';
      }
      
      await db.collection('users').doc(userId).update(updateData);
      
      console.log(`✅ Successfully changed user tier to: ${newTier.toUpperCase()}`);
      console.log(`⏰ New TTL Period: ${getTTLInfoForTier(newTier)}`);
      return true;
    } else {
      console.log('⏭️  User tier change cancelled.');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Error managing user tier: ${error.message}`);
    return false;
  }
}

async function changeUserPassword(userId) {
  console.log(`\n🔐 Password Change for user: ${userId}`);
  console.log('='.repeat(50));
  
  try {
    // Check if user exists
    const userRecord = await admin.auth().getUser(userId);
    console.log(`📧 User email: ${userRecord.email}`);
    
    // Get new password
    const newPassword = await promptUserText('Enter new password (min 6 characters): ');
    if (!newPassword || newPassword.length < 6) {
      console.log('❌ Password must be at least 6 characters');
      return false;
    }
    
    // Confirm password
    const confirmPassword = await promptUserText('Confirm new password: ');
    if (newPassword !== confirmPassword) {
      console.log('❌ Passwords do not match');
      return false;
    }
    
    // Get notes for the password change
    const notes = await promptUserText('Enter notes for this password change (optional): ');
    
    // Confirm the change
    const confirmChange = await promptUser(`🗳️  Change password for ${userRecord.email}? (y/N): `);
    
    if (confirmChange === 'yes') {
      // Update password in Firebase Auth
      await admin.auth().updateUser(userId, {
        password: newPassword
      });
      
      console.log(`✅ Successfully changed password for: ${userRecord.email}`);
      
      // Update Firestore document with password change notes if provided
      if (notes) {
        try {
          const db = admin.firestore();
          await db.collection('users').doc(userId).update({
            'passwordChangedAt': admin.firestore.FieldValue.serverTimestamp(),
            'passwordChangedBy': 'firebase-admin-script',
            'passwordChangeNotes': notes,
            'updatedAt': admin.firestore.FieldValue.serverTimestamp()
          });
          console.log(`📝 Password change notes saved to Firestore`);
        } catch (firestoreError) {
          console.log(`⚠️  Could not save password change notes to Firestore: ${firestoreError.message}`);
        }
      }
      
      return true;
    } else {
      console.log('⏭️  Password change cancelled.');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Error changing password: ${error.message}`);
    return false;
  }
}

async function createNewUser() {
  console.log(`\n👤 Create New User`);
  console.log('='.repeat(50));
  
  try {
    // Get user details
    const email = await promptUserText('Enter email address: ');
    if (!email || !email.includes('@')) {
      console.log('❌ Invalid email address');
      return false;
    }
    
    const displayName = await promptUserText('Enter display name (optional): ');
    const password = await promptUserText('Enter password (min 6 characters): ');
    if (!password || password.length < 6) {
      console.log('❌ Password must be at least 6 characters');
      return false;
    }
    
    // Select user tier
    console.log('\n🔄 Select user tier:');
    console.log('  1. anonymous - 7 days TTL, basic features');
    console.log('  2. free - 30 days TTL, standard features (default)');
    console.log('  3. premium - 365 days TTL, enhanced features');
    console.log('  4. pro - Unlimited TTL, all features');
    
    const tierChoice = await promptUserChoice('Select user tier (1-4, default 2): ', ['1', '2', '3', '4']);
    
    let userTier;
    switch (tierChoice) {
      case '1':
        userTier = 'anonymous';
        break;
      case '2':
      default:
        userTier = 'free';
        break;
      case '3':
        userTier = 'premium';
        break;
      case '4':
        userTier = 'pro';
        break;
    }
    
    // Select admin role
    console.log('\n👑 Select admin role:');
    console.log('  1. none - No admin privileges (default)');
    console.log('  2. moderator - View analytics, basic admin panel');
    console.log('  3. admin - Full system management, TTL management');
    console.log('  4. superAdmin - Complete system control, user management');
    
    const adminChoice = await promptUserChoice('Select admin role (1-4, default 1): ', ['1', '2', '3', '4']);
    
    let adminRole;
    switch (adminChoice) {
      case '1':
      default:
        adminRole = 'none';
        break;
      case '2':
        adminRole = 'moderator';
        break;
      case '3':
        adminRole = 'admin';
        break;
      case '4':
        adminRole = 'superAdmin';
        break;
    }
    
    // Confirm creation
    console.log(`\n📋 User Details:`);
    console.log(`   Email: ${email}`);
    console.log(`   Display Name: ${displayName || 'Not set'}`);
    console.log(`   User Tier: ${userTier.toUpperCase()}`);
    console.log(`   Admin Role: ${adminRole.toUpperCase()}`);
    console.log(`   TTL Period: ${getTTLInfoForTier(userTier)}`);
    
    const confirmCreate = await promptUser(`🗳️  Create this user? (y/N): `);
    
    if (confirmCreate === 'yes') {
      // Create Firebase Auth user
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: displayName || null,
        emailVerified: false,
      });
      
      console.log(`✅ Created Firebase Auth user: ${userRecord.uid}`);
      
      // Create Firestore user document with default values
      const db = admin.firestore();
      const now = admin.firestore.FieldValue.serverTimestamp();
      
      const userData = {
        'uid': userRecord.uid,
        'email': email,
        'displayName': displayName || null,
        'photoURL': null,
        'emailVerified': false,
        'providerId': 'email',
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
        'tier': userTier,
        'adminRole': adminRole,
        'adminRoleAssignedBy': 'firebase-admin-script',
        'adminRoleAssignedAt': now,
        'adminRoleNotes': `User created with ${userTier} tier and ${adminRole} admin role`,
        'subscription': {
          'tier': userTier,
          'status': 'active',
          'autoRenew': false,
        },
        'usage': {
          'checklistsCreated': 0,
          'sessionsCompleted': 0,
        },
        'preferences': {
          'themeMode': 'system',
          'language': 'en_US',
          'notifications': {
            'email': true,
            'push': true,
          },
        },
        'stats': {
          'totalChecklists': 0,
          'completedChecklists': 0,
          'totalItems': 0,
          'completedItems': 0,
          'lastActivity': now,
        },
      };
      
      await db.collection('users').doc(userRecord.uid).set(userData);
      
      console.log(`✅ Created Firestore user document for: ${userRecord.uid}`);
      console.log(`📧 Email verification required: ${!userRecord.emailVerified}`);
      console.log(`💎 User Tier: ${userTier.toUpperCase()}`);
      console.log(`👑 Admin Role: ${adminRole.toUpperCase()}`);
      console.log(`⏰ TTL Period: ${getTTLInfoForTier(userTier)}`);
      
      return true;
    } else {
      console.log('⏭️  User creation cancelled.');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Error creating user: ${error.message}`);
    return false;
  }
}

async function manageAdminRole(userId) {
  console.log(`\n🔧 Admin Role Management for user: ${userId}`);
  console.log('='.repeat(50));
  
  try {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`❌ User document not found for ${userId}. Cannot manage admin role.`);
      return false;
    }
    
    const userData = userDoc.data();
    const currentAdminRole = userData.adminRole || 'none';
    
    console.log(`📋 Current admin role: ${currentAdminRole.toUpperCase()}`);
    console.log('\n🔄 Available admin roles:');
    console.log('  1. none - No admin privileges');
    console.log('  2. moderator - View analytics, basic admin panel');
    console.log('  3. admin - Full system management, TTL management');
    console.log('  4. superAdmin - Complete system control, user management');
    console.log('  5. cancel - Cancel admin role change');
    
    const roleChoice = await promptUserChoice('Select new admin role (1-5): ', ['1', '2', '3', '4', '5']);
    
    let newAdminRole;
    switch (roleChoice) {
      case '1':
        newAdminRole = 'none';
        break;
      case '2':
        newAdminRole = 'moderator';
        break;
      case '3':
        newAdminRole = 'admin';
        break;
      case '4':
        newAdminRole = 'superAdmin';
        break;
      case '5':
        console.log('⏭️  Admin role change cancelled.');
        return false;
      default:
        console.log('❌ Invalid choice. Admin role change cancelled.');
        return false;
    }
    
    if (newAdminRole === currentAdminRole) {
      console.log(`ℹ️  User already has role: ${currentAdminRole.toUpperCase()}`);
      return false;
    }
    
    // Get notes for the role change
    const notes = await promptUserText('Enter notes for this role change (optional): ');
    
    // Confirm the change
    const confirmChange = await promptUser(`🗳️  Change admin role from ${currentAdminRole.toUpperCase()} to ${newAdminRole.toUpperCase()}? (y/N): `);
    
    if (confirmChange === 'yes') {
      await db.collection('users').doc(userId).update({
        adminRole: newAdminRole,
        adminRoleAssignedBy: 'firebase-admin-script',
        adminRoleAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminRoleNotes: notes || `Role changed from ${currentAdminRole} to ${newAdminRole}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ Successfully changed admin role to: ${newAdminRole.toUpperCase()}`);
      return true;
    } else {
      console.log('⏭️  Admin role change cancelled.');
      return false;
    }
    
  } catch (error) {
    console.log(`❌ Error managing admin role: ${error.message}`);
    return false;
  }
}

async function promptUserChoice(question, validChoices) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const askQuestion = () => {
      rl.question(question, (answer) => {
        if (validChoices.includes(answer)) {
          rl.close();
          resolve(answer);
        } else {
          console.log(`❌ Invalid choice. Please enter one of: ${validChoices.join(', ')}`);
          askQuestion();
        }
      });
    };
    
    askQuestion();
  });
}

async function promptUserText(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
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

  // Ask if user wants to delete this user, manage admin role, manage user tier, or change password
  const shouldDeleteUser = await promptUser(`🗑️  Delete user ${userRecord.uid}? (y/N/a for admin/t for tier/p for password): `);
  
  if (shouldDeleteUser === 'yes') {
    try {
      // If user has subcollections, ask about deleting them
      if (collections.length > 0) {
        const shouldDeleteCollections = await promptUser(`🗂️  Delete all subcollections for user ${userRecord.uid}? (y/N): `);
        if (shouldDeleteCollections === 'yes') {
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
  } else if (shouldDeleteUser === 'admin') {
    const adminRoleChanged = await manageAdminRole(userRecord.uid);
    return { deleted: false, skipped: true, adminRoleChanged, tierChanged: false, passwordChanged: false }; // Indicate skipped, but admin role was managed
  } else if (shouldDeleteUser === 'tier') {
    const tierChanged = await manageUserTier(userRecord.uid);
    return { deleted: false, skipped: true, adminRoleChanged: false, tierChanged, passwordChanged: false }; // Indicate skipped, but user tier was managed
  } else if (shouldDeleteUser === 'password') {
    const passwordChanged = await changeUserPassword(userRecord.uid);
    return { deleted: false, skipped: true, adminRoleChanged: false, tierChanged: false, passwordChanged }; // Indicate skipped, but password was changed
  } else {
    console.log(`⏭️  Skipped user: ${userRecord.uid}`);
    return { deleted: false, skipped: true, adminRoleChanged: false, tierChanged: false, passwordChanged: false };
  }
}

async function main() {
  console.log('🔍 Firebase User CRUD Script');
  console.log('============================\n');
  
  // Ask if user wants to create a new user or manage existing users
  const action = await promptUserChoice('Select action:\n  1. Manage existing users\n  2. Create new user\nChoice (1-2): ', ['1', '2']);
  
  if (action === '2') {
    // Create new user mode
    const created = await createNewUser();
    if (created) {
      console.log('\n🎉 User creation completed successfully!');
    } else {
      console.log('\n❌ User creation failed or was cancelled.');
    }
    process.exit(0);
  }
  
  // Manage existing users mode
  let totalUsers = 0;
  let deletedUsers = 0;
  let skippedUsers = 0;
  let errorUsers = 0;
  let adminRoleChanges = 0;
  let tierChanges = 0;
  let passwordChanges = 0;
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
          if (result.adminRoleChanged) {
            adminRoleChanges++;
          }
          if (result.tierChanged) {
            tierChanges++;
          }
          if (result.passwordChanged) {
            passwordChanges++;
          }
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
    if (adminRoleChanges > 0) {
      console.log(`👑 Admin role changes: ${adminRoleChanges}`);
    }
    if (tierChanges > 0) {
      console.log(`💎 User tier changes: ${tierChanges}`);
    }
    if (passwordChanges > 0) {
      console.log(`🔐 Password changes: ${passwordChanges}`);
    }
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