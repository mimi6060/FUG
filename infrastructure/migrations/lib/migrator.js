/**
 * FUG Migrations - Core Migrator
 *
 * Handles migration execution, tracking, locking, and rollback.
 * Inspired by Flyway and Laravel migrations.
 */

import { readdir, readFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { createHash } from 'crypto';
import { getAppwriteServices, ensureDatabase, loadConfig } from './appwrite-client.js';
import { createLogger } from './logger.js';
import { Permission, Role, Query, ID } from 'node-appwrite';

// Migration types - exported for use in migrations
export const MIGRATION_TYPE_BOOTSTRAP = 'bootstrap'; // Only runs on fresh install
export const MIGRATION_TYPE_UPGRADE = 'upgrade'; // Runs on existing installs (default)

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Constants
const MIGRATIONS_COLLECTION_ID = 'migrations_tracking';
const LOCK_DOCUMENT_ID = 'migration_lock';
const LOCK_TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Create a migration context for bootstrap migrations
 * Provides helper methods to check installation state
 */
class MigrationContext {
  constructor(migrator) {
    this.migrator = migrator;
    this.services = migrator.services;
    this.config = migrator.services?.config;
    this.log = migrator.log;
    this._cache = {};
  }

  /**
   * Check if the FUG project exists
   */
  async projectExists() {
    if (this._cache.projectExists !== undefined) {
      return this._cache.projectExists;
    }

    try {
      const { databases, config } = this.services;
      // Try to access the database to check if project is configured
      await databases.get(config.databaseId);
      this._cache.projectExists = true;
      return true;
    } catch (error) {
      if (error.code === 404 || error.code === 401) {
        this._cache.projectExists = false;
        return false;
      }
      // Unknown error, assume project exists to be safe
      this._cache.projectExists = true;
      return true;
    }
  }

  /**
   * Check if the database exists
   */
  async databaseExists() {
    if (this._cache.databaseExists !== undefined) {
      return this._cache.databaseExists;
    }

    try {
      const { databases, config } = this.services;
      await databases.get(config.databaseId);
      this._cache.databaseExists = true;
      return true;
    } catch (error) {
      if (error.code === 404) {
        this._cache.databaseExists = false;
        return false;
      }
      throw error;
    }
  }

  /**
   * Check if a collection exists
   */
  async collectionExists(collectionId) {
    try {
      const { databases, config } = this.services;
      await databases.getCollection(config.databaseId, collectionId);
      return true;
    } catch (error) {
      if (error.code === 404) {
        return false;
      }
      throw error;
    }
  }

  /**
   * Check if this is a fresh installation (no migrations have run)
   */
  async isFreshInstall() {
    if (this._cache.isFreshInstall !== undefined) {
      return this._cache.isFreshInstall;
    }

    try {
      const applied = await this.migrator.getAppliedMigrations();
      const result = Object.keys(applied).length === 0;
      this._cache.isFreshInstall = result;
      return result;
    } catch (error) {
      // If we can't check, assume fresh install
      this._cache.isFreshInstall = true;
      return true;
    }
  }
}

/**
 * Create a Migrator instance
 */
export class Migrator {
  constructor(options = {}) {
    this.environment = options.environment || 'development';
    this.dryRun = options.dryRun || false;
    this.verbose = options.verbose || false;
    this.migrationsPath = options.migrationsPath || join(__dirname, '..', 'migrations');
    this.includeBootstrap = options.includeBootstrap !== false; // Include bootstrap migrations by default

    this.log = createLogger({
      silent: options.silent || false,
      verbose: this.verbose,
    });

    this.services = null;
    this.initialized = false;
    this.context = null;
  }

  /**
   * Initialize the migrator
   */
  async initialize() {
    if (this.initialized) return;

    this.services = getAppwriteServices(this.environment);

    // Create migration context for bootstrap migrations
    this.context = new MigrationContext(this);

    // Ensure database exists
    await ensureDatabase(this.environment);

    // Ensure migrations collection exists
    await this.ensureMigrationsCollection();

    this.initialized = true;
  }

  /**
   * Check if a migration should run based on its type and shouldRun() method
   */
  async shouldRunMigration(migration, filename) {
    const migrationType = migration.type || MIGRATION_TYPE_UPGRADE;

    // Handle bootstrap migrations when --skip-bootstrap is used
    if (migrationType === MIGRATION_TYPE_BOOTSTRAP) {
      if (!this.includeBootstrap) {
        this.log.debug(`Bootstrap migration ${filename} skipped (--skip-bootstrap)`);
        return false;
      }

      // Bootstrap migrations only run on fresh installations
      const isFresh = await this.context.isFreshInstall();
      if (!isFresh) {
        this.log.debug(`Bootstrap migration ${filename} skipped (not a fresh install)`);
        return false;
      }
    }

    // Check if migration has a custom shouldRun method
    if (typeof migration.shouldRun === 'function') {
      try {
        const shouldRun = await migration.shouldRun(this.context);
        if (!shouldRun) {
          this.log.debug(`Migration ${filename} skipped (shouldRun returned false)`);
          return false;
        }
      } catch (error) {
        this.log.warn(`Error in shouldRun for ${filename}: ${error.message}`);
        // If shouldRun fails, skip the migration to be safe
        return false;
      }
    }

    return true;
  }

  /**
   * Ensure the _migrations tracking collection exists
   */
  async ensureMigrationsCollection() {
    const { databases, config } = this.services;

    try {
      await databases.getCollection(config.databaseId, MIGRATIONS_COLLECTION_ID);
      this.log.debug('Migrations collection exists');
    } catch (error) {
      if (error.code === 404) {
        this.log.info('Creating migrations tracking collection...');

        if (!this.dryRun) {
          // Create collection
          await databases.createCollection(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'Migrations Tracking',
            [
              Permission.read(Role.any()),
              Permission.write(Role.any()),
            ]
          );

          // Create attributes
          await databases.createStringAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'name',
            255,
            true
          );

          await databases.createIntegerAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'batch',
            true
          );

          await databases.createDatetimeAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'applied_at',
            true
          );

          await databases.createStringAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'checksum',
            64,
            true
          );

          await databases.createBooleanAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'is_lock',
            false,
            false
          );

          await databases.createDatetimeAttribute(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'locked_at',
            false
          );

          // Wait for attributes to be available
          await this.waitForAttributes(MIGRATIONS_COLLECTION_ID);

          // Create index on name
          await databases.createIndex(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            'name_idx',
            'unique',
            ['name']
          );
        }

        this.log.success('Migrations tracking collection created');
      } else {
        throw error;
      }
    }
  }

  /**
   * Wait for collection attributes to be available
   */
  async waitForAttributes(collectionId, maxWait = 120000) {
    const { databases, config } = this.services;
    const start = Date.now();

    while (Date.now() - start < maxWait) {
      const collection = await databases.getCollection(config.databaseId, collectionId);
      const allReady = collection.attributes.every((attr) => attr.status === 'available');

      if (allReady) {
        return true;
      }

      await new Promise((resolve) => setTimeout(resolve, 1000));
    }

    throw new Error(`Timeout waiting for attributes on collection ${collectionId}`);
  }

  /**
   * Acquire migration lock
   */
  async acquireLock() {
    const { databases, config, Query } = this.services;

    try {
      // Check for existing lock
      const locks = await databases.listDocuments(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        [Query.equal('is_lock', true)]
      );

      if (locks.documents.length > 0) {
        const lock = locks.documents[0];
        const lockedAt = new Date(lock.locked_at).getTime();
        const now = Date.now();

        // Check if lock is stale
        if (now - lockedAt > LOCK_TIMEOUT_MS) {
          this.log.warn('Found stale lock, removing...');
          await databases.deleteDocument(
            config.databaseId,
            MIGRATIONS_COLLECTION_ID,
            lock.$id
          );
        } else {
          this.log.locked();
          return false;
        }
      }

      // Create lock
      if (!this.dryRun) {
        await databases.createDocument(
          config.databaseId,
          MIGRATIONS_COLLECTION_ID,
          LOCK_DOCUMENT_ID,
          {
            name: '_lock',
            batch: 0,
            applied_at: new Date().toISOString(),
            checksum: 'lock',
            is_lock: true,
            locked_at: new Date().toISOString(),
          }
        );
      }

      return true;
    } catch (error) {
      if (error.code === 409) {
        // Conflict - another process created the lock
        this.log.locked();
        return false;
      }
      throw error;
    }
  }

  /**
   * Release migration lock
   */
  async releaseLock() {
    if (this.dryRun) return;

    const { databases, config } = this.services;

    try {
      await databases.deleteDocument(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        LOCK_DOCUMENT_ID
      );
    } catch (error) {
      if (error.code !== 404) {
        this.log.warn(`Failed to release lock: ${error.message}`);
      }
    }
  }

  /**
   * Get list of migration files
   */
  async getMigrationFiles() {
    const files = await readdir(this.migrationsPath);

    return files
      .filter((f) => f.endsWith('.js') && !f.startsWith('_'))
      .sort((a, b) => {
        // Sort by migration number prefix
        const numA = parseInt(a.split('_')[0], 10);
        const numB = parseInt(b.split('_')[0], 10);
        return numA - numB;
      });
  }

  /**
   * Load a migration file
   */
  async loadMigration(filename) {
    const filePath = join(this.migrationsPath, filename);
    const module = await import(filePath);
    return module.default || module;
  }

  /**
   * Calculate checksum for a migration file
   */
  async calculateChecksum(filename) {
    const filePath = join(this.migrationsPath, filename);
    const content = await readFile(filePath, 'utf-8');
    return createHash('sha256').update(content).digest('hex').substring(0, 64);
  }

  /**
   * Get applied migrations from database
   */
  async getAppliedMigrations() {
    const { databases, config, Query } = this.services;

    try {
      const result = await databases.listDocuments(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        [
          Query.equal('is_lock', false),
          Query.orderAsc('name'),
          Query.limit(1000),
        ]
      );

      return result.documents.reduce((acc, doc) => {
        acc[doc.name] = {
          batch: doc.batch,
          applied_at: doc.applied_at,
          checksum: doc.checksum,
          $id: doc.$id,
        };
        return acc;
      }, {});
    } catch (error) {
      if (error.code === 404) {
        return {};
      }
      throw error;
    }
  }

  /**
   * Get current batch number
   */
  async getCurrentBatch() {
    const { databases, config, Query } = this.services;

    try {
      const result = await databases.listDocuments(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        [
          Query.equal('is_lock', false),
          Query.orderDesc('batch'),
          Query.limit(1),
        ]
      );

      if (result.documents.length === 0) {
        return 0;
      }

      return result.documents[0].batch;
    } catch (error) {
      return 0;
    }
  }

  /**
   * Record a migration as applied
   */
  async recordMigration(name, batch, checksum) {
    if (this.dryRun) return;

    const { databases, config, ID } = this.services;

    await databases.createDocument(
      config.databaseId,
      MIGRATIONS_COLLECTION_ID,
      ID.unique(),
      {
        name,
        batch,
        applied_at: new Date().toISOString(),
        checksum,
        is_lock: false,
      }
    );
  }

  /**
   * Remove a migration record
   */
  async removeMigrationRecord(name) {
    if (this.dryRun) return;

    const { databases, config, Query } = this.services;

    const result = await databases.listDocuments(
      config.databaseId,
      MIGRATIONS_COLLECTION_ID,
      [Query.equal('name', name)]
    );

    if (result.documents.length > 0) {
      await databases.deleteDocument(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        result.documents[0].$id
      );
    }
  }

  /**
   * Get migration status
   */
  async getStatus() {
    await this.initialize();

    const files = await this.getMigrationFiles();
    const applied = await this.getAppliedMigrations();

    const status = [];

    for (const file of files) {
      const name = file.replace('.js', '');
      const checksum = await this.calculateChecksum(file);
      const appliedInfo = applied[name];

      status.push({
        name,
        file,
        applied: !!appliedInfo,
        batch: appliedInfo?.batch,
        applied_at: appliedInfo?.applied_at,
        checksum,
        checksumMatch: appliedInfo ? appliedInfo.checksum === checksum : null,
      });
    }

    return status;
  }

  /**
   * Run pending migrations
   */
  async up(options = {}) {
    await this.initialize();

    const startTime = Date.now();

    this.log.header('FUG Migrations - Up');
    this.log.environment(
      this.environment,
      this.services.config.endpoint,
      this.services.config.projectId
    );

    if (this.dryRun) {
      this.log.dryRun();
    }

    // Acquire lock
    const lockAcquired = await this.acquireLock();
    if (!lockAcquired) {
      return { applied: 0, failed: 0, skipped: 0 };
    }

    try {
      const files = await this.getMigrationFiles();
      const applied = await this.getAppliedMigrations();
      const currentBatch = await this.getCurrentBatch();
      const newBatch = currentBatch + 1;

      let appliedCount = 0;
      let failedCount = 0;
      let skippedCount = 0;

      for (const file of files) {
        const name = file.replace('.js', '');

        if (applied[name]) {
          // Check checksum
          const checksum = await this.calculateChecksum(file);
          if (applied[name].checksum !== checksum) {
            this.log.warn(`Checksum mismatch for ${name} - migration has been modified!`);
          }
          skippedCount++;
          continue;
        }

        try {
          const migration = await this.loadMigration(file);

          // Check if migration should run (bootstrap type, shouldRun method, etc.)
          const shouldRun = await this.shouldRunMigration(migration, file);
          if (!shouldRun) {
            this.log.info(`Skipped: ${name} (condition not met)`);
            skippedCount++;
            continue;
          }

          this.log.migration(name, 'up');

          const checksum = await this.calculateChecksum(file);

          if (!this.dryRun) {
            // Pass context as 5th argument for bootstrap migrations
            await migration.up(
              this.services.client,
              this.services.databases,
              this.log,
              this.services.config,
              this.context
            );

            await this.recordMigration(name, newBatch, checksum);
          }

          this.log.success(`Applied: ${name}`);
          appliedCount++;
        } catch (error) {
          this.log.error(`Failed: ${name}`);
          this.log.error(`  ${error.message}`);
          if (this.verbose) {
            console.error(error);
          }
          failedCount++;

          // Stop on first failure unless forced
          if (!options.force) {
            break;
          }
        }
      }

      this.log.summary(appliedCount, failedCount, skippedCount);
      this.log.elapsed(Date.now() - startTime);

      return { applied: appliedCount, failed: failedCount, skipped: skippedCount };
    } finally {
      await this.releaseLock();
    }
  }

  /**
   * Rollback migrations
   */
  async down(options = {}) {
    await this.initialize();

    const steps = options.steps || 1;
    const startTime = Date.now();

    this.log.header('FUG Migrations - Down (Rollback)');
    this.log.environment(
      this.environment,
      this.services.config.endpoint,
      this.services.config.projectId
    );

    if (this.dryRun) {
      this.log.dryRun();
    }

    // Acquire lock
    const lockAcquired = await this.acquireLock();
    if (!lockAcquired) {
      return { rolledBack: 0, failed: 0 };
    }

    try {
      const currentBatch = await this.getCurrentBatch();

      if (currentBatch === 0) {
        this.log.info('Nothing to rollback');
        return { rolledBack: 0, failed: 0 };
      }

      // Get migrations to rollback
      const { databases, config, Query } = this.services;
      const result = await databases.listDocuments(
        config.databaseId,
        MIGRATIONS_COLLECTION_ID,
        [
          Query.equal('is_lock', false),
          Query.greaterThanEqual('batch', currentBatch - steps + 1),
          Query.orderDesc('name'),
          Query.limit(1000),
        ]
      );

      let rolledBackCount = 0;
      let failedCount = 0;

      for (const doc of result.documents) {
        const file = `${doc.name}.js`;
        this.log.migration(doc.name, 'down');

        try {
          const migration = await this.loadMigration(file);

          if (!this.dryRun) {
            if (migration.down) {
              await migration.down(
                this.services.client,
                this.services.databases,
                this.log,
                this.services.config
              );
            } else {
              this.log.warn(`No down() method for ${doc.name}`);
            }

            await this.removeMigrationRecord(doc.name);
          }

          this.log.success(`Rolled back: ${doc.name}`);
          rolledBackCount++;
        } catch (error) {
          this.log.error(`Failed to rollback: ${doc.name}`);
          this.log.error(`  ${error.message}`);
          if (this.verbose) {
            console.error(error);
          }
          failedCount++;
          break;
        }
      }

      this.log.summary(0, failedCount, 0);
      this.log.raw(`  Rolled back: ${rolledBackCount}`);
      this.log.elapsed(Date.now() - startTime);

      return { rolledBack: rolledBackCount, failed: failedCount };
    } finally {
      await this.releaseLock();
    }
  }

  /**
   * Reset all migrations (dangerous!)
   */
  async reset() {
    await this.initialize();

    const startTime = Date.now();

    this.log.header('FUG Migrations - Reset');
    this.log.environment(
      this.environment,
      this.services.config.endpoint,
      this.services.config.projectId
    );

    if (this.dryRun) {
      this.log.dryRun();
    }

    // Get all applied migrations
    const applied = await this.getAppliedMigrations();
    const migrationNames = Object.keys(applied).sort().reverse();

    let rolledBackCount = 0;
    let failedCount = 0;

    for (const name of migrationNames) {
      const file = `${name}.js`;
      this.log.migration(name, 'down');

      try {
        const migration = await this.loadMigration(file);

        if (!this.dryRun) {
          if (migration.down) {
            await migration.down(
              this.services.client,
              this.services.databases,
              this.log,
              this.services.config
            );
          }

          await this.removeMigrationRecord(name);
        }

        this.log.success(`Rolled back: ${name}`);
        rolledBackCount++;
      } catch (error) {
        this.log.error(`Failed to rollback: ${name}`);
        this.log.error(`  ${error.message}`);
        if (this.verbose) {
          console.error(error);
        }
        failedCount++;
      }
    }

    this.log.elapsed(Date.now() - startTime);

    return { rolledBack: rolledBackCount, failed: failedCount };
  }

  /**
   * Fresh migration (reset + up)
   */
  async fresh() {
    this.log.header('FUG Migrations - Fresh');

    const resetResult = await this.reset();
    const upResult = await this.up();

    return {
      reset: resetResult,
      up: upResult,
    };
  }
}

/**
 * Create migration file template
 * @param {string} name - Migration name
 * @param {number} number - Migration number
 * @param {Object} options - Template options
 * @param {string} options.type - Migration type: 'upgrade' (default) or 'bootstrap'
 */
export function createMigrationTemplate(name, number, options = {}) {
  const paddedNumber = String(number).padStart(3, '0');
  const migrationName = `${paddedNumber}_${name}`;
  const migrationType = options.type || 'upgrade';

  const bootstrapExample = migrationType === 'bootstrap' ? `
  // type: 'bootstrap' means this migration only runs on fresh installations
  type: 'bootstrap',

  /**
   * Optional: Custom condition for running this migration
   * @param {MigrationContext} context - Context with helper methods
   * @returns {Promise<boolean>} True if migration should run
   */
  async shouldRun(context) {
    // Example: Only run if database doesn't exist
    return !await context.databaseExists();
  },
` : `
  // type: 'upgrade' (default) - runs on all installations
  // type: 'bootstrap' - only runs on fresh installations
  type: 'upgrade',
`;

  const template = `/**
 * Migration: ${migrationName}
 * Created: ${new Date().toISOString()}
 * Type: ${migrationType}
 */

export default {
  name: '${migrationName}',
${bootstrapExample}
  /**
   * Run the migration
   * @param {Client} client - Appwrite client
   * @param {Databases} databases - Appwrite Databases service
   * @param {Object} log - Logger instance
   * @param {Object} config - Environment configuration
   * @param {MigrationContext} context - Context with helper methods (optional)
   */
  async up(client, databases, log, config, context) {
    const databaseId = config.databaseId;

    // TODO: Implement migration
    // Example:
    // await databases.createCollection(databaseId, 'collection_id', 'Collection Name');
    // await databases.createStringAttribute(databaseId, 'collection_id', 'field_name', 255, true);
    //
    // For idempotent operations, use context helpers:
    // if (!await context.collectionExists('collection_id')) {
    //   await databases.createCollection(...);
    // }

    log.info('Migration ${migrationName} applied');
  },

  /**
   * Reverse the migration
   * @param {Client} client - Appwrite client
   * @param {Databases} databases - Appwrite Databases service
   * @param {Object} log - Logger instance
   * @param {Object} config - Environment configuration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // TODO: Implement rollback
    // Example:
    // await databases.deleteCollection(databaseId, 'collection_id');

    log.info('Migration ${migrationName} rolled back');
  },
};
`;

  return {
    filename: `${migrationName}.js`,
    content: template,
  };
}

export default Migrator;
