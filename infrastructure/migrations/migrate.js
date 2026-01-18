#!/usr/bin/env node

/**
 * FUG Migrations CLI
 *
 * A migration system for Appwrite inspired by Flyway and Laravel migrations.
 *
 * Commands:
 *   migrate up      - Apply all pending migrations
 *   migrate down    - Rollback the last batch of migrations
 *   migrate status  - Show migration status
 *   migrate create  - Create a new migration file
 *   migrate reset   - Rollback all migrations
 *   migrate fresh   - Reset and re-run all migrations
 */

import { program } from 'commander';
import { writeFile, readdir, mkdir } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { createInterface } from 'readline';
import { Migrator, createMigrationTemplate } from './lib/migrator.js';
import { createLogger } from './lib/logger.js';
import { testConnection, loadConfig } from './lib/appwrite-client.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const logger = createLogger();

/**
 * Prompt for user confirmation
 */
async function confirm(message) {
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(logger.confirmPrompt(message), (answer) => {
      rl.close();
      resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
    });
  });
}

/**
 * Get the next migration number
 */
async function getNextMigrationNumber() {
  const migrationsPath = join(__dirname, 'migrations');

  try {
    const files = await readdir(migrationsPath);
    const migrationFiles = files.filter((f) => f.endsWith('.js') && /^\d{3}_/.test(f));

    if (migrationFiles.length === 0) {
      return 1;
    }

    const numbers = migrationFiles.map((f) => parseInt(f.split('_')[0], 10));
    return Math.max(...numbers) + 1;
  } catch (error) {
    if (error.code === 'ENOENT') {
      await mkdir(migrationsPath, { recursive: true });
      return 1;
    }
    throw error;
  }
}

/**
 * Initialize the CLI program
 */
program
  .name('fug-migrate')
  .description('FUG Database Migration System for Appwrite')
  .version('1.0.0')
  .option('-e, --env <environment>', 'Environment (development, test, production)', 'development')
  .option('--dry-run', 'Show what would be done without making changes')
  .option('-v, --verbose', 'Show detailed output')
  .option('--force', 'Force execution without confirmation prompts');

/**
 * Command: up - Apply pending migrations
 */
program
  .command('up')
  .description('Apply all pending migrations')
  .action(async () => {
    const opts = program.opts();

    try {
      // Test connection first
      logger.step('Testing Appwrite connection...');
      await testConnection(opts.env);
      logger.success('Connection successful');
      logger.blank();

      const migrator = new Migrator({
        environment: opts.env,
        dryRun: opts.dryRun,
        verbose: opts.verbose,
      });

      const result = await migrator.up({ force: opts.force });

      if (result.failed > 0) {
        process.exit(1);
      }
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: down - Rollback migrations
 */
program
  .command('down')
  .description('Rollback the last batch of migrations')
  .option('-s, --steps <number>', 'Number of batches to rollback', '1')
  .action(async (cmdOpts) => {
    const opts = program.opts();
    const steps = parseInt(cmdOpts.steps, 10);

    try {
      // Confirm if in production
      if (opts.env === 'production' && !opts.force) {
        const confirmed = await confirm(
          `You are about to rollback migrations in PRODUCTION. Are you sure?`
        );
        if (!confirmed) {
          logger.info('Aborted.');
          process.exit(0);
        }
      }

      const migrator = new Migrator({
        environment: opts.env,
        dryRun: opts.dryRun,
        verbose: opts.verbose,
      });

      const result = await migrator.down({ steps });

      if (result.failed > 0) {
        process.exit(1);
      }
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: status - Show migration status
 */
program
  .command('status')
  .description('Show the status of all migrations')
  .action(async () => {
    const opts = program.opts();

    try {
      const cfg = loadConfig(opts.env);

      logger.header('FUG Migrations - Status');
      logger.environment(opts.env, cfg.endpoint, cfg.projectId);

      const migrator = new Migrator({
        environment: opts.env,
        verbose: opts.verbose,
      });

      const status = await migrator.getStatus();

      logger.statusTable(status);

      // Summary
      const applied = status.filter((s) => s.applied).length;
      const pending = status.filter((s) => !s.applied).length;
      const modified = status.filter((s) => s.applied && !s.checksumMatch).length;

      logger.divider();
      logger.raw(`  Total: ${status.length} migration(s)`);
      logger.raw(`  Applied: ${applied}`);
      logger.raw(`  Pending: ${pending}`);
      if (modified > 0) {
        logger.warn(`  Modified: ${modified} (checksum mismatch!)`);
      }
      logger.blank();
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: create - Create a new migration file
 */
program
  .command('create <name>')
  .description('Create a new migration file')
  .action(async (name) => {
    const opts = program.opts();

    try {
      // Validate name
      const cleanName = name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '');

      if (!cleanName) {
        logger.error('Invalid migration name');
        process.exit(1);
      }

      const number = await getNextMigrationNumber();
      const { filename, content } = createMigrationTemplate(cleanName, number);

      const migrationsPath = join(__dirname, 'migrations');
      const filePath = join(migrationsPath, filename);

      await writeFile(filePath, content, 'utf-8');

      logger.success(`Created migration: ${filename}`);
      logger.info(`Path: ${filePath}`);
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: reset - Rollback all migrations
 */
program
  .command('reset')
  .description('Rollback all migrations (DANGER!)')
  .action(async () => {
    const opts = program.opts();

    try {
      // Always confirm reset
      if (!opts.force) {
        const confirmed = await confirm(
          `This will rollback ALL migrations in ${opts.env.toUpperCase()}. Are you sure?`
        );
        if (!confirmed) {
          logger.info('Aborted.');
          process.exit(0);
        }
      }

      const migrator = new Migrator({
        environment: opts.env,
        dryRun: opts.dryRun,
        verbose: opts.verbose,
      });

      const result = await migrator.reset();

      if (result.failed > 0) {
        process.exit(1);
      }
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: fresh - Reset and re-run all migrations
 */
program
  .command('fresh')
  .description('Reset and re-run all migrations (DANGER!)')
  .action(async () => {
    const opts = program.opts();

    try {
      // Confirm in production
      if (opts.env === 'production' && !opts.force) {
        const confirmed = await confirm(
          `You are about to RESET and re-run ALL migrations in PRODUCTION. This will DELETE ALL DATA. Are you absolutely sure?`
        );
        if (!confirmed) {
          logger.info('Aborted.');
          process.exit(0);
        }

        // Double confirm for production
        const doubleConfirmed = await confirm(`Type 'yes' to confirm:`);
        if (!doubleConfirmed) {
          logger.info('Aborted.');
          process.exit(0);
        }
      } else if (!opts.force) {
        const confirmed = await confirm(
          `This will reset and re-run ALL migrations in ${opts.env.toUpperCase()}. Are you sure?`
        );
        if (!confirmed) {
          logger.info('Aborted.');
          process.exit(0);
        }
      }

      const migrator = new Migrator({
        environment: opts.env,
        dryRun: opts.dryRun,
        verbose: opts.verbose,
      });

      const result = await migrator.fresh();

      if (result.up.failed > 0) {
        process.exit(1);
      }
    } catch (error) {
      logger.error(error.message);
      if (opts.verbose) {
        console.error(error);
      }
      process.exit(1);
    }
  });

/**
 * Command: test - Test Appwrite connection
 */
program
  .command('test')
  .description('Test Appwrite connection')
  .action(async () => {
    const opts = program.opts();

    try {
      const cfg = loadConfig(opts.env);

      logger.header('FUG Migrations - Connection Test');
      logger.environment(opts.env, cfg.endpoint, cfg.projectId);

      logger.step('Testing connection...');
      await testConnection(opts.env);

      logger.success('Connection successful!');
      logger.info('Appwrite is reachable and API key is valid.');
    } catch (error) {
      logger.error('Connection failed!');
      logger.error(error.message);
      process.exit(1);
    }
  });

// Parse arguments
program.parse();

// Show help if no command provided
if (!process.argv.slice(2).length) {
  program.help();
}
