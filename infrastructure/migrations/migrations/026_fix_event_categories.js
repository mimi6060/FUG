/**
 * Migration: 026_fix_event_categories
 * Created: 2026-01-22
 *
 * Fix event categories to match CLAUDE.md business specification.
 *
 * OLD categories (from 005_events_base): sport, music, food, tech, art, social, education, other
 * NEW categories (per CLAUDE.md): bar, cafe, restaurant, park, home, other
 *
 * Since there is no production data, we can safely delete and recreate the enum.
 */

const COLLECTION_ID = 'events';

// New categories as defined in CLAUDE.md
const NEW_CATEGORIES = ['bar', 'cafe', 'restaurant', 'park', 'home', 'other'];

// Old categories for rollback
const OLD_CATEGORIES = ['sport', 'music', 'food', 'tech', 'art', 'social', 'education', 'other'];

export default {
  name: '026_fix_event_categories',

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

    log.step('Updating event categories to match CLAUDE.md specification...');

    // Step 1: Delete the existing 'category' attribute
    try {
      await databases.deleteAttribute(databaseId, COLLECTION_ID, 'category');
      log.info('Deleted existing category attribute');

      // Wait for deletion to complete
      await waitForAttributeStatus('category', 'deleted');
      log.info('Attribute deletion confirmed');
    } catch (error) {
      if (error.code === 404) {
        log.warn('Category attribute not found, will create new one');
      } else {
        throw error;
      }
    }

    // Step 2: Create the new 'category' attribute with correct values
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'category',
      NEW_CATEGORIES,
      false, // not required (has default)
      'other' // default value
    );
    log.info(`Created new category attribute with values: ${NEW_CATEGORIES.join(', ')}`);

    // Wait for attribute to be available
    await waitForAttributeStatus('category', 'available');

    log.success('Event categories migration completed');
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

    log.step('Rolling back event categories...');

    // Delete current category attribute
    try {
      await databases.deleteAttribute(databaseId, COLLECTION_ID, 'category');
      log.info('Deleted category attribute');
      await waitForAttributeStatus('category', 'deleted');
    } catch (error) {
      if (error.code === 404) {
        log.warn('Category attribute not found');
      } else {
        throw error;
      }
    }

    // Recreate with original values
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'category',
      OLD_CATEGORIES,
      false,
      'other'
    );
    log.info(`Recreated category attribute with original values: ${OLD_CATEGORIES.join(', ')}`);

    await waitForAttributeStatus('category', 'available');

    log.success('Event categories rollback completed');
  },
};
