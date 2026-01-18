/**
 * FUG Migrations - Appwrite Client Configuration
 *
 * Handles environment-based Appwrite client initialization.
 */

import { Client, Databases, ID, Query, Permission, Role } from 'node-appwrite';
import { config } from 'dotenv';
import { existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configuration cache
let cachedConfig = null;
let cachedClient = null;
let cachedDatabases = null;

/**
 * Load environment configuration
 * @param {string} environment - Environment name (development, test, production)
 * @returns {Object} Configuration object
 */
export function loadConfig(environment = 'development') {
  if (cachedConfig && cachedConfig._env === environment) {
    return cachedConfig;
  }

  // Determine environment from multiple sources
  const env = environment || process.env.ENV || process.env.NODE_ENV || 'development';

  // Try to load environment-specific .env file
  const envFile = join(__dirname, '..', 'environments', `.env.${env}`);

  if (existsSync(envFile)) {
    config({ path: envFile, override: true });
  } else {
    // Fallback to root .env
    const rootEnvFile = join(__dirname, '..', '.env');
    if (existsSync(rootEnvFile)) {
      config({ path: rootEnvFile, override: true });
    }
  }

  // Validate required configuration
  const requiredVars = [
    'APPWRITE_ENDPOINT',
    'APPWRITE_PROJECT_ID',
    'APPWRITE_API_KEY',
    'DATABASE_ID',
  ];

  const missing = requiredVars.filter((v) => !process.env[v]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}\n` +
        `Make sure you have a valid .env file in environments/.env.${env} or in the root directory.`
    );
  }

  cachedConfig = {
    _env: env,
    environment: env,
    endpoint: process.env.APPWRITE_ENDPOINT,
    projectId: process.env.APPWRITE_PROJECT_ID,
    apiKey: process.env.APPWRITE_API_KEY,
    databaseId: process.env.DATABASE_ID,
  };

  return cachedConfig;
}

/**
 * Create and configure Appwrite client
 * @param {string} environment - Environment name
 * @returns {Client} Configured Appwrite client
 */
export function createClient(environment = 'development') {
  const cfg = loadConfig(environment);

  if (cachedClient && cachedConfig._env === environment) {
    return cachedClient;
  }

  const client = new Client();

  client
    .setEndpoint(cfg.endpoint)
    .setProject(cfg.projectId)
    .setKey(cfg.apiKey);

  cachedClient = client;
  return client;
}

/**
 * Create Databases service instance
 * @param {string} environment - Environment name
 * @returns {Databases} Appwrite Databases instance
 */
export function createDatabases(environment = 'development') {
  const cfg = loadConfig(environment);

  if (cachedDatabases && cachedConfig._env === environment) {
    return cachedDatabases;
  }

  const client = createClient(environment);
  cachedDatabases = new Databases(client);
  return cachedDatabases;
}

/**
 * Get all Appwrite services needed for migrations
 * @param {string} environment - Environment name
 * @returns {Object} Object containing client, databases, and config
 */
export function getAppwriteServices(environment = 'development') {
  const cfg = loadConfig(environment);
  const client = createClient(environment);
  const databases = createDatabases(environment);

  return {
    client,
    databases,
    config: cfg,
    // Re-export useful utilities
    ID,
    Query,
    Permission,
    Role,
  };
}

/**
 * Test the Appwrite connection
 * @param {string} environment - Environment name
 * @returns {Promise<boolean>} True if connection is successful
 */
export async function testConnection(environment = 'development') {
  try {
    const { databases, config: cfg } = getAppwriteServices(environment);

    // Try to list databases to verify connection
    await databases.list();
    return true;
  } catch (error) {
    if (error.code === 401) {
      throw new Error('Invalid API key. Please check your APPWRITE_API_KEY.');
    }
    if (error.code === 'ECONNREFUSED' || error.message.includes('ECONNREFUSED')) {
      throw new Error(
        `Cannot connect to Appwrite at ${loadConfig(environment).endpoint}. ` +
          'Is the server running?'
      );
    }
    throw error;
  }
}

/**
 * Ensure the database exists
 * @param {string} environment - Environment name
 * @returns {Promise<void>}
 */
export async function ensureDatabase(environment = 'development') {
  const { databases, config: cfg } = getAppwriteServices(environment);

  try {
    await databases.get(cfg.databaseId);
  } catch (error) {
    if (error.code === 404) {
      // Database doesn't exist, create it
      await databases.create(cfg.databaseId, cfg.databaseId);
    } else {
      throw error;
    }
  }
}

/**
 * Reset cached instances (useful for testing)
 */
export function resetCache() {
  cachedConfig = null;
  cachedClient = null;
  cachedDatabases = null;
}

export default {
  loadConfig,
  createClient,
  createDatabases,
  getAppwriteServices,
  testConnection,
  ensureDatabase,
  resetCache,
};
