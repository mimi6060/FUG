/**
 * Migration: 005_events_base
 * Created: Add base attributes to events collection
 *
 * Adds: creatorId, title, description, status, category, maxParticipants,
 *       participantCount, startDate, endDate, createdAt, updatedAt
 */

export default {
  name: '005_events_base',

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

    // creatorId - links to user who created the event
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'creatorId',
      36,
      true
    );
    log.info('Created attribute: creatorId');

    // title
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'title',
      200,
      true
    );
    log.info('Created attribute: title');

    // description
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'description',
      2000,
      false
    );
    log.info('Created attribute: description');

    // status - enum: draft, published, cancelled, completed
    await databases.createEnumAttribute(
      databaseId,
      collectionId,
      'status',
      ['draft', 'published', 'cancelled', 'completed'],
      true,
      'draft'
    );
    log.info('Created attribute: status');

    // category
    await databases.createEnumAttribute(
      databaseId,
      collectionId,
      'category',
      ['sport', 'music', 'food', 'tech', 'art', 'social', 'education', 'other'],
      true,
      'other'
    );
    log.info('Created attribute: category');

    // maxParticipants - 0 means unlimited
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'maxParticipants',
      false,
      0, // min
      10000, // max
      0 // default (unlimited)
    );
    log.info('Created attribute: maxParticipants');

    // participantCount - cached count
    await databases.createIntegerAttribute(
      databaseId,
      collectionId,
      'participantCount',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: participantCount');

    // startDate
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'startDate',
      true
    );
    log.info('Created attribute: startDate');

    // endDate
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'endDate',
      false
    );
    log.info('Created attribute: endDate');

    // imageUrl - event cover image
    await databases.createUrlAttribute(
      databaseId,
      collectionId,
      'imageUrl',
      false
    );
    log.info('Created attribute: imageUrl');

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

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('updatedAt');

    log.success('Events base attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'events';

    const attributes = [
      'creatorId',
      'title',
      'description',
      'status',
      'category',
      'maxParticipants',
      'participantCount',
      'startDate',
      'endDate',
      'imageUrl',
      'createdAt',
      'updatedAt',
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

    log.success('Events base attributes rolled back');
  },
};
