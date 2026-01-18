/**
 * Migration: 002_users_base_attributes
 * Created: Add base attributes to users collection
 *
 * Adds: userId, name, email, avatar, bio, createdAt, updatedAt
 */

export default {
  name: '002_users_base_attributes',

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

    // userId - links to Appwrite Auth user
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'userId',
      36,
      true
    );
    log.info('Created attribute: userId');

    // name
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'name',
      100,
      true
    );
    log.info('Created attribute: name');

    // email
    await databases.createEmailAttribute(
      databaseId,
      collectionId,
      'email',
      true
    );
    log.info('Created attribute: email');

    // avatar URL
    await databases.createUrlAttribute(
      databaseId,
      collectionId,
      'avatar',
      false
    );
    log.info('Created attribute: avatar');

    // bio
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'bio',
      500,
      false
    );
    log.info('Created attribute: bio');

    // createdAt
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // updatedAt
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'updatedAt',
      true
    );
    log.info('Created attribute: updatedAt');

    // Wait for all attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('updatedAt');

    log.success('Users base attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'users';

    const attributes = ['userId', 'name', 'email', 'avatar', 'bio', 'createdAt', 'updatedAt'];

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

    log.success('Users base attributes rolled back');
  },
};
