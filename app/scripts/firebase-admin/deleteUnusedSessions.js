#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
const BATCH_SIZE = 500; // Firestore batch limit
const DRY_RUN = process.argv.includes('--dry-run');
const FORCE = process.argv.includes('--force');
const DAYS_OLD = parseInt(process.argv.find(arg => arg.startsWith('--days='))?.split('=')[1] || '7');

// Initialize Firebase Admin SDK
function initializeFirebase() {
  try {
    // Try to load service account key
    const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://checklister-ai.firebaseio.com'
      });
    } else {
      // Use default credentials (for local development)
      admin.initializeApp({
        projectId: 'checklister-ai'
      });
    }
    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
  }
}

// Get total number of sessions
async function getTotalSessions() {
  const db = admin.firestore();
  
  try {
    const sessionsRef = db.collection('sessions');
    const snapshot = await sessionsRef.get();
    return snapshot.size;
  } catch (error) {
    console.error('❌ Error fetching total sessions:', error.message);
    throw error;
  }
}

// Get all sessions in one query
async function getAllSessions() {
  const db = admin.firestore();
  
  try {
    const sessionsRef = db.collection('sessions');
    const snapshot = await sessionsRef.get();
    
    const sessions = [];
    snapshot.forEach(doc => {
      sessions.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    return sessions;
  } catch (error) {
    console.error('❌ Error fetching all sessions:', error.message);
    throw error;
  }
}

// Categorize all sessions in one pass to avoid discrepancies
function categorizeSessions(sessions, daysOld) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysOld);
  
  const oldSessions = [];
  const abandonedSessions = [];
  const unusedSessions = [];
  const keptSessions = [];
  
  console.log(`🔍 Categorizing ${sessions.length} sessions...`);
  
  sessions.forEach(session => {
    const sessionDate = session.createdAt?.toDate ? session.createdAt.toDate() : new Date(session.createdAt);
    const isOld = sessionDate < cutoffDate;
    const isAbandoned = session.status === 'abandoned';
    
    // Check if session has no items or all items completed
    const hasNoItems = !session.items || session.items.length === 0;
    const allCompleted = !hasNoItems && session.items.every(item => 
      item.status === 'completed' || item.status === 'skipped'
    );
    const isUnused = hasNoItems || allCompleted;
    
    // Categorize session
    if (isAbandoned) {
      abandonedSessions.push({
        ...session,
        reason: 'abandoned'
      });
    } else if (isOld) {
      oldSessions.push({
        ...session,
        reason: 'old'
      });
    } else if (isUnused) {
      unusedSessions.push({
        ...session,
        reason: hasNoItems ? 'no_items' : 'all_completed'
      });
    } else {
      // Track why sessions are being kept
      const pendingItems = session.items ? session.items.filter(item => 
        item.status !== 'completed' && item.status !== 'skipped'
      ).length : 0;
      
      keptSessions.push({
        id: session.id,
        status: session.status || 'unknown',
        totalItems: session.items?.length || 0,
        pendingItems: pendingItems,
        reason: 'has_pending_items'
      });
    }
  });
  
  // Show diagnostic info
  console.log(`📊 Old sessions (${daysOld}+ days): ${oldSessions.length}`);
  console.log(`📊 Abandoned sessions: ${abandonedSessions.length}`);
  console.log(`📊 Unused sessions: ${unusedSessions.length}`);
  console.log(`📊 Sessions being kept: ${keptSessions.length}`);
  
  if (keptSessions.length > 0) {
    const statusCounts = {};
    keptSessions.forEach(session => {
      statusCounts[session.status] = (statusCounts[session.status] || 0) + 1;
    });
    console.log('📋 Kept sessions by status:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`  - ${status}: ${count}`);
    });
  }
  
  return {
    oldSessions,
    abandonedSessions,
    unusedSessions,
    keptSessions
  };
}

// Legacy functions removed - now using categorizeSessions() for consistent results

// Delete sessions in batches
async function deleteSessions(sessions, reason) {
  if (sessions.length === 0) {
    console.log(`✅ No sessions to delete for reason: ${reason}`);
    return;
  }
  
  const db = admin.firestore();
  const batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;
  
  console.log(`🗑️  Preparing to delete ${sessions.length} sessions (reason: ${reason})`);
  
  if (DRY_RUN) {
    console.log('🔍 DRY RUN MODE - No actual deletion will occur');
    sessions.forEach(session => {
      console.log(`  Would delete: ${session.id} (${session.reason || reason})`);
    });
    return;
  }
  
  for (const session of sessions) {
    const sessionRef = db.collection('sessions').doc(session.id);
    currentBatch.delete(sessionRef);
    operationCount++;
    
    if (operationCount === BATCH_SIZE) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      operationCount = 0;
    }
  }
  
  if (operationCount > 0) {
    batches.push(currentBatch);
  }
  
  console.log(`📦 Executing ${batches.length} batch(es) of deletions...`);
  
  try {
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`✅ Batch ${i + 1}/${batches.length} completed`);
    }
    console.log(`🎉 Successfully deleted ${sessions.length} sessions`);
  } catch (error) {
    console.error('❌ Error deleting sessions:', error.message);
    throw error;
  }
}

// Main execution function
async function main() {
  console.log('🚀 Firebase Session Cleanup Script');
  console.log('====================================');
  
  if (DRY_RUN) {
    console.log('🔍 Running in DRY RUN mode');
  }
  
  if (FORCE) {
    console.log('⚠️  FORCE mode enabled - will delete without confirmation');
  }
  
  console.log(`📅 Sessions older than ${DAYS_OLD} days will be considered`);
  console.log('');
  
  initializeFirebase();
  
  try {
    // Get total sessions count first
    const totalSessionsBefore = await getTotalSessions();
    console.log(`📊 Total sessions in database: ${totalSessionsBefore.toLocaleString()}`);
    console.log('');
    
    // Get all sessions in one query to avoid discrepancies
    const allSessions = await getAllSessions();
    console.log(`📊 Retrieved ${allSessions.length} sessions for analysis`);
    
    // Categorize sessions
    const categorizedSessions = categorizeSessions(allSessions, DAYS_OLD);
    
    const { oldSessions, abandonedSessions, unusedSessions, keptSessions } = categorizedSessions;
    const totalToDelete = oldSessions.length + abandonedSessions.length + unusedSessions.length;
    const totalSessionsAfter = totalSessionsBefore - totalToDelete;
    
    if (totalToDelete === 0) {
      console.log('✅ No sessions found for deletion');
      return;
    }
    
    console.log('');
    console.log('📋 Summary:');
    console.log(`  - Old sessions (${DAYS_OLD}+ days): ${oldSessions.length}`);
    console.log(`  - Abandoned sessions: ${abandonedSessions.length}`);
    console.log(`  - Unused sessions: ${unusedSessions.length}`);
    console.log(`  - Total to delete: ${totalToDelete}`);
    console.log('');
    console.log('📈 Impact:');
    console.log(`  - Sessions before: ${totalSessionsBefore.toLocaleString()}`);
    console.log(`  - Sessions after: ${totalSessionsAfter.toLocaleString()}`);
    console.log(`  - Reduction: ${((totalToDelete / totalSessionsBefore) * 100).toFixed(1)}%`);
    console.log('');
    
    if (!FORCE && !DRY_RUN) {
      console.log('⚠️  This will permanently delete sessions from the database.');
      console.log('   Use --force to skip confirmation or --dry-run to preview changes.');
      console.log('   Or run the shell script with --force flag.');
      return;
    }
    
    // Delete sessions by category
    await deleteSessions(oldSessions, 'old');
    await deleteSessions(abandonedSessions, 'abandoned');
    await deleteSessions(unusedSessions, 'unused');
    
    // Verify final count
    const finalCount = await getTotalSessions();
    console.log('');
    console.log('📊 Final Results:');
    console.log(`  - Sessions before cleanup: ${totalSessionsBefore.toLocaleString()}`);
    console.log(`  - Sessions after cleanup: ${finalCount.toLocaleString()}`);
    console.log(`  - Total deleted: ${(totalSessionsBefore - finalCount).toLocaleString()}`);
    console.log(`  - Reduction achieved: ${(((totalSessionsBefore - finalCount) / totalSessionsBefore) * 100).toFixed(1)}%`);
    console.log('');
    console.log('🎉 Session cleanup completed successfully!');
    
  } catch (error) {
    console.error('❌ Script failed:', error.message);
    process.exit(1);
  }
}

// Handle command line arguments
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
Firebase Session Cleanup Script

Usage: node deleteUnusedSessions.js [options]

Options:
  --dry-run          Preview changes without actually deleting
  --force            Skip confirmation and delete immediately
  --days=N           Consider sessions older than N days (default: 7)
  --help, -h         Show this help message

Examples:
  node deleteUnusedSessions.js --dry-run
  node deleteUnusedSessions.js --force --days=30
  node deleteUnusedSessions.js --dry-run --days=1
`);
  process.exit(0);
}

// Run the script
main().catch(console.error); 