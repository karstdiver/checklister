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