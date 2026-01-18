# FUG Migrations

A powerful database migration system for Appwrite, inspired by Flyway and Laravel migrations.

## Features

- **Version Control for Database Schema**: Track all database changes with versioned migration files
- **Environment Support**: Separate configurations for development, test, and production
- **Batch Tracking**: Migrations are grouped in batches for easy rollback
- **Checksum Validation**: Detect when migration files have been modified
- **Concurrent Execution Protection**: Locking mechanism prevents simultaneous migrations
- **Dry Run Mode**: Preview changes without executing them
- **Colored Output**: Beautiful CLI output with progress indicators

## Installation

```bash
cd infrastructure/migrations
npm install
```

## Quick Start

1. **Configure your environment**:
   ```bash
   # Copy and edit the environment file
   cp environments/.env.development environments/.env.development.local
   # Edit with your Appwrite credentials
   ```

2. **Test the connection**:
   ```bash
   npm run migrate:dev -- test
   ```

3. **Run migrations**:
   ```bash
   npm run migrate:dev
   ```

## Commands

### Apply Migrations

```bash
# Apply all pending migrations (development)
npm run migrate

# Apply with specific environment
npm run migrate:dev      # Development
npm run migrate:test     # Test
npm run migrate:prod     # Production

# Or use the CLI directly
node migrate.js up --env=development
node migrate.js up --env=production --force
```

### Rollback Migrations

```bash
# Rollback the last batch
node migrate.js down

# Rollback multiple batches
node migrate.js down --steps=3

# With environment
node migrate.js down --env=production --steps=1
```

### Check Status

```bash
# View migration status
node migrate.js status

# With environment
node migrate.js status --env=production
```

### Create New Migration

```bash
# Create a new migration file
node migrate.js create add_user_preferences

# Creates: migrations/013_add_user_preferences.js
```

### Reset (Danger!)

```bash
# Rollback ALL migrations
node migrate.js reset

# Reset and re-run all migrations
node migrate.js fresh
```

### Test Connection

```bash
# Test Appwrite connection
node migrate.js test --env=development
```

## CLI Options

| Option | Short | Description |
|--------|-------|-------------|
| `--env` | `-e` | Environment (development, test, production) |
| `--dry-run` | | Show what would be done without making changes |
| `--verbose` | `-v` | Show detailed output |
| `--force` | | Force execution without confirmation prompts |

## Creating Migrations

### Migration File Structure

Each migration is an ES module that exports an object with `name`, `up`, and `down` methods:

```javascript
// migrations/013_add_user_preferences.js

export default {
  name: '013_add_user_preferences',

  /**
   * Run the migration
   * @param {Client} client - Appwrite client
   * @param {Databases} databases - Appwrite Databases service
   * @param {Object} log - Logger instance
   * @param {Object} config - Environment configuration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Create attributes
    await databases.createStringAttribute(
      databaseId,
      'users',
      'preferences',
      2000,
      false
    );

    log.info('Added preferences attribute to users');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    await databases.deleteAttribute(databaseId, 'users', 'preferences');

    log.info('Removed preferences attribute from users');
  },
};
```

### Best Practices

1. **One Change Per Migration**: Keep migrations focused on a single change
2. **Always Implement `down()`**: Make sure you can rollback any migration
3. **Wait for Attributes**: Appwrite creates attributes asynchronously

   ```javascript
   // Helper to wait for attribute
   const waitForAttribute = async (collectionId, attrKey, maxWait = 30000) => {
     const start = Date.now();
     while (Date.now() - start < maxWait) {
       const collection = await databases.getCollection(databaseId, collectionId);
       const attr = collection.attributes.find((a) => a.key === attrKey);
       if (attr && attr.status === 'available') {
         return true;
       }
       await new Promise((resolve) => setTimeout(resolve, 500));
     }
     throw new Error(`Timeout waiting for attribute ${attrKey}`);
   };
   ```

4. **Use Descriptive Names**: Migration names should describe what they do
5. **Don't Modify Applied Migrations**: Create new migrations for changes

### Available Logger Methods

```javascript
log.info('Informational message');     // Blue info icon
log.success('Success message');        // Green checkmark
log.error('Error message');            // Red X
log.warn('Warning message');           // Yellow warning
log.step('Step description');          // Cyan arrow
log.debug('Debug info');               // Only shown with --verbose
```

## Environment Configuration

### Development (`environments/.env.development`)

```env
APPWRITE_ENDPOINT=http://localhost/v1
APPWRITE_PROJECT_ID=fug-dev
APPWRITE_API_KEY=your-dev-api-key
DATABASE_ID=fug-db
```

### Test (`environments/.env.test`)

```env
APPWRITE_ENDPOINT=http://localhost/v1
APPWRITE_PROJECT_ID=fug-test
APPWRITE_API_KEY=your-test-api-key
DATABASE_ID=fug-db-test
```

### Production (`environments/.env.production`)

```env
APPWRITE_ENDPOINT=https://appwrite.fug.app/v1
APPWRITE_PROJECT_ID=fug-prod
APPWRITE_API_KEY=${APPWRITE_API_KEY}  # Use system env var
DATABASE_ID=fug-db
```

For production, set the API key via system environment variable:

```bash
export APPWRITE_API_KEY=your-production-key
node migrate.js up --env=production
```

## Migration Tracking

The system uses a `_migrations` collection to track:

- **name**: Migration identifier
- **batch**: Batch number (for grouped rollbacks)
- **applied_at**: When the migration was applied
- **checksum**: SHA-256 hash of the migration file

### Checksum Validation

If a migration file is modified after being applied, the system will warn you:

```
⚠ Checksum mismatch for 005_events_base - migration has been modified!
```

This helps detect accidental modifications to applied migrations.

## Included Migrations

| Migration | Description |
|-----------|-------------|
| `001_initial_schema` | Creates 7 base collections |
| `002_users_base_attributes` | User basic fields (name, email, etc.) |
| `003_users_gamification` | Points, level, follower counts |
| `004_users_location` | Location and notification settings |
| `005_events_base` | Event basic fields |
| `006_events_location` | Event location fields |
| `007_followers_schema` | Followers collection attributes |
| `008_participants_schema` | Event participants attributes |
| `009_achievements_schema` | Achievements system |
| `010_notifications_schema` | Notifications collection |
| `011_indexes` | All database indexes |
| `012_seed_achievements` | Initial achievements data |

## Troubleshooting

### Connection Failed

```
✘ Cannot connect to Appwrite at http://localhost/v1. Is the server running?
```

- Check that Appwrite is running
- Verify the `APPWRITE_ENDPOINT` is correct
- Ensure network connectivity

### Invalid API Key

```
✘ Invalid API key. Please check your APPWRITE_API_KEY.
```

- Verify your API key in the Appwrite console
- Make sure the key has the required permissions

### Migration Locked

```
LOCKED Another migration is in progress
```

- Wait for the other migration to complete
- If stuck, the lock will auto-expire after 5 minutes
- Or manually delete the `_migration_lock` document

### Attribute Timeout

```
Error: Timeout waiting for attribute xyz
```

- Appwrite may be slow to create attributes
- Try increasing the timeout in the migration
- Check Appwrite server resources

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Database Migrations

on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/migrations/**'

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        working-directory: infrastructure/migrations
        run: npm ci

      - name: Run migrations
        working-directory: infrastructure/migrations
        env:
          APPWRITE_API_KEY: ${{ secrets.APPWRITE_API_KEY }}
        run: node migrate.js up --env=production --force
```

## License

MIT
