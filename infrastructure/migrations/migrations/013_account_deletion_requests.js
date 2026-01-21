/**
 * Migration: 013_account_deletion_requests
 * Created: Account deletion requests collection for RGPD compliance
 *
 * Creates the account_deletion_requests collection with:
 * - userId: string (required) - User requesting deletion
 * - requestedAt: datetime (required) - When deletion was requested
 * - scheduledDeletionAt: datetime (required) - When deletion will occur (30 days)
 * - status: enum (required) - pending/cancelled/completed
 * - cancellationReason: string (optional) - Why request was cancelled
 */

import { Permission, Role } from 'node-appwrite';

const COLLECTION_ID = 'account_deletion_requests';
const COLLECTION_NAME = 'Account Deletion Requests';

export default {
  name: '013_account_deletion_requests',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper function to wait for attribute to be available
    const waitForAttribute = async (attrKey, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        const collection = await databases.getCollection(databaseId, COLLECTION_ID);
        const attr = collection.attributes.find((a) => a.key === attrKey);
        if (attr && attr.status === 'available') {
          return true;
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      throw new Error(`Timeout waiting for attribute ${attrKey}`);
    };

    // Create collection
    try {
      await databases.createCollection(
        databaseId,
        COLLECTION_ID,
        COLLECTION_NAME,
        [
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
          Permission.delete(Role.users()),
        ]
      );
      log.info(`Created collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code === 409) {
        log.warn(`Collection ${COLLECTION_NAME} already exists, continuing with attributes...`);
      } else {
        throw error;
      }
    }

    // userId - the user requesting account deletion
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'userId',
      36,
      true
    );
    log.info('Created attribute: userId');

    // requestedAt - when the deletion was requested
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'requestedAt',
      true
    );
    log.info('Created attribute: requestedAt');

    // scheduledDeletionAt - when deletion will occur (30 days after request)
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'scheduledDeletionAt',
      true
    );
    log.info('Created attribute: scheduledDeletionAt');

    // status - current status of the deletion request
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'status',
      ['pending', 'cancelled', 'completed'],
      true,
      'pending'
    );
    log.info('Created attribute: status');

    // cancellationReason - optional reason if request was cancelled
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'cancellationReason',
      500,
      false
    );
    log.info('Created attribute: cancellationReason');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('cancellationReason');

    // Create index on userId for fast lookups
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_userId',
        'key',
        ['userId']
      );
      log.info('Created index: idx_userId');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_userId already exists');
      } else {
        throw error;
      }
    }

    // Create index on status for filtering pending requests
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_status',
        'key',
        ['status']
      );
      log.info('Created index: idx_status');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_status already exists');
      } else {
        throw error;
      }
    }

    // Create composite index for userId + status queries
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_userId_status',
        'key',
        ['userId', 'status']
      );
      log.info('Created index: idx_userId_status');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_userId_status already exists');
      } else {
        throw error;
      }
    }

    // Create index on scheduledDeletionAt for cron job to find expired requests
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_scheduledDeletionAt',
        'key',
        ['scheduledDeletionAt']
      );
      log.info('Created index: idx_scheduledDeletionAt');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_scheduledDeletionAt already exists');
      } else {
        throw error;
      }
    }

    log.success('Account deletion requests schema created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Delete the entire collection (this also deletes all attributes and indexes)
    try {
      await databases.deleteCollection(databaseId, COLLECTION_ID);
      log.info(`Deleted collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code === 404) {
        log.warn(`Collection ${COLLECTION_NAME} not found, skipping...`);
      } else {
        throw error;
      }
    }

    log.success('Account deletion requests schema rolled back');
  },
};
