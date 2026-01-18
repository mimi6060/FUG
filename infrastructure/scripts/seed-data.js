#!/usr/bin/env node

/**
 * FUG - Seed Data Script
 * Inserts default achievements into the database
 */

import { Client, Databases, Query, ID } from 'node-appwrite';
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
  achievement: (name, points) => console.log(`${colors.dim}  + ${name} (${points} pts)${colors.reset}`),
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
const ACHIEVEMENTS_COLLECTION = 'achievements';

// Achievement definitions - exactly as specified
const achievements = [
  {
    code: 'first_fug',
    name: 'Premiere FUG',
    description: 'Creer sa premiere FUG',
    icon: 'party_popper',
    points: 10,
    conditionType: 'events_created',
    conditionValue: 1,
  },
  {
    code: 'social_butterfly',
    name: 'Papillon Social',
    description: 'Suivre 10 personnes',
    icon: 'butterfly',
    points: 25,
    conditionType: 'following_count',
    conditionValue: 10,
  },
  {
    code: 'party_starter',
    name: 'Animateur',
    description: 'Avoir 5 participants a sa FUG',
    icon: 'fire',
    points: 50,
    conditionType: 'event_participants_hosted',
    conditionValue: 5,
  },
  {
    code: 'regular',
    name: 'Habitue',
    description: 'Participer a 10 FUG',
    icon: 'calendar',
    points: 30,
    conditionType: 'events_joined',
    conditionValue: 10,
  },
  {
    code: 'popular',
    name: 'Populaire',
    description: 'Avoir 50 followers',
    icon: 'star',
    points: 100,
    conditionType: 'followers_count',
    conditionValue: 50,
  },
  {
    code: 'explorer',
    name: 'Explorateur',
    description: 'Rejoindre 5 FUG differentes',
    icon: 'compass',
    points: 20,
    conditionType: 'events_joined',
    conditionValue: 5,
  },
  {
    code: 'early_bird',
    name: 'Leve-tot',
    description: 'Creer une FUG avant 10h',
    icon: 'bird',
    points: 15,
    conditionType: 'early_event',
    conditionValue: 10,
  },
  {
    code: 'night_owl',
    name: 'Noctambule',
    description: 'Creer une FUG apres 22h',
    icon: 'owl',
    points: 15,
    conditionType: 'late_event',
    conditionValue: 22,
  },
];

/**
 * Check if an achievement already exists by code
 */
async function achievementExists(code) {
  try {
    const result = await databases.listDocuments(
      DATABASE_ID,
      ACHIEVEMENTS_COLLECTION,
      [Query.equal('code', code), Query.limit(1)]
    );
    return result.documents.length > 0;
  } catch (error) {
    return false;
  }
}

/**
 * Create an achievement
 */
async function createAchievement(achievement) {
  try {
    // Check if already exists
    if (await achievementExists(achievement.code)) {
      log.warn(`Achievement already exists: ${achievement.code}`);
      return { created: false, skipped: true };
    }

    await databases.createDocument(
      DATABASE_ID,
      ACHIEVEMENTS_COLLECTION,
      ID.unique(),
      achievement
    );

    log.achievement(achievement.name, achievement.points);
    return { created: true, skipped: false };

  } catch (error) {
    if (error.code === 409) {
      log.warn(`Achievement already exists: ${achievement.code}`);
      return { created: false, skipped: true };
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
  console.log(`${colors.yellow}${colors.bright}========================================${colors.reset}`);
  console.log(`${colors.yellow}${colors.bright}  FUG - Seed Achievements${colors.reset}`);
  console.log(`${colors.yellow}${colors.bright}========================================${colors.reset}`);
  console.log('');

  try {
    log.info(`Seeding ${achievements.length} achievements...`);
    console.log('');

    let created = 0;
    let skipped = 0;

    for (const achievement of achievements) {
      const result = await createAchievement(achievement);
      if (result.created) created++;
      if (result.skipped) skipped++;
    }

    console.log('');
    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    log.success('Seeding complete!');
    console.log(`${colors.dim}  Created: ${created}${colors.reset}`);
    console.log(`${colors.dim}  Skipped: ${skipped}${colors.reset}`);
    console.log(`${colors.dim}  Total: ${achievements.length}${colors.reset}`);
    console.log(`${colors.green}${colors.bright}========================================${colors.reset}`);
    console.log('');

    // Print achievement summary
    console.log(`${colors.bright}Achievement Summary:${colors.reset}`);
    console.log(`${colors.dim}--------------------${colors.reset}`);
    console.log('');
    console.log(`  ${colors.cyan}Code${colors.reset}              ${colors.cyan}Name${colors.reset}              ${colors.cyan}Points${colors.reset}`);
    console.log(`  ${colors.dim}----              ----              ------${colors.reset}`);
    for (const a of achievements) {
      const codeStr = a.code.padEnd(18);
      const nameStr = a.name.padEnd(18);
      console.log(`  ${codeStr}${nameStr}${a.points}`);
    }
    console.log('');
    console.log(`  ${colors.bright}Total points available: ${achievements.reduce((sum, a) => sum + a.points, 0)}${colors.reset}`);
    console.log('');

  } catch (error) {
    log.error(`Seeding failed: ${error.message}`);
    console.error(error);
    process.exit(1);
  }
}

main();
