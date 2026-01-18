/**
 * Migration: 003_users_gamification
 * Created: Add gamification attributes to users collection
 *
 * Adds: points, level, followersCount, followingCount
 */

export default {
  name: '003_users_gamification',

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

    // points - gamification points
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'points',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: points');

    // level - user level
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'level',
      false,
      1, // min
      100, // max
      1 // default
    );
    log.info('Created attribute: level');

    // followersCount - cached follower count
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'followersCount',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: followersCount');

    // followingCount - cached following count
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'followingCount',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: followingCount');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('followingCount');

    log.success('Users gamification attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'users';

    const attributes = ['points', 'level', 'followersCount', 'followingCount'];

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

    log.success('Users gamification attributes rolled back');
  },
};
