/**
 * Migration: 025_events_missing_attributes
 * Created: 2026-01-22
 *
 * Add missing attributes to events collection for Flutter compatibility.
 * These attributes are expected by the Flutter models but were not present in the schema.
 *
 * Adds: price, currency, tags, isFeatured, rating, reviewCount
 */

export default {
  name: '025_events_missing_attributes',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'events';

    // Helper function to wait for attribute to be available
    const waitForAttribute = async (attrKey, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        const collection = await databases.getCollection(databaseId, collectionId);
        const attr = collection.attributes.find((a) => a.key === attrKey);
        if (attr && attr.status === 'available') {
          return true;
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      throw new Error(`Timeout waiting for attribute ${attrKey}`);
    };

    // Helper function to create attribute with 409 handling (already exists)
    const createAttributeSafe = async (createFn, attrName) => {
      try {
        await createFn();
        log.info(`Created attribute: ${attrName}`);
      } catch (e) {
        if (e.code === 409) {
          log.info(`Attribute ${attrName} already exists, skipping...`);
        } else {
          throw e;
        }
      }
    };

    // price - price in cents (0 = free)
    await createAttributeSafe(async () => {
      await databases.createIntegerAttribute(
        databaseId,
        collectionId,
        'price',
        false,
        0, // min (no negative prices)
        null, // max
        0 // default (free)
      );
    }, 'price');

    // currency - ISO 4217 currency code (3 chars)
    await createAttributeSafe(async () => {
      await databases.createStringAttribute(
        databaseId,
        collectionId,
        'currency',
        3,
        false,
        'EUR' // default
      );
    }, 'currency');

    // tags - array of free-form tags
    await createAttributeSafe(async () => {
      await databases.createStringAttribute(
        databaseId,
        collectionId,
        'tags',
        50,
        false, // not required
        null, // default
        true // array
      );
    }, 'tags');

    // isFeatured - featured event flag for promoted events
    await createAttributeSafe(async () => {
      await databases.createBooleanAttribute(
        databaseId,
        collectionId,
        'isFeatured',
        false,
        false // default
      );
    }, 'isFeatured');

    // rating - average event rating 0-5
    await createAttributeSafe(async () => {
      await databases.createFloatAttribute(
        databaseId,
        collectionId,
        'rating',
        false,
        0, // min
        5 // max
      );
    }, 'rating');

    // reviewCount - number of reviews for this event
    await createAttributeSafe(async () => {
      await databases.createIntegerAttribute(
        databaseId,
        collectionId,
        'reviewCount',
        false,
        0, // min
        null, // max
        0 // default
      );
    }, 'reviewCount');

    // Wait for last attribute to be available
    log.step('Waiting for attributes to be available...');
    try {
      await waitForAttribute('reviewCount');
    } catch (e) {
      log.warn('Timeout waiting for reviewCount, but migration may still succeed');
    }

    log.success('Events missing attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'events';

    // Delete attributes in reverse order
    const attributes = [
      'reviewCount',
      'rating',
      'isFeatured',
      'tags',
      'currency',
      'price',
    ];

    for (const attr of attributes) {
      try {
        await databases.deleteAttribute(databaseId, collectionId, attr);
        log.info(`Deleted attribute: ${attr}`);
      } catch (error) {
        if (error.code === 404) {
          log.warn(`Attribute ${attr} not found, skipping...`);
        } else {
          throw error;
        }
      }
    }

    log.success('Events missing attributes rolled back');
  },
};
