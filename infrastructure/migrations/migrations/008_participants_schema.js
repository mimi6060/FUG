/**
 * Migration: 008_participants_schema
 * Created: Add attributes to event_participants collection
 *
 * Adds: eventId, userId, status, joinedAt, cancelledAt
 */

export default {
  name: '008_participants_schema',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'event_participants';

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

    // eventId - reference to the event
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'eventId',
      36,
      true
    );
    log.info('Created attribute: eventId');

    // userId - reference to the participant user
    await databases.createStringAttribute(
      databaseId,
      collectionId,
      'userId',
      36,
      true
    );
    log.info('Created attribute: userId');

    // status - enum: pending, confirmed, cancelled, attended
    await databases.createEnumAttribute(
      databaseId,
      collectionId,
      'status',
      ['pending', 'confirmed', 'cancelled', 'attended'],
      false,
      'pending'
    );
    log.info('Created attribute: status');

    // role - organizer, co-organizer, participant
    await databases.createEnumAttribute(
      databaseId,
      collectionId,
      'role',
      ['organizer', 'co-organizer', 'participant'],
      false,
      'participant'
    );
    log.info('Created attribute: role');

    // joinedAt
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'joinedAt',
      true
    );
    log.info('Created attribute: joinedAt');

    // cancelledAt - when the participant cancelled (if applicable)
    await databases.createDatetimeAttribute(
      databaseId,
      collectionId,
      'cancelledAt',
      false
    );
    log.info('Created attribute: cancelledAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('cancelledAt');

    log.success('Event participants schema attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'event_participants';

    const attributes = ['eventId', 'userId', 'status', 'role', 'joinedAt', 'cancelledAt'];

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

    log.success('Event participants schema attributes rolled back');
  },
};
