# INFRA-001: Appwrite Infrastructure as Code

> **Priority:** P0 - CRITICAL (Blocking)
> **Epic:** Infrastructure Automation
> **Effort:** Medium (2-3 days)
> **Dependencies:** None (foundational)
> **Status:** Done

---

## Context

Currently, Appwrite setup requires manual configuration:
- Project creation in console
- Database creation
- Admin user setup
- OAuth provider configuration

This prevents:
1. **Reproducible deployments** on new servers
2. **Version upgrades** on staging/prod without DB clones
3. **Automated CI/CD** pipelines
4. **Disaster recovery** scenarios

## Goal

**100% automated Appwrite setup via migrations/scripts.**

Starting from a fresh Appwrite installation:
```bash
./bootstrap.sh
# → Creates project, admin user, database, collections, OAuth
# → Displays generated admin password (not stored)
# → Ready to use
```

---

## Requirements

### R1: Bootstrap Script (Fresh Installation)
- [ ] Detect if Appwrite is fresh (no project exists)
- [ ] Create project via API
- [ ] Create admin user with email: `fous.toi.une.guinze@gmail.com`
- [ ] Generate random secure password (display once, never store)
- [ ] Create API key for migrations
- [ ] Generate `.env` file with credentials
- [ ] Run all migrations

### R2: Migration System Enhancement
- [ ] Support "bootstrap" migrations (run only on fresh install)
- [ ] Support "upgrade" migrations (run on existing installs)
- [ ] Idempotent migrations (can run multiple times safely)
- [ ] Track migration state in Appwrite (not local file)

### R3: Migrations to Create/Update

| Migration | Type | Description |
|-----------|------|-------------|
| 000_bootstrap_project | Bootstrap | Create project if not exists |
| 001_create_admin | Bootstrap | Create admin user |
| 002_create_database | Bootstrap | Create fug-db database |
| 003-013 | Upgrade | Existing schema migrations |
| 014_oauth_providers | Upgrade | Configure Google/Apple OAuth |

### R4: Environment Handling
- [ ] Development: localhost:9000
- [ ] Staging: staging.fug-app.com
- [ ] Production: api.fug-app.com
- [ ] Credentials via environment variables (never in files)

### R5: Secrets Management
- [ ] Admin password: generated, displayed once
- [ ] API keys: generated, stored in `.env` (gitignored)
- [ ] OAuth secrets: from environment variables
- [ ] No secrets in git history

---

## Technical Design

### Bootstrap Flow

```
┌─────────────────────────────────────────────────────────┐
│                    bootstrap.sh                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Check Appwrite is running                           │
│     └─► curl health endpoint                            │
│                                                         │
│  2. Check if project exists                             │
│     └─► If exists: skip to migrations                   │
│     └─► If not: create project                          │
│                                                         │
│  3. Create admin account                                │
│     └─► Email: fous.toi.une.guinze@gmail.com            │
│     └─► Password: random 24 chars                       │
│     └─► Display password to user                        │
│                                                         │
│  4. Create API key                                      │
│     └─► Full permissions for migrations                 │
│     └─► Save to .env (gitignored)                       │
│                                                         │
│  5. Run migrations                                      │
│     └─► node migrate.js up                              │
│                                                         │
│  6. Configure OAuth (if credentials provided)           │
│     └─► Read from environment variables                 │
│                                                         │
│  7. Display summary                                     │
│     └─► Admin email                                     │
│     └─► Admin password (SAVE THIS!)                     │
│     └─► Project ID                                      │
│     └─► API endpoint                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Migration Types

```javascript
// Bootstrap migration (only runs on fresh install)
export default {
  type: 'bootstrap', // or 'upgrade'
  name: '000_bootstrap_project',

  async shouldRun(context) {
    // Check if project exists
    return !await context.projectExists();
  },

  async up(context) {
    // Create project
  }
}
```

### Password Generation

```javascript
const crypto = require('crypto');

function generateSecurePassword() {
  const length = 24;
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  const randomBytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i++) {
    password += charset[randomBytes[i] % charset.length];
  }
  return password;
}
```

---

## Stories Breakdown

### INFRA-001-A: Bootstrap Script
**Effort:** 1 day

Create `infrastructure/setup/bootstrap.sh`:
- Fresh Appwrite detection
- Project creation via console API
- Admin user creation
- Password generation and display
- API key creation
- .env generation

### INFRA-001-B: Migration System Enhancement
**Effort:** 0.5 day

Update `infrastructure/migrations/migrate.js`:
- Add bootstrap migration support
- Improve idempotency
- Better error handling

### INFRA-001-C: Bootstrap Migrations
**Effort:** 0.5 day

Create migrations:
- 000_bootstrap_project.js
- 001_bootstrap_admin.js (rename existing to start at 002)

### INFRA-001-D: Documentation
**Effort:** 0.5 day

Update documentation:
- README.md with setup instructions
- DEPLOYMENT.md for production setup
- Secrets management guide

### INFRA-001-E: Update CLAUDE.md
**Effort:** 0.25 day

Add mandatory rule to CLAUDE.md:
- All Appwrite modifications MUST be via migrations
- No manual changes in Appwrite console
- Explain migration workflow for new features

---

## Acceptance Criteria

1. [ ] `./bootstrap.sh` works on fresh Appwrite
2. [ ] Admin password is generated and displayed (never stored)
3. [ ] All migrations run successfully
4. [ ] OAuth configured if credentials provided
5. [ ] Same script works on dev/staging/prod
6. [ ] Migrations are idempotent (safe to run multiple times)
7. [ ] No secrets in git history
8. [ ] Documentation complete

---

## Usage Examples

### Fresh Installation
```bash
# Start Appwrite
cd infrastructure && docker-compose up -d

# Bootstrap everything
cd setup && ./bootstrap.sh

# Output:
# ══════════════════════════════════════════════════
#   FUG - Appwrite Bootstrap Complete!
# ══════════════════════════════════════════════════
#
#   Admin Email:    fous.toi.une.guinze@gmail.com
#   Admin Password: xK9#mP2$vL5@nQ8wR3&jT6yU  ← SAVE THIS!
#   Project ID:     fug-1706012345
#   Endpoint:       http://localhost:9000/v1
#
#   ⚠️  The password above will NOT be shown again!
#   ⚠️  Save it in a secure password manager!
#
# ══════════════════════════════════════════════════
```

### Upgrade Existing Installation
```bash
# Just run migrations (project already exists)
cd infrastructure/migrations
node migrate.js up

# Only new migrations are applied
# Existing data is preserved
```

### Production Deployment
```bash
# Set environment variables (from secrets manager)
export APPWRITE_ENDPOINT=https://api.fug-app.com/v1
export GOOGLE_CLIENT_ID=xxx
export GOOGLE_CLIENT_SECRET=xxx

# Run bootstrap
./bootstrap.sh --env=production
```

---

## Security Considerations

1. **Password never stored** - Generated, displayed once, user must save
2. **API keys in .env** - gitignored, generated per environment
3. **OAuth secrets from env** - Never in files
4. **Audit trail** - All changes via migrations are traceable
5. **No manual changes** - Console only for viewing, not editing

---

## Notes

- Appwrite console API requires special authentication flow
- Some operations need admin session, others need API key
- Consider using Appwrite CLI for some operations
- Test thoroughly before running on production

---

*Created: 2026-01-21*
*Author: BMAD System*
