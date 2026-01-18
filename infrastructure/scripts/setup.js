#!/usr/bin/env node

/**
 * FUG - Appwrite Setup Orchestrator
 * Main entry point for initializing the entire Appwrite infrastructure
 */

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ANSI color codes for beautiful logs
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',

  // Foreground colors
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',

  // Background colors
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
};

// Logger with colors
const log = {
  info: (msg) => console.log(`${colors.blue}[INFO]${colors.reset} ${msg}`),
  success: (msg) => console.log(`${colors.green}[SUCCESS]${colors.reset} ${msg}`),
  error: (msg) => console.log(`${colors.red}[ERROR]${colors.reset} ${msg}`),
  warn: (msg) => console.log(`${colors.yellow}[WARN]${colors.reset} ${msg}`),
  step: (msg) => console.log(`${colors.cyan}${colors.bright}>>> ${msg}${colors.reset}`),
  header: (msg) => {
    console.log('');
    console.log(`${colors.bgBlue}${colors.white}${colors.bright} ${msg} ${colors.reset}`);
    console.log('');
  },
};

// Scripts to execute in order
const setupScripts = [
  { name: 'setup-collections.js', description: 'Creating collections and attributes' },
  { name: 'setup-indexes.js', description: 'Creating database indexes' },
  { name: 'setup-buckets.js', description: 'Creating storage buckets' },
  { name: 'seed-data.js', description: 'Seeding initial data (achievements)' },
];

/**
 * Execute a Node.js script and return a promise
 */
function runScript(scriptName, description) {
  return new Promise((resolve, reject) => {
    const scriptPath = join(__dirname, scriptName);

    log.step(description);
    log.info(`Running: ${scriptName}`);
    console.log('');

    const child = spawn('node', [scriptPath], {
      cwd: __dirname,
      stdio: 'inherit',
      env: process.env,
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Script ${scriptName} exited with code ${code}`));
      }
    });

    child.on('error', (err) => {
      reject(new Error(`Failed to run ${scriptName}: ${err.message}`));
    });
  });
}

/**
 * Validate required environment variables
 */
function validateEnv() {
  const required = ['APPWRITE_ENDPOINT', 'APPWRITE_PROJECT_ID', 'APPWRITE_API_KEY'];
  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    log.error('Missing required environment variables:');
    missing.forEach((key) => console.log(`  - ${key}`));
    console.log('');
    log.info('Please create a .env file based on .env.example');
    process.exit(1);
  }

  return {
    endpoint: process.env.APPWRITE_ENDPOINT,
    projectId: process.env.APPWRITE_PROJECT_ID,
    databaseId: process.env.DATABASE_ID || 'fug-db',
  };
}

/**
 * Print the banner
 */
function printBanner() {
  console.log('');
  console.log(`${colors.cyan}${colors.bright}`);
  console.log('  ███████╗██╗   ██╗ ██████╗ ');
  console.log('  ██╔════╝██║   ██║██╔════╝ ');
  console.log('  █████╗  ██║   ██║██║  ███╗');
  console.log('  ██╔══╝  ██║   ██║██║   ██║');
  console.log('  ██║     ╚██████╔╝╚██████╔╝');
  console.log('  ╚═╝      ╚═════╝  ╚═════╝ ');
  console.log(`${colors.reset}`);
  console.log(`${colors.dim}  Appwrite Infrastructure Setup${colors.reset}`);
  console.log('');
}

/**
 * Print configuration summary
 */
function printConfig(config) {
  console.log(`${colors.bright}Configuration:${colors.reset}`);
  console.log(`  Endpoint:    ${colors.cyan}${config.endpoint}${colors.reset}`);
  console.log(`  Project ID:  ${colors.cyan}${config.projectId}${colors.reset}`);
  console.log(`  Database ID: ${colors.cyan}${config.databaseId}${colors.reset}`);
  console.log('');
}

/**
 * Print final summary
 */
function printSummary(startTime, results) {
  const duration = ((Date.now() - startTime) / 1000).toFixed(2);
  const successful = results.filter((r) => r.success).length;
  const failed = results.filter((r) => !r.success).length;

  console.log('');
  console.log(`${colors.bgGreen}${colors.white}${colors.bright} SETUP COMPLETE ${colors.reset}`);
  console.log('');
  console.log(`${colors.bright}Summary:${colors.reset}`);
  console.log(`  Duration:   ${colors.cyan}${duration}s${colors.reset}`);
  console.log(`  Successful: ${colors.green}${successful}${colors.reset}`);
  console.log(`  Failed:     ${failed > 0 ? colors.red : colors.dim}${failed}${colors.reset}`);
  console.log('');
  console.log(`${colors.bright}What was created:${colors.reset}`);
  console.log(`  ${colors.green}+${colors.reset} 7 Collections (users, followers, events, event_participants, achievements, user_achievements, notifications)`);
  console.log(`  ${colors.green}+${colors.reset} Database indexes for optimal query performance`);
  console.log(`  ${colors.green}+${colors.reset} 2 Storage buckets (avatars, event-images)`);
  console.log(`  ${colors.green}+${colors.reset} 8 Default achievements`);
  console.log('');
  console.log(`${colors.bright}Next steps:${colors.reset}`);
  console.log(`  1. Configure your Flutter app with the Appwrite credentials`);
  console.log(`  2. Deploy your Appwrite functions`);
  console.log(`  3. Start building your app!`);
  console.log('');
}

/**
 * Main execution
 */
async function main() {
  const startTime = Date.now();
  const results = [];

  printBanner();

  // Validate environment
  const config = validateEnv();
  printConfig(config);

  log.header('STARTING APPWRITE SETUP');

  // Run each setup script in sequence
  for (const script of setupScripts) {
    try {
      await runScript(script.name, script.description);
      results.push({ name: script.name, success: true });
      log.success(`Completed: ${script.name}`);
      console.log('');
    } catch (error) {
      results.push({ name: script.name, success: false, error: error.message });
      log.error(`Failed: ${script.name}`);
      log.error(error.message);
      console.log('');

      // Ask if we should continue on error
      log.warn('Setup encountered an error. Continuing with remaining scripts...');
      console.log('');
    }
  }

  // Print summary
  printSummary(startTime, results);

  // Exit with error code if any script failed
  const hasErrors = results.some((r) => !r.success);
  if (hasErrors) {
    process.exit(1);
  }
}

main().catch((error) => {
  log.error(`Unexpected error: ${error.message}`);
  console.error(error);
  process.exit(1);
});
