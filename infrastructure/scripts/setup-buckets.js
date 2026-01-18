#!/usr/bin/env node

/**
 * FUG - Appwrite Storage Buckets Setup Script
 * Creates storage buckets for user avatars and event images
 */

import { Client, Storage, Permission, Role } from 'node-appwrite';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
  dim: '\x1b[2m',
};

// Logger
const log = {
  info: (msg) => console.log(`${colors.blue}[INFO]${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}[SUCCESS]${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}[ERROR]${colors.reset} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow}[WARN]${colors.reset} ${msg}`),
  detail: (msg) => console.log(`${colors.dim}  ${msg}${colors.reset}`),
};

// Validate environment variables
const requiredEnvVars = ['APPWRITE_ENDPOINT', 'APPWRITE_PROJECT_ID', 'APPWRITE_API_KEY'];
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    log.error(`Missing required environment variable: ${envVar}`);
    process.exit(1);
  }
}

// Initialize Appwrite client
const client = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const storage = new Storage(client);

// Bucket IDs
const BUCKETS = {
  AVATARS: 'avatars',
  EVENT_IMAGES: 'event-images',
};

// Bucket definitions
const bucketDefinitions = {
  [BUCKETS.AVATARS]: {
    name: 'User Avatars',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSecurity: true,
    enabled: true,
    maximumFileSize: 2 * 1024 * 1024, // 2MB
    allowedFileExtensions: ['jpeg', 'jpg', 'png', 'webp'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },

  [BUCKETS.EVENT_IMAGES]: {
    name: 'Event Images',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSecurity: true,
    enabled: true,
    maximumFileSize: 5 * 1024 * 1024, // 5MB
    allowedFileExtensions: ['jpeg', 'jpg', 'png', 'webp', 'gif'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },
};

/**
 * Check if a bucket exists
 */
async function bucketExists(bucketId) {
  try {
    await storage.getBucket(bucketId);
    return true;
  } catch (error) {
    if (error.code === 404) {
      return false;
    }
    throw error;
  }
}

/**
 * Format file size for display
 */
function formatFileSize(bytes) {
  if (bytes >= 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(0)}MB`;
  }
  if (bytes >= 1024) {
    return `${(bytes / 1024).toFixed(0)}KB`;
  }
  return `${bytes}B`;
}

/**
 * Create a storage bucket
 */
async function createBucket(bucketId, definition) {
  log.info(`Creating bucket: ${colors.cyan}${definition.name}${colors.reset} (${bucketId})`);

  try {
    // Check if bucket already exists
    if (await bucketExists(bucketId)) {
      log.warn(`Bucket already exists: ${bucketId}`);

      // Update existing bucket settings
      await storage.updateBucket(
        bucketId,
        definition.name,
        definition.permissions,
        definition.fileSecurity,
        definition.enabled,
        definition.maximumFileSize,
        definition.allowedFileExtensions,
        definition.compression,
        definition.encryption,
        definition.antivirus
      );

      log.success(`Bucket updated: ${bucketId}`);
    } else {
      // Create new bucket
      await storage.createBucket(
        bucketId,
        definition.name,
        definition.permissions,
        definition.fileSecurity,
        definition.enabled,
        definition.maximumFileSize,
        definition.allowedFileExtensions,
        definition.compression,
        definition.encryption,
        definition.antivirus
      );

      log.success(`Bucket created: ${bucketId}`);
    }

    // Display bucket details
    log.detail(`Max size: ${formatFileSize(definition.maximumFileSize)}`);
    log.detail(`Allowed types: ${definition.allowedFileExtensions.map(ext => `image/${ext}`).join(', ')}`);
    log.detail(`Compression: ${definition.compression}`);
    log.detail(`Encryption: ${definition.encryption ? 'enabled' : 'disabled'}`);
    log.detail(`Antivirus: ${definition.antivirus ? 'enabled' : 'disabled'}`);

  } catch (error) {
    if (error.code === 409) {
      log.warn(`Bucket already exists: ${bucketId}`);
    } else {
      throw error;
    }
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('');
  console.log(`${colors.cyan}${colors.bright}========================================${colors.reset}`);
  console.log(`${colors.cyan}${colors.bright}  FUG - Appwrite Buckets Setup${colors.reset}`);
  console.log(`${colors.cyan}${colors.bright}========================================${colors.reset}`);
  console.log('');

  try {
    // Create all buckets
    for (const [bucketId, definition] of Object.entries(bucketDefinitions)) {
      await createBucket(bucketId, definition);
      console.log('');
    }

    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    log.success('All buckets created successfully!');
    console.log(`${colors.dim}  Total buckets: ${Object.keys(bucketDefinitions).length}${colors.reset}`);
    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    console.log('');

    // Print bucket summary
    console.log(`${colors.bright}Bucket Summary:${colors.reset}`);
    console.log(`${colors.dim}---------------${colors.reset}`);
    console.log(`  ${colors.cyan}${BUCKETS.AVATARS}${colors.reset}: User profile pictures (max 2MB)`);
    console.log(`    Formats: image/jpeg, image/png, image/webp`);
    console.log(`  ${colors.cyan}${BUCKETS.EVENT_IMAGES}${colors.reset}: Event photos (max 5MB)`);
    console.log(`    Formats: image/jpeg, image/png, image/webp, image/gif`);
    console.log('');

  } catch (error) {
    log.error(`Setup failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

main();
