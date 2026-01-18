/**
 * Migration: 004_users_location
 * Created: Add location-related attributes to users collection
 *
 * Adds: locationLat, locationLng, notificationRadius, fcmToken
 */

export default {
  name: '004_users_location',

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

    // locationLat - latitude for user location
    await databases.createFloatAttribute(
      databaseId,
      collectionId,
      'locationLat',
      false,
      -90, // min
      90 // max
    );
    log.info('Created attribute: locationLat');

    // locationLng - longitude for user location
    await databases.createFloatAttribute(
      databaseId,
      collectionId,
      'locationLng',
      false,
      -180, // min
      180 // max
    );
    log.info('Created attribute: locationLng');

    // notificationRadius - radius in km for event notifications
    await databases.createFloatAttribute(
      databaseId,
      collectionId,
      'notificationRadius',
      false,
      0, // min
      100, // max
      10 // default 10km
    );
    log.info('Created attribute: notificationRadius');

    // fcmToken - Firebase Cloud Messaging token for push notifications
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'fcmToken',
      500,
      false
    );
    log.info('Created attribute: fcmToken');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('fcmToken');

    log.success('Users location attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'users';

    const attributes = ['locationLat', 'locationLng', 'notificationRadius', 'fcmToken'];

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

    log.success('Users location attributes rolled back');
  },
};
