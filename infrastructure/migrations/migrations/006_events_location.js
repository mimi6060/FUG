/**
 * Migration: 006_events_location
 * Created: Add location-related attributes to events collection
 *
 * Adds: locationLat, locationLng, locationName, locationAddress
 */

export default {
  name: '006_events_location',

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

    // locationLat - latitude for event location
    await databases.createFloatAttribute(
      databaseId,
      collectionId,
      'locationLat',
      true,
      -90, // min
      90 // max
    );
    log.info('Created attribute: locationLat');

    // locationLng - longitude for event location
    await databases.createFloatAttribute(
      databaseId,
      collectionId,
      'locationLng',
      true,
      -180, // min
      180 // max
    );
    log.info('Created attribute: locationLng');

    // locationName - human-readable location name
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'locationName',
      200,
      true
    );
    log.info('Created attribute: locationName');

    // locationAddress - full address
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'locationAddress',
      500,
      false
    );
    log.info('Created attribute: locationAddress');

    // isOnline - flag for virtual events
    await databases.createBooleanAttribute(
      databaseId,
      collectionId,
      'isOnline',
      false,
      false // default
    );
    log.info('Created attribute: isOnline');

    // onlineUrl - URL for online events
    await databases.createUrlAttribute(
      databaseId,
      collectionId,
      'onlineUrl',
      false
    );
    log.info('Created attribute: onlineUrl');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('onlineUrl');

    log.success('Events location attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'events';

    const attributes = [
      'locationLat',
      'locationLng',
      'locationName',
      'locationAddress',
      'isOnline',
      'onlineUrl',
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

    log.success('Events location attributes rolled back');
  },
};
