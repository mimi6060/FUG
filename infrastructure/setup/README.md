# FUG Infrastructure Setup

> Automated Appwrite Infrastructure as Code (IaC) for the FUG project.

---

## Important: Infrastructure as Code

**All Appwrite modifications MUST go through migrations or bootstrap scripts.**

- NO manual changes in the Appwrite console
- All changes are version-controlled
- Reproducible across dev/staging/production
- Audit trail via git history

---

## Quick Start

### Fresh Installation

```bash
# 1. Start Appwrite
cd infrastructure && docker-compose up -d

# 2. Bootstrap everything (creates project, admin, database, runs migrations)
cd setup && ./bootstrap.sh

# 3. Save the admin password shown at the end!
```

The bootstrap script:
- Creates the FUG project
- Creates admin account with generated secure password
- Creates API key for migrations
- Creates the database
- Runs all migrations

### Existing Installation (Upgrades)

```bash
# Run pending migrations only
cd infrastructure/migrations
node migrate.js up --env=development
```

---

## Bootstrap Script

### Usage

```bash
# Development (default)
./bootstrap.sh

# Staging
./bootstrap.sh --env=staging

# Production
./bootstrap.sh --env=production
```

### What It Does

1. **Checks Appwrite health** - Verifies Appwrite is running
2. **Creates admin account** - Email: `fous.toi.une.guinze@gmail.com`
3. **Generates password** - 24-character secure random password
4. **Creates project** - FUG project in Appwrite
5. **Creates API key** - Full permissions for migrations
6. **Creates database** - fug-db database
7. **Generates .env** - Configuration for migration system
8. **Runs migrations** - All schema migrations
9. **Displays password** - **SAVE THIS - shown only once!**

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APPWRITE_ENDPOINT` | Appwrite API URL | Based on --env |
| `PROJECT_ID` | Project ID | `fug` |
| `PROJECT_NAME` | Display name | `FUG` |
| `DATABASE_ID` | Database ID | `fug-db` |

### Endpoints by Environment

| Environment | Endpoint |
|-------------|----------|
| development | `http://localhost:9000/v1` |
| staging | `https://staging.fug-app.com/v1` |
| production | `https://api.fug-app.com/v1` |

---

## Migration System

All database changes go through migrations.

### Commands

```bash
cd infrastructure/migrations

# Check status
node migrate.js status --env=development

# Apply pending migrations
node migrate.js up --env=development

# Rollback last batch
node migrate.js down --env=development

# Create new migration
node migrate.js create my-migration-name

# Create bootstrap migration (fresh install only)
node migrate.js create my-bootstrap-migration --bootstrap
```

### Migration Types

| Type | Description | When it runs |
|------|-------------|--------------|
| `upgrade` | Standard migration | Always (if not already applied) |
| `bootstrap` | Fresh install only | Only on new installations |

### Creating Migrations

```bash
# Standard upgrade migration
node migrate.js create add-user-preferences

# Bootstrap migration (only runs on fresh installs)
node migrate.js create initial-setup --bootstrap
```

---

## OAuth Providers

### Priority

| Provider | Priority | Cost | Platform | Status |
|----------|----------|------|----------|--------|
| **Google** | HIGH | Free | Android + Web | Configured via migration |
| **Apple** | LOW | $99/year | iOS only | Optional |

### Configuration

OAuth providers are configured via migrations (see `014_oauth_providers.js`).

Set environment variables before running migrations:

```bash
export GOOGLE_CLIENT_ID=your-client-id
export GOOGLE_CLIENT_SECRET=your-client-secret
```

See:
- [GOOGLE_SIGNIN_SETUP.md](./GOOGLE_SIGNIN_SETUP.md) - Google OAuth setup
- [APPLE_SIGNIN_SETUP.md](./APPLE_SIGNIN_SETUP.md) - Apple OAuth setup

---

## Files

```
infrastructure/setup/
├── README.md                    # This file
├── bootstrap.sh                 # Main bootstrap script (IaC)
├── bootstrap-appwrite.sh        # Legacy bootstrap (deprecated)
├── configure-oauth.sh           # OAuth configuration helper
├── GOOGLE_SIGNIN_SETUP.md       # Google OAuth guide
├── APPLE_SIGNIN_SETUP.md        # Apple OAuth guide
└── .google-credentials          # Google credentials (gitignored)

infrastructure/migrations/
├── migrate.js                   # Migration CLI
├── .env                         # Migration config (gitignored)
├── lib/                         # Migration system
└── migrations/                  # Migration files
    ├── 000_bootstrap_verify.js  # Bootstrap verification
    ├── 001_initial_schema.js    # Initial collections
    ├── ...
    └── 014_oauth_providers.js   # OAuth configuration
```

---

## Security

### Files to NEVER commit

These are in `.gitignore`:

```
infrastructure/setup/.google-credentials
infrastructure/setup/.apple-credentials
infrastructure/setup/.env
infrastructure/migrations/.env
*.p8
*.pem
```

### Admin Password

- Generated randomly (24 characters)
- Displayed once at bootstrap completion
- Never stored in files
- Must be saved in a secure password manager

### Production Secrets

For production environments, use:
- Environment variables
- Docker secrets
- HashiCorp Vault
- Cloud secret managers (AWS Secrets Manager, GCP Secret Manager)

---

## Troubleshooting

### "Cannot connect to Appwrite"

```bash
# Check Appwrite is running
docker-compose ps

# Start Appwrite
docker-compose up -d

# Check logs
docker-compose logs appwrite
```

### "Project already exists"

If running bootstrap on an existing installation:
- Run migrations only: `node migrate.js up`
- Or continue bootstrap (will skip existing resources)

### "Admin account already exists"

Enter the existing admin password when prompted.
If forgotten, reset via Appwrite console or recreate the instance.

### Migration errors

```bash
# Check status
node migrate.js status --env=development --verbose

# Test connection
node migrate.js test --env=development
```

---

## Deployment Workflow

### Development

```bash
cd infrastructure
docker-compose up -d
cd setup && ./bootstrap.sh
```

### Staging/Production

```bash
# Set environment variables
export APPWRITE_ENDPOINT=https://api.fug-app.com/v1
export GOOGLE_CLIENT_ID=...
export GOOGLE_CLIENT_SECRET=...

# Bootstrap (first time) or migrate (upgrades)
./bootstrap.sh --env=production
# or
node migrate.js up --env=production
```

---

*Last updated: 2026-01-22*
