/**
 * Migration: 007_followers_schema
 * Created: Add attributes to followers collection
 *
 * Adds: followerId, followingId, createdAt
 */

export default {
  name: '007_followers_schema',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'followers';

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

    // followerId - the user who is following
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'followerId',
      36,
      true
    );
    log.info('Created attribute: followerId');

    // followingId - the user being followed
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'followingId',
      36,
      true
    );
    log.info('Created attribute: followingId');

    // createdAt
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('createdAt');

    log.success('Followers schema attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'followers';

    const attributes = ['followerId', 'followingId', 'createdAt'];

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

    log.success('Followers schema attributes rolled back');
  },
};
