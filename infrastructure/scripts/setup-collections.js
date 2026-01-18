#!/usr/bin/env node

/**
 * FUG - Appwrite Collections Setup Script
 * Creates all 7 collections with their complete attributes
 */

import { Client, Databases, Permission, Role, ID } from 'node-appwrite';
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
  dim: '\x1b[2m',
};

// Logger
const log = {
  info: (msg) => console.log(`${colors.blue}[INFO]${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}[SUCCESS]${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}[ERROR]${colors.reset} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow}[WARN]${colors.reset} ${msg}`),
  attr: (msg) => console.log(`${colors.dim}  + ${msg}${colors.reset}`),
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

// Collection definitions with all attributes
const collectionDefinitions = {
  [COLLECTIONS.USERS]: {
    name: 'Users',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'name', size: 255, required: true },
      { type: 'string', key: 'email', size: 255, required: true },
      { type: 'string', key: 'avatar', size: 2048, required: false },
      { type: 'string', key: 'bio', size: 500, required: false },
      { type: 'integer', key: 'points', required: false, default: 0, min: 0, max: 999999999 },
      { type: 'integer', key: 'level', required: false, default: 1, min: 1, max: 100 },
      { type: 'float', key: 'locationLat', required: false, min: -90, max: 90 },
      { type: 'float', key: 'locationLng', required: false, min: -180, max: 180 },
      { type: 'integer', key: 'followersCount', required: false, default: 0, min: 0, max: 999999999 },
      { type: 'integer', key: 'followingCount', required: false, default: 0, min: 0, max: 999999999 },
      { type: 'integer', key: 'eventsCreatedCount', required: false, default: 0, min: 0, max: 999999999 },
      { type: 'integer', key: 'eventsJoinedCount', required: false, default: 0, min: 0, max: 999999999 },
      { type: 'integer', key: 'notificationRadius', required: false, default: 10000, min: 100, max: 100000 },
      { type: 'boolean', key: 'isOnline', required: false, default: false },
      { type: 'datetime', key: 'lastSeenAt', required: false },
      { type: 'datetime', key: 'createdAt', required: false },
    ],
  },

  [COLLECTIONS.FOLLOWERS]: {
    name: 'Followers',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.delete(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'followerId', size: 36, required: true },
      { type: 'string', key: 'followeeId', size: 36, required: true },
      { type: 'datetime', key: 'createdAt', required: false },
    ],
  },

  [COLLECTIONS.EVENTS]: {
    name: 'Events',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'creatorId', size: 36, required: true },
      { type: 'string', key: 'title', size: 255, required: true },
      { type: 'string', key: 'description', size: 2000, required: false },
      { type: 'float', key: 'locationLat', required: true, min: -90, max: 90 },
      { type: 'float', key: 'locationLng', required: true, min: -180, max: 180 },
      { type: 'string', key: 'locationName', size: 500, required: false },
      { type: 'enum', key: 'category', elements: ['bar', 'cafe', 'restaurant', 'park', 'home', 'other'], required: false, default: 'other' },
      { type: 'enum', key: 'status', elements: ['active', 'ended', 'cancelled'], required: false, default: 'active' },
      { type: 'integer', key: 'maxParticipants', required: false, min: 1, max: 1000 },
      { type: 'integer', key: 'participantsCount', required: false, default: 0, min: 0, max: 1000 },
      { type: 'datetime', key: 'startsAt', required: true },
      { type: 'datetime', key: 'endsAt', required: false },
      { type: 'datetime', key: 'createdAt', required: false },
    ],
  },

  [COLLECTIONS.EVENT_PARTICIPANTS]: {
    name: 'Event Participants',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'eventId', size: 36, required: true },
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'enum', key: 'status', elements: ['pending', 'confirmed', 'arrived', 'left'], required: false, default: 'pending' },
      { type: 'string', key: 'arrivalMessage', size: 500, required: false },
      { type: 'datetime', key: 'joinedAt', required: false },
      { type: 'datetime', key: 'arrivedAt', required: false },
    ],
  },

  [COLLECTIONS.ACHIEVEMENTS]: {
    name: 'Achievements',
    permissions: [
      Permission.read(Role.any()),
    ],
    attributes: [
      { type: 'string', key: 'code', size: 50, required: true },
      { type: 'string', key: 'name', size: 100, required: true },
      { type: 'string', key: 'description', size: 500, required: false },
      { type: 'string', key: 'icon', size: 100, required: false },
      { type: 'integer', key: 'points', required: false, default: 0, min: 0, max: 10000 },
      { type: 'string', key: 'conditionType', size: 100, required: false },
      { type: 'integer', key: 'conditionValue', required: false, default: 0, min: 0, max: 999999 },
    ],
  },

  [COLLECTIONS.USER_ACHIEVEMENTS]: {
    name: 'User Achievements',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'string', key: 'achievementId', size: 36, required: true },
      { type: 'datetime', key: 'unlockedAt', required: false },
    ],
  },

  [COLLECTIONS.NOTIFICATIONS]: {
    name: 'Notifications',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    attributes: [
      { type: 'string', key: 'userId', size: 36, required: true },
      { type: 'enum', key: 'type', elements: ['follow', 'event_nearby', 'event_join', 'event_arrive', 'achievement', 'system'], required: true },
      { type: 'string', key: 'title', size: 255, required: false },
      { type: 'string', key: 'body', size: 1000, required: false },
      { type: 'string', key: 'data', size: 2000, required: false },
      { type: 'boolean', key: 'isRead', required: false, default: false },
      { type: 'datetime', key: 'createdAt', required: false },
    ],
  },
};

/**
 * Wait for an attribute to be available
 */
async function waitForAttribute(collectionId, attributeKey, maxRetries = 30) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const attribute = await databases.getAttribute(DATABASE_ID, collectionId, attributeKey);
      if (attribute.status === 'available') {
        return true;
      }
      if (attribute.status === 'failed') {
        throw new Error(`Attribute ${attributeKey} creation failed`);
      }
    } catch (error) {
      if (error.code !== 404) {
        throw error;
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`Timeout waiting for attribute ${attributeKey}`);
}

/**
 * Check if a collection exists
 */
async function collectionExists(collectionId) {
  try {
    await databases.getCollection(DATABASE_ID, collectionId);
    return true;
  } catch (error) {
    if (error.code === 404) {
      return false;
    }
    throw error;
  }
}

/**
 * Create an attribute based on its type
 */
async function createAttribute(collectionId, attr) {
  try {
    switch (attr.type) {
      case 'string':
        await databases.createStringAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.size,
          attr.required,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      case 'integer':
        await databases.createIntegerAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.required,
          attr.min ?? null,
          attr.max ?? null,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      case 'float':
        await databases.createFloatAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.required,
          attr.min ?? null,
          attr.max ?? null,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      case 'boolean':
        await databases.createBooleanAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.required,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      case 'datetime':
        await databases.createDatetimeAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.required,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      case 'enum':
        await databases.createEnumAttribute(
          DATABASE_ID,
          collectionId,
          attr.key,
          attr.elements,
          attr.required,
          attr.default ?? null,
          attr.array ?? false
        );
        break;

      default:
        throw new Error(`Unknown attribute type: ${attr.type}`);
    }

    log.attr(`${attr.key} (${attr.type})`);
  } catch (error) {
    if (error.code === 409) {
      log.warn(`  Attribute already exists: ${attr.key}`);
    } else {
      throw error;
    }
  }
}

/**
 * Create a collection with all its attributes
 */
async function createCollection(collectionId, definition) {
  log.info(`Creating collection: ${colors.cyan}${definition.name}${colors.reset} (${collectionId})`);

  // Check if collection already exists
  if (await collectionExists(collectionId)) {
    log.warn(`Collection already exists: ${collectionId}`);
  } else {
    // Create the collection
    await databases.createCollection(
      DATABASE_ID,
      collectionId,
      definition.name,
      definition.permissions,
      false, // documentSecurity
      true   // enabled
    );
    log.success(`Collection created: ${collectionId}`);
  }

  // Create attributes
  for (const attr of definition.attributes) {
    await createAttribute(collectionId, attr);
    // Wait for attribute to be available before creating next one
    await waitForAttribute(collectionId, attr.key);
  }

  log.success(`All ${definition.attributes.length} attributes created for: ${collectionId}`);
}

/**
 * Ensure database exists
 */
async function ensureDatabase() {
  try {
    await databases.get(DATABASE_ID);
    log.info(`Database exists: ${colors.cyan}${DATABASE_ID}${colors.reset}`);
  } catch (error) {
    if (error.code === 404) {
      log.info(`Creating database: ${DATABASE_ID}`);
      await databases.create(DATABASE_ID, 'FUG Database', true);
      log.success(`Database created: ${DATABASE_ID}`);
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
  console.log(`${colors.cyan}${colors.bright}  FUG - Appwrite Collections Setup${colors.reset}`);
  console.log(`${colors.cyan}${colors.bright}========================================${colors.reset}`);
  console.log('');

  try {
    // Ensure database exists
    await ensureDatabase();
    console.log('');

    // Create all collections
    let totalAttributes = 0;
    for (const [collectionId, definition] of Object.entries(collectionDefinitions)) {
      await createCollection(collectionId, definition);
      totalAttributes += definition.attributes.length;
      console.log('');
    }

    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    log.success('All collections created successfully!');
    console.log(`${colors.dim}  Collections: ${Object.keys(collectionDefinitions).length}${colors.reset}`);
    console.log(`${colors.dim}  Attributes: ${totalAttributes}${colors.reset}`);
    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    console.log('');

  } catch (error) {
    log.error(`Setup failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

main();
