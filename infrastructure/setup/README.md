# FUG Infrastructure Setup

> Scripts for automated Appwrite configuration and deployment.

---

## Quick Start

### 1. Fresh Server Installation

```bash
# Bootstrap Appwrite (creates project, database, runs migrations)
./bootstrap-appwrite.sh
```

### 2. Configure OAuth Providers

```bash
# After setting up credentials files
./configure-oauth.sh
```

---

## OAuth Providers Priority

| Provider | Priority | Cost | Platform | Status |
|----------|----------|------|----------|--------|
| **Google** | HIGH | Free | Android + Web | Ready to configure |
| **Apple** | LOW | $99/year | iOS only | Optional - decide later |

### Recommendation

Start with **Google Sign-In only** for MVP:
- Free Google Cloud account
- Works on Android and Web
- Most users have Google accounts

Apple Sign-In can be added later if iOS release is decided.

---

## Files

```
infrastructure/setup/
├── README.md                    # This file
├── bootstrap-appwrite.sh        # Initial Appwrite setup (automated)
├── configure-oauth.sh           # OAuth provider configuration (automated)
├── GOOGLE_SIGNIN_SETUP.md       # Google OAuth setup guide
├── APPLE_SIGNIN_SETUP.md        # Apple OAuth setup guide (optional)
├── .google-credentials          # Google credentials (DO NOT COMMIT)
├── .apple-credentials           # Apple credentials (DO NOT COMMIT)
└── .env                         # Local environment (DO NOT COMMIT)
```

---

## Google Sign-In Setup

### 1. Google Cloud Console (Manual)

See [GOOGLE_SIGNIN_SETUP.md](./GOOGLE_SIGNIN_SETUP.md)

Summary:
1. Create Google Cloud project
2. Configure OAuth consent screen
3. Create OAuth 2.0 credentials
4. Copy Client ID and Secret

### 2. Create Credentials File

```bash
cat > .google-credentials << 'EOF'
GOOGLE_CLIENT_ID=123456789-xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxx
EOF
```

### 3. Run Configuration

```bash
./configure-oauth.sh
```

---

## Apple Sign-In Setup (Optional)

> **Cost:** $99/year Apple Developer Program
> **Decision:** To be made before iOS release

See [APPLE_SIGNIN_SETUP.md](./APPLE_SIGNIN_SETUP.md) if iOS is decided.

---

## Bootstrap Script Details

`bootstrap-appwrite.sh` performs:

1. **Creates admin session** - Uses Appwrite admin credentials
2. **Creates project** - New FUG project in Appwrite
3. **Creates API key** - For migrations and backend operations
4. **Creates database** - fug-db database
5. **Generates .env** - Configuration for migrations
6. **Runs migrations** - All database schema migrations
7. **Configures OAuth** - If credentials files exist

### Usage

```bash
# Interactive mode (prompts for admin credentials)
./bootstrap-appwrite.sh

# With environment variables
APPWRITE_ADMIN_EMAIL=admin@example.com \
APPWRITE_ADMIN_PASSWORD=secret \
./bootstrap-appwrite.sh

# Production environment
./bootstrap-appwrite.sh --env production
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APPWRITE_ENDPOINT` | Appwrite API URL | `http://localhost:9000/v1` |
| `APPWRITE_ADMIN_EMAIL` | Admin email | (prompted) |
| `APPWRITE_ADMIN_PASSWORD` | Admin password | (prompted) |
| `PROJECT_NAME` | Project name | `FUG` |
| `PROJECT_ID` | Project ID | `fug-{timestamp}` |
| `DATABASE_ID` | Database ID | `fug-db` |

---

## Security

### Files to NEVER commit

Add to `.gitignore`:
```gitignore
# OAuth credentials
infrastructure/setup/.google-credentials
infrastructure/setup/.apple-credentials
infrastructure/setup/.env

# Private keys
*.p8
*.pem
```

### Production Secrets

For production, use:
- Environment variables
- Docker secrets
- HashiCorp Vault
- Cloud provider secret managers (AWS Secrets Manager, GCP Secret Manager)

---

## Troubleshooting

### "Connection refused" error
- Ensure Appwrite is running: `docker-compose up -d`
- Check endpoint URL

### "Unauthorized" error
- Verify admin credentials
- Check API key has required scopes

### OAuth callback errors
- Verify redirect URIs match exactly
- Check provider console configuration

---

## Migration System

Migrations are in `../migrations/`. See that directory for:
- `migrate.js` - Migration runner
- `migrations/` - Migration files

```bash
# Check migration status
cd ../migrations
node migrate.js status

# Run pending migrations
node migrate.js up

# Rollback last batch
node migrate.js down
```

---

*Last updated: 2026-01-21*
