# Firestore Management Guide

This guide explains how to develop, test, and deploy Firestore security rules and indexes in the Checklister project.

## 📁 File Structure

```
app/
├── firestore.rules              # Security rules
├── firestore.indexes.json       # Database indexes
├── firebase.json               # Firebase configuration
├── .firebaserc                 # Project configuration
└── scripts/
    └── deploy-firestore.sh     # Deployment script
```

## 🔐 Security Rules

### Current Rules Analysis

**File:** `app/firestore.rules`

#### ✅ What's Currently Allowed:
- **Pricing Tiers**: Any authenticated user can read/write
- **Users**: Users can read/write their own documents
- **Everything else**: Denied by default

#### 🚨 Security Issues:
1. **Too permissive** for pricing tiers (should be admin-only)
2. **Missing rules** for other collections (checklists, sessions, etc.)
3. **No admin role validation** in Firestore rules

### Recommended Enhanced Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check admin role
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.adminRole in ['admin', 'superAdmin'];
    }
    
    // Pricing tiers - admin only for write, read for authenticated users
    match /pricingTiers/{document} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
    
    // Users - own documents + admin access
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == userId || isAdmin());
    }
    
    // Checklists - user's own data
    match /checklists/{checklistId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Sessions - user's own data
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Achievements - user's own data
    match /achievements/{achievementId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 📊 Database Indexes

### Current Indexes

**File:** `app/firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "pricingTiers",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "active",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastUpdated",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Recommended Additional Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "pricingTiers",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "active",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "lastUpdated",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "checklists",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "sessions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startedAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## 🛠️ Development Workflow

### 1. Local Development

#### Install Firebase CLI
```bash
npm install -g firebase-tools
```

#### Login to Firebase
```bash
firebase login
```

#### Start Local Emulator
```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# Start with data import/export
firebase emulators:start --only firestore --import=./firestore-data --export-on-exit=./firestore-data
```

### 2. Rule Development

#### Edit Rules
```bash
# Edit security rules
code app/firestore.rules

# Edit indexes
code app/firestore.indexes.json
```

#### Test Rules Locally
```bash
# Start emulator
firebase emulators:start --only firestore

# Test with your app (connect to localhost:8080)
# Or use Firebase CLI to test specific operations
```

### 3. Validation

#### Validate Rules Syntax
```bash
firebase deploy --only firestore:rules --dry-run
```

#### Test Rules with Emulator
```bash
# Start emulator
firebase emulators:start --only firestore

# In another terminal, test operations
firebase firestore:rules:test
```

## 🚀 Deployment

### Using the Deployment Script

**Script:** `app/scripts/deploy-firestore.sh`

#### Deploy All Firestore Configurations
```bash
# Deploy to development
./scripts/deploy-firestore.sh all dev

# Deploy to production (when ready)
./scripts/deploy-firestore.sh all prod
```

#### Deploy Specific Components
```bash
# Deploy only rules
./scripts/deploy-firestore.sh rules dev

# Deploy only indexes
./scripts/deploy-firestore.sh indexes dev
```

### Manual Deployment

#### Deploy Rules Only
```bash
firebase deploy --only firestore:rules --project checklister-firebase-dev
```

#### Deploy Indexes Only
```bash
firebase deploy --only firestore:indexes --project checklister-firebase-dev
```

#### Deploy All Firestore
```bash
firebase deploy --only firestore --project checklister-firebase-dev
```

## 🔍 Testing Rules

### 1. Local Testing

#### Start Emulator with Test Data
```bash
# Create test data directory
mkdir -p firestore-data

# Start emulator with test data
firebase emulators:start --only firestore --import=./firestore-data --export-on-exit=./firestore-data
```

#### Test Specific Operations
```bash
# Test read operation
firebase firestore:rules:test --project checklister-firebase-dev

# Test write operation
firebase firestore:rules:test --project checklister-firebase-dev --write
```

### 2. Production Testing

#### Test Rules in Production
```bash
# Deploy rules
firebase deploy --only firestore:rules --project checklister-firebase-dev

# Test with real data (be careful!)
# Use Firebase Console to monitor requests
```

## 📋 Best Practices

### 1. Security Rules
- **Principle of Least Privilege**: Only grant necessary permissions
- **Validate Data**: Check data structure and content
- **Use Functions**: Create reusable helper functions
- **Test Thoroughly**: Test all read/write operations

### 2. Indexes
- **Monitor Usage**: Check Firebase Console for index usage
- **Optimize Queries**: Create indexes for frequently used queries
- **Avoid Over-indexing**: Too many indexes slow down writes

### 3. Deployment
- **Test Locally**: Always test in emulator first
- **Deploy Incrementally**: Deploy rules before indexes
- **Monitor Logs**: Check Firebase Console for errors
- **Rollback Plan**: Keep previous rules as backup

## 🚨 Common Issues

### 1. Permission Denied Errors
```bash
# Check if user is authenticated
# Verify user has correct role
# Check if rules are properly deployed
```

### 2. Index Errors
```bash
# Check if required indexes exist
# Verify index fields match query
# Wait for indexes to build (can take time)
```

### 3. Deployment Failures
```bash
# Check Firebase CLI version
# Verify project configuration
# Check authentication status
```

## 📚 Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Firestore Emulator Documentation](https://firebase.google.com/docs/emulator-suite/install_and_configure)

## 🔄 Version Control

### Git Workflow
```bash
# Edit rules/indexes
git add app/firestore.rules app/firestore.indexes.json
git commit -m "feat: update Firestore rules for enhanced security"

# Deploy changes
./scripts/deploy-firestore.sh all dev

# Test in development
# If successful, deploy to production
./scripts/deploy-firestore.sh all prod
```

### Backup Strategy
- Keep previous rules in Git history
- Document rule changes in commit messages
- Test rules before deploying to production
- Monitor Firebase Console for issues after deployment 