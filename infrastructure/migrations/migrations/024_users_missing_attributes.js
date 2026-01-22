/**
 * Migration: 024_users_missing_attributes
 * Created: 2026-01-22
 *
 * Add missing attributes to users collection for Flutter compatibility.
 * These attributes are expected by the Flutter models but were not present in the schema.
 *
 * Adds: location, interests, eventsCreated, eventsAttended, rating, isVerified
 */

export default {
  name: '024_users_missing_attributes',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'users';

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

    // location - city/location text (e.g., "Paris, France")
    await createAttributeSafe(async () => {
      await databases.createStringAttribute(
        databaseId,
        collectionId,
        'location',
        255,
        false // not required
      );
    }, 'location');

    // interests - array of interest strings
    await createAttributeSafe(async () => {
      await databases.createStringAttribute(
        databaseId,
        collectionId,
        'interests',
        100,
        false, // not required
        null, // default
        true // array
      );
    }, 'interests');

    // eventsCreated - counter of events created by user
    await createAttributeSafe(async () => {
      await databases.createIntegerAttribute(
        databaseId,
        collectionId,
        'eventsCreated',
        false,
        0, // min
        null, // max
        0 // default
      );
    }, 'eventsCreated');

    // eventsAttended - counter of events attended by user
    await createAttributeSafe(async () => {
      await databases.createIntegerAttribute(
        databaseId,
        collectionId,
        'eventsAttended',
        false,
        0, // min
        null, // max
        0 // default
      );
    }, 'eventsAttended');

    // rating - average user rating 0-5
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

    // isVerified - verified account flag
    await createAttributeSafe(async () => {
      await databases.createBooleanAttribute(
        databaseId,
        collectionId,
        'isVerified',
        false,
        false // default
      );
    }, 'isVerified');

    // Wait for last attribute to be available
    log.step('Waiting for attributes to be available...');
    try {
      await waitForAttribute('isVerified');
    } catch (e) {
      log.warn('Timeout waiting for isVerified, but migration may still succeed');
    }

    log.success('Users missing attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'users';

    // Delete attributes in reverse order
    const attributes = [
      'isVerified',
      'rating',
      'eventsAttended',
      'eventsCreated',
      'interests',
      'location',
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

    log.success('Users missing attributes rolled back');
  },
};
