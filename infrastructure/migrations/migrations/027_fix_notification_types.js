/**
 * Migration: 027_fix_notification_types
 * Created: 2026-01-22
 *
 * Synchronize notification types between Flutter and Appwrite.
 *
 * This migration combines all notification types needed:
 * - Original types: follow, event_invite, event_reminder, event_update, event_cancelled,
 *                   achievement_unlocked, level_up, nearby_event, system
 * - Flutter-specific: new_event, new_participant, event_liked, new_comment, direct_message,
 *                     new_follower
 * - DSA compliance: report_received, report_resolved, content_removed, appeal_received,
 *                   appeal_resolved, content_moderated, appeal_decision
 *
 * Note: Using snake_case for Appwrite enum values (Flutter converts to camelCase)
 */

const COLLECTION_ID = 'notifications';

// Complete list of all notification types (union of all sources)
const ALL_NOTIFICATION_TYPES = [
  // Original Appwrite types
  'follow',
  'event_invite',
  'event_reminder',
  'event_update',
  'event_cancelled',
  'achievement_unlocked',
  'level_up',
  'nearby_event',
  'system',
  // Flutter-specific types (snake_case for Appwrite)
  'new_event',
  'new_participant',
  'event_liked',
  'new_comment',
  'direct_message',
  'new_follower',
  // DSA compliance types
  'report_received',
  'report_resolved',
  'content_removed',
  'content_moderated',
  'appeal_received',
  'appeal_resolved',
  'appeal_decision',
];

// Previous types for rollback (from migration 018)
const PREVIOUS_NOTIFICATION_TYPES = [
  'follow',
  'event_invite',
  'event_reminder',
  'event_update',
  'event_cancelled',
  'achievement_unlocked',
  'level_up',
  'nearby_event',
  'system',
  'report_received',
  'content_moderated',
  'appeal_decision',
];

export default {
  name: '027_fix_notification_types',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
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

    log.step('Synchronizing notification types between Flutter and Appwrite...');
    log.info(`New notification types: ${ALL_NOTIFICATION_TYPES.join(', ')}`);

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

    // Step 2: Create the new 'type' attribute with all values
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'type',
      ALL_NOTIFICATION_TYPES,
      false, // not required (has default)
      'system' // default value
    );
    log.info('Created new type attribute with synchronized types');

    // Wait for attribute to be available
    await waitForAttributeStatus('type', 'available');

    log.success('Notification types synchronization completed');
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

    log.step('Rolling back notification types...');

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

    // Recreate with previous values (from migration 018)
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'type',
      PREVIOUS_NOTIFICATION_TYPES,
      false,
      'system'
    );
    log.info('Recreated type attribute with previous values');

    await waitForAttributeStatus('type', 'available');

    log.success('Notification types rollback completed');
  },
};
