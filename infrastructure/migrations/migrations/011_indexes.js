/**
 * Migration: 011_indexes
 * Created: Create indexes for all collections
 *
 * Creates necessary indexes for query performance
 */

// Index definitions per collection
const INDEXES = {
  users: [
    { key: 'userId_idx', type: 'unique', attributes: ['userId'] },
    { key: 'email_idx', type: 'unique', attributes: ['email'] },
    { key: 'points_idx', type: 'key', attributes: ['points'], orders: ['DESC'] },
    { key: 'level_idx', type: 'key', attributes: ['level'], orders: ['DESC'] },
    { key: 'createdAt_idx', type: 'key', attributes: ['createdAt'], orders: ['DESC'] },
  ],
  events: [
    { key: 'creatorId_idx', type: 'key', attributes: ['creatorId'] },
    { key: 'status_idx', type: 'key', attributes: ['status'] },
    { key: 'category_idx', type: 'key', attributes: ['category'] },
    { key: 'startDate_idx', type: 'key', attributes: ['startDate'], orders: ['ASC'] },
    { key: 'status_startDate_idx', type: 'key', attributes: ['status', 'startDate'], orders: ['ASC', 'ASC'] },
    { key: 'createdAt_idx', type: 'key', attributes: ['createdAt'], orders: ['DESC'] },
    { key: 'location_idx', type: 'key', attributes: ['locationLat', 'locationLng'] },
  ],
  followers: [
    { key: 'followerId_idx', type: 'key', attributes: ['followerId'] },
    { key: 'followingId_idx', type: 'key', attributes: ['followingId'] },
    { key: 'unique_follow_idx', type: 'unique', attributes: ['followerId', 'followingId'] },
    { key: 'createdAt_idx', type: 'key', attributes: ['createdAt'], orders: ['DESC'] },
  ],
  event_participants: [
    { key: 'eventId_idx', type: 'key', attributes: ['eventId'] },
    { key: 'userId_idx', type: 'key', attributes: ['userId'] },
    { key: 'unique_participant_idx', type: 'unique', attributes: ['eventId', 'userId'] },
    { key: 'status_idx', type: 'key', attributes: ['status'] },
    { key: 'eventId_status_idx', type: 'key', attributes: ['eventId', 'status'] },
    { key: 'joinedAt_idx', type: 'key', attributes: ['joinedAt'], orders: ['DESC'] },
  ],
  achievements: [
    { key: 'achievementId_idx', type: 'unique', attributes: ['achievementId'] },
    { key: 'category_idx', type: 'key', attributes: ['category'] },
    { key: 'tier_idx', type: 'key', attributes: ['tier'] },
  ],
  user_achievements: [
    { key: 'userId_idx', type: 'key', attributes: ['userId'] },
    { key: 'achievementId_idx', type: 'key', attributes: ['achievementId'] },
    { key: 'unique_user_achievement_idx', type: 'unique', attributes: ['userId', 'achievementId'] },
    { key: 'isUnlocked_idx', type: 'key', attributes: ['isUnlocked'] },
    { key: 'userId_isUnlocked_idx', type: 'key', attributes: ['userId', 'isUnlocked'] },
  ],
  notifications: [
    { key: 'userId_idx', type: 'key', attributes: ['userId'] },
    { key: 'type_idx', type: 'key', attributes: ['type'] },
    { key: 'isRead_idx', type: 'key', attributes: ['isRead'] },
    { key: 'userId_isRead_idx', type: 'key', attributes: ['userId', 'isRead'] },
    { key: 'createdAt_idx', type: 'key', attributes: ['createdAt'], orders: ['DESC'] },
    { key: 'userId_createdAt_idx', type: 'key', attributes: ['userId', 'createdAt'], orders: ['ASC', 'DESC'] },
  ],
};

export default {
  name: '011_indexes',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper to wait for index to be available
    const waitForIndex = async (collectionId, indexKey, maxWait = 60000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        try {
          const collection = await databases.getCollection(databaseId, collectionId);
          const index = collection.indexes.find((i) => i.key === indexKey);
          if (index && index.status === 'available') {
            return true;
          }
        } catch (error) {
          // Ignore errors during polling
        }
        await new Promise((resolve) => setTimeout(resolve, 1000));
      }
      log.warn(`Timeout waiting for index ${indexKey} on ${collectionId}`);
      return false;
    };

    for (const [collectionId, indexes] of Object.entries(INDEXES)) {
      log.step(`Creating indexes for ${collectionId}...`);

      for (const index of indexes) {
        try {
          await databases.createIndex(
            databaseId,
            collectionId,
            index.key,
            index.type,
            index.attributes,
            index.orders || []
          );
          log.info(`Created index: ${collectionId}.${index.key}`);
        } catch (error) {
          if (error.code === 409) {
            log.warn(`Index ${collectionId}.${index.key} already exists, skipping...`);
          } else {
            throw error;
          }
        }
      }
    }

    // Wait for critical indexes to be ready
    log.step('Waiting for indexes to be available...');
    await waitForIndex('users', 'userId_idx');
    await waitForIndex('events', 'status_startDate_idx');
    await waitForIndex('followers', 'unique_follow_idx');

    log.success('All indexes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    for (const [collectionId, indexes] of Object.entries(INDEXES)) {
      log.step(`Deleting indexes for ${collectionId}...`);

      for (const index of indexes) {
        try {
          await databases.deleteIndex(databaseId, collectionId, index.key);
          log.info(`Deleted index: ${collectionId}.${index.key}`);
        } catch (error) {
          if (error.code === 404) {
            log.warn(`Index ${collectionId}.${index.key} not found, skipping...`);
          } else {
            throw error;
          }
        }
      }
    }

    log.success('All indexes deleted');
  },
};
