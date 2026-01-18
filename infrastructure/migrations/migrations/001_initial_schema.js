/**
 * Migration: 001_initial_schema
 * Created: Initial migration
 *
 * Creates the base collections for the FUG application.
 * This migration only creates collections without attributes.
 */

import { Permission, Role } from 'node-appwrite';

// Collection definitions
const COLLECTIONS = [
  {
    id: 'users',
    name: 'Users',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
    ],
  },
  {
    id: 'events',
    name: 'Events',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
  },
  {
    id: 'followers',
    name: 'Followers',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.delete(Role.users()),
    ],
  },
  {
    id: 'event_participants',
    name: 'Event Participants',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
  },
  {
    id: 'achievements',
    name: 'Achievements',
    permissions: [
      Permission.read(Role.any()),
    ],
  },
  {
    id: 'user_achievements',
    name: 'User Achievements',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
    ],
  },
  {
    id: 'notifications',
    name: 'Notifications',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
  },
];

export default {
  name: '001_initial_schema',

  /**
   * Run the migration - create all base collections
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    for (const collection of COLLECTIONS) {
      try {
        await databases.createCollection(
          databaseId,
          collection.id,
          collection.name,
          collection.permissions
        );
        log.info(`Created collection: ${collection.name}`);
      } catch (error) {
        if (error.code === 409) {
          log.warn(`Collection ${collection.name} already exists, skipping...`);
        } else {
          throw error;
        }
      }
    }

    log.success('Initial schema created with 7 collections');
  },

  /**
   * Reverse the migration - delete all collections
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Delete in reverse order to handle potential dependencies
    const collectionsReversed = [...COLLECTIONS].reverse();

    for (const collection of collectionsReversed) {
      try {
        await databases.deleteCollection(databaseId, collection.id);
        log.info(`Deleted collection: ${collection.name}`);
      } catch (error) {
        if (error.code === 404) {
          log.warn(`Collection ${collection.name} not found, skipping...`);
        } else {
          throw error;
        }
      }
    }

    log.success('Initial schema rolled back');
  },
};
