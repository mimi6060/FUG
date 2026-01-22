/**
 * Migration: 018_notification_dsa_types
 * Created: Add DSA-related notification types
 *
 * Adds new notification types required for DSA compliance:
 * - report_received: Confirmation when user submits a report
 * - content_moderated: Notification when user's content is moderated
 * - appeal_decision: Notification of appeal decision
 *
 * Note: This migration deletes and recreates the 'type' enum attribute
 * with the extended list of values.
 */

const COLLECTION_ID = 'notifications';

// All notification types including new DSA types
const ALL_NOTIFICATION_TYPES = [
  // Original types
  'follow',
  'event_invite',
  'event_reminder',
  'event_update',
  'event_cancelled',
  'achievement_unlocked',
  'level_up',
  'nearby_event',
  'system',
  // New DSA compliance types
  'report_received',
  'content_moderated',
  'appeal_decision',
];

// Original types for rollback
const ORIGINAL_NOTIFICATION_TYPES = [
  'follow',
  'event_invite',
  'event_reminder',
  'event_update',
  'event_cancelled',
  'achievement_unlocked',
  'level_up',
  'nearby_event',
  'system',
];

export default {
  name: '018_notification_dsa_types',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper function to wait for attribute to be available or deleted
    const waitForAttributeStatus = async (attrKey, targetStatus, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        try {
          const collection = await databases.getCollection(databaseId, COLLECTION_ID);
          const attr = collection.attributes.find((a) => a.key === attrKey);

          if (targetStatus === 'deleted' && !attr) {
            return true;
          }
          if (attr && attr.status === targetStatus) {
            return true;
          }
        } catch (error) {
          // Collection might not exist yet
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      throw new Error(`Timeout waiting for attribute ${attrKey} to be ${targetStatus}`);
    };

    log.step('Updating notification types for DSA compliance...');

    // Step 1: Delete the existing 'type' attribute
    try {
      await databases.deleteAttribute(databaseId, COLLECTION_ID, 'type');
      log.info('Deleted existing type attribute');

      // Wait for deletion to complete
      await waitForAttributeStatus('type', 'deleted');
      log.info('Attribute deletion confirmed');
    } catch (error) {
      if (error.code === 404) {
        log.warn('Type attribute not found, will create new one');
      } else {
        throw error;
      }
    }

    // Step 2: Create the new 'type' attribute with extended values
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'type',
      ALL_NOTIFICATION_TYPES,
      false,  // not required (has default)
      'system'  // default value
    );
    log.info('Created new type attribute with DSA types');

    // Wait for attribute to be available
    await waitForAttributeStatus('type', 'available');

    log.success('Notification DSA types migration completed');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper function to wait for attribute status
    const waitForAttributeStatus = async (attrKey, targetStatus, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        try {
          const collection = await databases.getCollection(databaseId, COLLECTION_ID);
          const attr = collection.attributes.find((a) => a.key === attrKey);

          if (targetStatus === 'deleted' && !attr) {
            return true;
          }
          if (attr && attr.status === targetStatus) {
            return true;
          }
        } catch (error) {
          // Collection might not exist yet
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      throw new Error(`Timeout waiting for attribute ${attrKey} to be ${targetStatus}`);
    };

    log.step('Rolling back notification DSA types...');

    // Delete current type attribute
    try {
      await databases.deleteAttribute(databaseId, COLLECTION_ID, 'type');
      log.info('Deleted type attribute');
      await waitForAttributeStatus('type', 'deleted');
    } catch (error) {
      if (error.code === 404) {
        log.warn('Type attribute not found');
      } else {
        throw error;
      }
    }

    // Recreate with original values
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'type',
      ORIGINAL_NOTIFICATION_TYPES,
      false,
      'system'
    );
    log.info('Recreated type attribute with original values');

    await waitForAttributeStatus('type', 'available');

    log.success('Notification DSA types rollback completed');
  },
};
