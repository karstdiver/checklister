# Firebase Admin Scripts

This directory contains Firebase admin scripts for managing users and data in the Checklister application.

## firebaseUserCRUD.js

A comprehensive script for managing Firebase users with admin role and user tier management capabilities.

### Features

- **User Creation**: Create new users with Firebase Auth and Firestore documents
- **User Management**: View, delete, and manage all Firebase Auth users
- **Data Cleanup**: Delete user documents, collections, and storage files
- **Admin Role Management**: Assign and modify admin roles for users
- **User Tier Management**: Change user tiers and TTL periods
- **Comprehensive Reporting**: Detailed summary of all operations

### Prerequisites

1. **Node.js**: Must be installed and accessible
2. **Firebase Admin SDK**: Install with `npm install firebase-admin`
3. **Service Account Key**: Place `serviceAccountKey.json` in this directory

### Setup

1. Get your Firebase service account key:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings > Service Accounts
   - Click "Generate new private key"
   - Save as `serviceAccountKey.json` in this directory

2. Install dependencies:
   ```bash
   npm install firebase-admin
   ```

### Usage

Run the script:
```bash
node firebaseUserCRUD.js
```

The script will first ask you to choose an action:
1. **Manage existing users** - View, delete, or modify existing users
2. **Create new user** - Create a new user with Firebase Auth and Firestore document

### User Creation

When creating a new user, you can specify:
- **Email address** (required)
- **Display name** (optional)
- **Password** (minimum 6 characters)
- **User tier** (anonymous, free, premium, pro)
- **Admin role** (none, moderator, admin, superAdmin)

The script will create:
1. **Firebase Auth user** with email/password authentication
2. **Firestore user document** with all default values and settings
3. **Complete user profile** with preferences, stats, and usage tracking

### Interactive Options

For each user, you'll be prompted with:

```
🗑️  Delete user [USER_ID]? (y/N/a for admin/t for tier):
```

- **y** or **yes**: Delete the user and all associated data
- **N** or **no** (or any other input): Skip the user
- **a** or **admin**: Manage admin role for the user
- **t** or **tier**: Manage user tier for the user
- **p** or **password**: Change user password

### Admin Role Management

When you select 'a' for admin management, you can:

1. **View current admin role** and assignment details
2. **Select new admin role** from available options:
   - `none` - No admin privileges
   - `moderator` - View analytics, basic admin panel access
   - `admin` - Full system management, TTL management
   - `superAdmin` - Complete system control, user management
3. **Add notes** for the role change
4. **Confirm the change** before applying

### User Tier Management

When you select 't' for tier management, you can:

1. **View current user tier** and TTL information
2. **Select new user tier** from available options:
   - `anonymous` - 7 days TTL, basic features
   - `free` - 30 days TTL, standard features
   - `premium` - 365 days TTL, enhanced features
   - `pro` - Unlimited TTL, all features
3. **Add notes** for the tier change
4. **Confirm the change** before applying

### Password Management

When you select 'p' for password management, you can:

1. **View current user email** for confirmation
2. **Enter new password** (minimum 6 characters)
3. **Confirm new password** to prevent typos
4. **Add notes** for the password change (optional)
5. **Confirm the change** before applying

**Security Features:**
- Password must be at least 6 characters
- Password confirmation prevents typos
- Password change is logged in Firestore with timestamp and notes
- Only works for users with email/password authentication

### Admin Role Hierarchy

- **none**: Regular user with no admin privileges
- **moderator**: Can view analytics and access basic admin panel
- **admin**: Can manage system settings, TTL, and perform cleanup operations
- **superAdmin**: Complete control including user management and role assignment

### User Tier Hierarchy

- **anonymous**: 7 days TTL, basic features only
- **free**: 30 days TTL, standard features
- **premium**: 365 days TTL, enhanced features
- **pro**: Unlimited TTL, all features available

### Data Cleanup

When deleting a user, the script will:

1. **Delete subcollections** (if any exist)
2. **Delete storage files** (profile images, item photos)
3. **Delete user document** from 'users' collection
4. **Delete top-level documents** in user-linked collections
5. **Delete user** from Firebase Auth

### Safety Features

- **Confirmation prompts** for all destructive operations
- **Detailed user information** display before any action
- **Comprehensive error handling** with informative messages
- **Audit trail** for admin role and user tier changes (who, when, why)

### Output Summary

The script provides a detailed summary including:
- Total users processed
- Users deleted
- Users skipped
- Admin role changes made
- User tier changes made
- Password changes made
- Storage files deleted
- Any errors encountered

### Default User Values

When creating a new user, the script sets these default values:

**User Profile:**
- `isActive`: true
- `emailVerified`: false (requires email verification)
- `providerId`: 'email'

**Preferences:**
- `themeMode`: 'system'
- `language`: 'en_US'
- `notifications.email`: true
- `notifications.push`: true

**Stats:**
- `totalChecklists`: 0
- `completedChecklists`: 0
- `totalItems`: 0
- `completedItems`: 0

**Usage:**
- `checklistsCreated`: 0
- `sessionsCompleted`: 0

**Subscription:**
- `status`: 'active'
- `autoRenew`: false

### Example Output

```
🔍 Firebase User CRUD Script
============================

============================================================
👤 User ID: abc123
📧 Email: user@example.com
👑 Admin Role: NONE
💎 User Tier: ANONYMOUS
⏰ TTL Period: 7 days
============================================================
🗑️  Delete user abc123? (y/N/a for admin/t for tier): t

💎 User Tier Management for user: abc123
==================================================
📋 Current user tier: ANONYMOUS
⏰ Current TTL: 7 days

🔄 Available user tiers:
  1. anonymous - 7 days TTL, basic features
  2. free - 30 days TTL, standard features
  3. premium - 365 days TTL, enhanced features
  4. pro - Unlimited TTL, all features
  5. cancel - Cancel tier change

Select new user tier (1-5): 4
Enter notes for this tier change (optional): Upgraded to Pro for unlimited TTL
🗳️  Change user tier from ANONYMOUS to PRO? (y/N): y
✅ Successfully changed user tier to: PRO
⏰ New TTL Period: Unlimited (no expiration)

============================================================
📊 SUMMARY
============================================================
👥 Total users processed: 1
✅ Users deleted: 0
⏭️  Users skipped: 1
💎 User tier changes: 1
🎉 Script completed!
```

### Security Notes

- This script requires Firebase Admin SDK credentials
- Admin role changes are logged with timestamps and notes
- Only use this script in secure environments
- Review all changes before confirming
- Consider backing up data before bulk operations 