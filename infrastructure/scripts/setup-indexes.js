#!/usr/bin/env node

/**
 * FUG - Appwrite Indexes Setup Script
 * Creates all necessary indexes for optimal query performance
 */

import { Client, Databases } from 'node-appwrite';
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
  index: (msg) => console.log(`${colors.dim}  + ${msg}${colors.reset}`),
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

const databases = new Databases(client);
const DATABASE_ID = process.env.DATABASE_ID || 'fug-db';

// Collection IDs
const COLLECTIONS = {
  USERS: 'users',
  FOLLOWERS: 'followers',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  ACHIEVEMENTS: 'achievements',
  USER_ACHIEVEMENTS: 'user_achievements',
  NOTIFICATIONS: 'notifications',
};

// Index definitions for each collection
const indexDefinitions = {
  [COLLECTIONS.USERS]: [
    {
      key: 'idx_email_unique',
      type: 'unique',
      attributes: ['email'],
      orders: ['ASC'],
    },
    {
      key: 'idx_points_desc',
      type: 'key',
      attributes: ['points'],
      orders: ['DESC'],
    },
  ],

  [COLLECTIONS.FOLLOWERS]: [
    {
      key: 'idx_followerId',
      type: 'key',
      attributes: ['followerId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_followeeId',
      type: 'key',
      attributes: ['followeeId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_follower_followee_unique',
      type: 'unique',
      attributes: ['followerId', 'followeeId'],
      orders: ['ASC', 'ASC'],
    },
  ],

  [COLLECTIONS.EVENTS]: [
    {
      key: 'idx_creatorId',
      type: 'key',
      attributes: ['creatorId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_status',
      type: 'key',
      attributes: ['status'],
      orders: ['ASC'],
    },
    {
      key: 'idx_startsAt_desc',
      type: 'key',
      attributes: ['startsAt'],
      orders: ['DESC'],
    },
  ],

  [COLLECTIONS.EVENT_PARTICIPANTS]: [
    {
      key: 'idx_eventId',
      type: 'key',
      attributes: ['eventId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_userId',
      type: 'key',
      attributes: ['userId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_event_user_unique',
      type: 'unique',
      attributes: ['eventId', 'userId'],
      orders: ['ASC', 'ASC'],
    },
  ],

  [COLLECTIONS.ACHIEVEMENTS]: [
    {
      key: 'idx_code_unique',
      type: 'unique',
      attributes: ['code'],
      orders: ['ASC'],
    },
  ],

  [COLLECTIONS.USER_ACHIEVEMENTS]: [
    {
      key: 'idx_userId',
      type: 'key',
      attributes: ['userId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_achievementId',
      type: 'key',
      attributes: ['achievementId'],
      orders: ['ASC'],
    },
    {
      key: 'idx_user_achievement_unique',
      type: 'unique',
      attributes: ['userId', 'achievementId'],
      orders: ['ASC', 'ASC'],
    },
  ],

  [COLLECTIONS.NOTIFICATIONS]: [
    {
      key: 'idx_userId_isRead',
      type: 'key',
      attributes: ['userId', 'isRead'],
      orders: ['ASC', 'ASC'],
    },
    {
      key: 'idx_createdAt_desc',
      type: 'key',
      attributes: ['createdAt'],
      orders: ['DESC'],
    },
  ],
};

/**
 * Check if an index exists
 */
async function indexExists(collectionId, indexKey) {
  try {
    await databases.getIndex(DATABASE_ID, collectionId, indexKey);
    return true;
  } catch (error) {
    if (error.code === 404) {
      return false;
    }
    throw error;
  }
}

/**
 * Wait for an index to be available
 */
async function waitForIndex(collectionId, indexKey, maxRetries = 60) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const index = await databases.getIndex(DATABASE_ID, collectionId, indexKey);
      if (index.status === 'available') {
        return true;
      }
      if (index.status === 'failed') {
        throw new Error(`Index ${indexKey} creation failed`);
      }
    } catch (error) {
      if (error.code !== 404) {
        throw error;
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`Timeout waiting for index ${indexKey}`);
}

/**
 * Create an index for a collection
 */
async function createIndex(collectionId, indexDef) {
  try {
    // Check if index already exists
    if (await indexExists(collectionId, indexDef.key)) {
      log.warn(`Index already exists: ${indexDef.key}`);
      return;
    }

    await databases.createIndex(
      DATABASE_ID,
      collectionId,
      indexDef.key,
      indexDef.type,
      indexDef.attributes,
      indexDef.orders
    );

    log.index(`${indexDef.key} (${indexDef.type}) on [${indexDef.attributes.join(', ')}]`);

    // Wait for index to be available
    await waitForIndex(collectionId, indexDef.key);
    log.success(`Index ready: ${indexDef.key}`);

  } catch (error) {
    if (error.code === 409) {
      log.warn(`Index already exists: ${indexDef.key}`);
    } else {
      throw error;
    }
  }
}

/**
 * Create all indexes for a collection
 */
async function createCollectionIndexes(collectionId, indexes) {
  log.info(`Creating indexes for: ${colors.cyan}${collectionId}${colors.reset}`);

  for (const indexDef of indexes) {
    await createIndex(collectionId, indexDef);
  }

  log.success(`All ${indexes.length} indexes created for: ${collectionId}`);
}

/**
 * Main execution
 */
async function main() {
  console.log('');
  console.log(`${colors.magenta}${colors.bright}========================================${colors.reset}`);
  console.log(`${colors.magenta}${colors.bright}  FUG - Appwrite Indexes Setup${colors.reset}`);
  console.log(`${colors.magenta}${colors.bright}========================================${colors.reset}`);
  console.log('');

  try {
    let totalIndexes = 0;

    // Create indexes for all collections
    for (const [collectionId, indexes] of Object.entries(indexDefinitions)) {
      await createCollectionIndexes(collectionId, indexes);
      totalIndexes += indexes.length;
      console.log('');
    }

    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    log.success('All indexes created successfully!');
    console.log(`${colors.dim}  Collections: ${Object.keys(indexDefinitions).length}${colors.reset}`);
    console.log(`${colors.dim}  Indexes: ${totalIndexes}${colors.reset}`);
    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    console.log('');

  } catch (error) {
    log.error(`Setup failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

main();
