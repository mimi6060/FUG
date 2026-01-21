/**
 * Migration: 010_notifications_schema
 * Created: Add attributes to notifications collection
 *
 * Adds: userId, type, title, body, data, isRead, createdAt
 */

export default {
  name: '010_notifications_schema',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'notifications';

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

    // userId - recipient of the notification
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'userId',
      36,
      true
    );
    log.info('Created attribute: userId');

    // type - notification type
    await databases.createEnumAttribute(
      databaseId,
      collectionId,
      'type',
      [
        'follow',
        'event_invite',
        'event_reminder',
        'event_update',
        'event_cancelled',
        'achievement_unlocked',
        'level_up',
        'nearby_event',
        'system',
      ],
      false,
      'system'
    );
    log.info('Created attribute: type');

    // title
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'title',
      200,
      true
    );
    log.info('Created attribute: title');

    // body
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'body',
      500,
      true
    );
    log.info('Created attribute: body');

    // data - JSON string with additional data (eventId, userId, etc.)
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'data',
      2000,
      false
    );
    log.info('Created attribute: data');

    // imageUrl - notification image
    await databases.createUrlAttribute(
      databaseId,
      collectionId,
      'imageUrl',
      false
    );
    log.info('Created attribute: imageUrl');

    // actionUrl - deep link or URL
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'actionUrl',
      500,
      false
    );
    log.info('Created attribute: actionUrl');

    // isRead
    await databases.createBooleanAttribute(
      databaseId,
      collectionId,
      'isRead',
      false,
      false // default
    );
    log.info('Created attribute: isRead');

    // isPush - was sent as push notification
    await databases.createBooleanAttribute(
      databaseId,
      collectionId,
      'isPush',
      false,
      false // default
    );
    log.info('Created attribute: isPush');

    // createdAt
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // expiresAt - optional expiration
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'expiresAt',
      false
    );
    log.info('Created attribute: expiresAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('expiresAt');

    log.success('Notifications schema attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'notifications';

    const attributes = [
      'userId',
      'type',
      'title',
      'body',
      'data',
      'imageUrl',
      'actionUrl',
      'isRead',
      'isPush',
      'createdAt',
      'expiresAt',
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

    log.success('Notifications schema attributes rolled back');
  },
};
