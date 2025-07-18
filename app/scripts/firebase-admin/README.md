# Firebase Admin Scripts

This directory contains Firebase Admin SDK scripts for managing the Checklister Firebase database.

## Prerequisites

- Node.js (v14 or higher)
- npm
- Firebase project access

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. (Optional) Add Firebase service account key:
   - Download your Firebase service account key from Firebase Console
   - Save it as `serviceAccountKey.json` in this directory
   - This file is already in `.gitignore` for security

## Scripts

### User CRUD Script

Manages Firebase users with comprehensive cleanup including Firestore documents and Firebase Storage files.

#### Usage

```bash
# Run the user management script
node firebaseUserCRUD.js
```

#### What it deletes

When deleting a user, the script removes:

1. **Firebase Auth user account**
2. **User document** from `users` collection
3. **User subcollections** (if confirmed)
4. **Top-level documents** in `sessions` and `checklists` collections
5. **Profile images** from Firebase Storage (`profile_images/` folder)
6. **Item photos** from Firebase Storage (`item_photos/` folder)

#### Safety features

- **Interactive confirmation**: Asks for confirmation before each deletion step
- **Granular control**: Separate confirmations for collections, profile images, and item photos
- **Comprehensive cleanup**: Ensures no orphaned files remain in storage
- **Error handling**: Graceful error handling and reporting
- **Detailed logging**: Shows exactly what's being deleted

#### Storage cleanup process

1. **Profile images**: Finds all files matching `profile_images/profile_{userId}_*`
2. **Item photos**: 
   - Finds all checklists belonging to the user
   - Extracts all item IDs from those checklists
   - Finds all files matching `item_photos/item_{itemId}_*`
3. **Confirmation**: Asks user to confirm deletion of each type
4. **Bulk deletion**: Deletes all files in parallel for efficiency

#### Example output

```
👤 User ID: abc123
📧 Email: user@example.com
📋 Subcollections: None found
📋 Top-level collections to be checked for userId: sessions, checklists
🗑️  Delete user abc123? (y/N): y

🗂️  Checking Firebase Storage for user: abc123
📸 Found 2 profile image(s) for user: abc123
🗑️  Delete 2 profile image(s) for user abc123? (y/N): y
✅ Deleted 2 profile image(s) for user: abc123

📋 Found 5 checklist item(s) for user: abc123
📸 Found 3 item photo(s) for user: abc123
🗑️  Delete 3 item photo(s) for user abc123? (y/N): y
✅ Deleted 3 item photo(s) for user: abc123

📊 Storage cleanup summary for user abc123:
   - Profile images: 2
   - Item photos: 3
   - Total files deleted: 5

✅ Deleted user: abc123
```

### Session Cleanup Script

Deletes unused sessions from the Firebase database to reduce storage costs and improve performance.

#### Usage

```bash
# Preview what would be deleted (recommended first step)
./cleanup-sessions.sh --dry-run

# Delete sessions older than 7 days (default) - REQUIRES --force
./cleanup-sessions.sh --force

# Delete sessions older than 30 days
./cleanup-sessions.sh --force --days 30

# Preview sessions older than 1 day
./cleanup-sessions.sh --dry-run --days 1

# Show help
./cleanup-sessions.sh --help
```

**⚠️ Important:** The script has a double confirmation system. You must use `--force` to actually delete sessions.

#### What it deletes

The script identifies and deletes:

1. **Old sessions**: Sessions older than the specified number of days
2. **Abandoned sessions**: Sessions with status "abandoned"
3. **Unused sessions**: Sessions with no items or all items completed/skipped

#### Safety features

- **Dry-run mode**: Preview changes without actually deleting
- **Double confirmation system**: Shell script + Node.js script confirmations
- **Force mode**: Skip both confirmations (use with caution)
- **Batch processing**: Deletes in batches to avoid timeouts
- **Error handling**: Graceful error handling and reporting
- **Consistent categorization**: Single query prevents counting discrepancies

#### Examples

```bash
# Safe preview of what would be deleted
./cleanup-sessions.sh --dry-run

# Delete old sessions with confirmation (requires --force)
./cleanup-sessions.sh --force --days 14

# Force delete very old sessions (no confirmation)
./cleanup-sessions.sh --force --days 90
```

#### Recommended Workflow

```bash
# 1. Always preview first to see what will be deleted
./cleanup-sessions.sh --dry-run

# 2. If the preview looks good, run with force to actually delete
./cleanup-sessions.sh --force

# 3. For different time periods, specify days
./cleanup-sessions.sh --dry-run --days 30
./cleanup-sessions.sh --force --days 30
```

### Direct Node.js Usage

You can also run the Node.js script directly:

```bash
# Preview changes
node deleteUnusedSessions.js --dry-run --days=7

# Delete with confirmation (will stop and ask for --force)
node deleteUnusedSessions.js --days=7

# Force delete (bypasses confirmation)
node deleteUnusedSessions.js --force --days=30
```

**Note:** The Node.js script will stop and ask for `--force` flag if not provided.

## Configuration

### Environment Variables

The script will use:
1. Service account key file if available (`serviceAccountKey.json`)
2. Default credentials (for local development with `gcloud auth`)

### Batch Size

The script processes deletions in batches of 500 (Firestore limit). This can be modified in the script if needed.

## Monitoring

After running the cleanup script, you can monitor the results:

1. Check Firebase Console for reduced session count
2. Monitor storage usage in Firebase Console
3. Check app performance improvements

## Troubleshooting

### Common Issues

1. **Authentication Error**: Ensure you have proper Firebase access
2. **Permission Denied**: Check Firebase security rules
3. **Script Not Found**: Ensure you're in the correct directory
4. **Script stops after preview**: Use `--force` flag to actually delete sessions
5. **Double confirmation confusion**: The script has two confirmation layers - use `--force` to skip both

### Debug Mode

Add debug logging by modifying the script or using Node.js debug flags:

```bash
DEBUG=* node deleteUnusedSessions.js --dry-run
```

## Security Notes

- Never commit `serviceAccountKey.json` to version control
- Use least-privilege service accounts
- Regularly rotate service account keys
- Monitor script usage and access logs

## Contributing

When adding new scripts:

1. Follow the existing pattern
2. Include proper error handling
3. Add dry-run capabilities where appropriate
4. Update this README
5. Add appropriate tests 