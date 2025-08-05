# Firestore Quick Reference

## 🚀 Quick Commands

### Deploy Rules & Indexes
```bash
# Deploy all to development
./scripts/deploy-firestore.sh all dev

# Deploy only rules
./scripts/deploy-firestore.sh rules dev

# Deploy only indexes
./scripts/deploy-firestore.sh indexes dev
```

### Local Development
```bash
# Start emulator
firebase emulators:start --only firestore

# Start with test data
firebase emulators:start --only firestore --import=./firestore-data --export-on-exit=./firestore-data
```

### Manual Deployment
```bash
# Deploy rules
firebase deploy --only firestore:rules --project checklister-firebase-dev

# Deploy indexes
firebase deploy --only firestore:indexes --project checklister-firebase-dev

# Deploy all
firebase deploy --only firestore --project checklister-firebase-dev
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `app/firestore.rules` | Security rules |
| `app/firestore.indexes.json` | Database indexes |
| `app/firebase.json` | Firebase configuration |
| `app/.firebaserc` | Project settings |
| `app/scripts/deploy-firestore.sh` | Deployment script |

## 🔐 Current Rules Summary

### ✅ Allowed Operations
- **Pricing Tiers**: Read/write for authenticated users
- **Users**: Read/write own documents
- **Everything else**: Denied

### 🚨 Security Issues
- Pricing tiers too permissive (should be admin-only)
- Missing rules for other collections
- No admin role validation in rules

## 📊 Current Indexes

- `pricingTiers`: `active` ASC, `lastUpdated` DESC

## 🛠️ Development Workflow

1. **Edit** rules/indexes in development tree
2. **Test** locally with emulator
3. **Deploy** using script or CLI
4. **Monitor** Firebase Console for issues

## 🔍 Troubleshooting

### Permission Denied
```bash
# Check authentication
firebase auth:list

# Check user roles in Firestore
# Verify rules are deployed
```

### Index Errors
```bash
# Check index status
firebase firestore:indexes --project checklister-firebase-dev

# Wait for indexes to build (can take time)
```

### Deployment Failures
```bash
# Check Firebase CLI
firebase --version

# Check login status
firebase projects:list

# Check project configuration
cat app/.firebaserc
```

## 📚 Resources

- [Firestore Rules Docs](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexes Docs](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI Docs](https://firebase.google.com/docs/cli)
- [Emulator Docs](https://firebase.google.com/docs/emulator-suite/install_and_configure) 