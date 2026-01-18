/**
 * Migration: 009_achievements_schema
 * Created: Add attributes to achievements and user_achievements collections
 *
 * achievements: id, name, description, icon, category, requiredPoints, tier
 * user_achievements: userId, achievementId, unlockedAt, progress
 */

export default {
  name: '009_achievements_schema',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper function to wait for attribute to be available
    const waitForAttribute = async (collectionId, attrKey, maxWait = 30000) => {
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

    // ========================================
    // ACHIEVEMENTS COLLECTION
    // ========================================
    log.step('Creating achievements attributes...');

    // achievementId - unique identifier
    await databases.createStringAttribute(
      databaseId,
      'achievements',
      'achievementId',
      50,
      true
    );
    log.info('Created attribute: achievementId');

    // name
    await databases.createStringAttribute(
      databaseId,
      'achievements',
      'name',
      100,
      true
    );
    log.info('Created attribute: name');

    // description
    await databases.createStringAttribute(
      databaseId,
      'achievements',
      'description',
      500,
      true
    );
    log.info('Created attribute: description');

    // icon - icon name or URL
    await databases.createStringAttribute(
      databaseId,
      'achievements',
      'icon',
      200,
      true
    );
    log.info('Created attribute: icon');

    // category
    await databases.createEnumAttribute(
      databaseId,
      'achievements',
      'category',
      ['social', 'events', 'engagement', 'milestones', 'special'],
      true,
      'milestones'
    );
    log.info('Created attribute: category');

    // requiredPoints - points needed to unlock
    await databases.createIntegerAttribute(
      databaseId,
      'achievements',
      'requiredPoints',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: requiredPoints');

    // requiredCount - count needed (e.g., 10 events attended)
    await databases.createIntegerAttribute(
      databaseId,
      'achievements',
      'requiredCount',
      false,
      0, // min
      null, // max
      1 // default
    );
    log.info('Created attribute: requiredCount');

    // tier - bronze, silver, gold, platinum
    await databases.createEnumAttribute(
      databaseId,
      'achievements',
      'tier',
      ['bronze', 'silver', 'gold', 'platinum'],
      true,
      'bronze'
    );
    log.info('Created attribute: tier');

    // isHidden - secret achievements
    await databases.createBooleanAttribute(
      databaseId,
      'achievements',
      'isHidden',
      false,
      false // default
    );
    log.info('Created attribute: isHidden');

    await waitForAttribute('achievements', 'isHidden');

    // ========================================
    // USER_ACHIEVEMENTS COLLECTION
    // ========================================
    log.step('Creating user_achievements attributes...');

    // userId
    await databases.createStringAttribute(
      databaseId,
      'user_achievements',
      'userId',
      36,
      true
    );
    log.info('Created attribute: userId');

    // achievementId
    await databases.createStringAttribute(
      databaseId,
      'user_achievements',
      'achievementId',
      50,
      true
    );
    log.info('Created attribute: achievementId');

    // progress - 0 to 100 percentage
    await databases.createIntegerAttribute(
      databaseId,
      'user_achievements',
      'progress',
      false,
      0, // min
      100, // max
      0 // default
    );
    log.info('Created attribute: progress');

    // currentCount - current progress count
    await databases.createIntegerAttribute(
      databaseId,
      'user_achievements',
      'currentCount',
      false,
      0, // min
      null, // max
      0 // default
    );
    log.info('Created attribute: currentCount');

    // isUnlocked
    await databases.createBooleanAttribute(
      databaseId,
      'user_achievements',
      'isUnlocked',
      true,
      false // default
    );
    log.info('Created attribute: isUnlocked');

    // unlockedAt
    await databases.createDatetimeAttribute(
      databaseId,
      'user_achievements',
      'unlockedAt',
      false
    );
    log.info('Created attribute: unlockedAt');

    // createdAt
    await databases.createDatetimeAttribute(
      databaseId,
      'user_achievements',
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('user_achievements', 'createdAt');

    log.success('Achievements schema attributes created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Delete achievements attributes
    const achievementsAttrs = [
      'achievementId',
      'name',
      'description',
      'icon',
      'category',
      'requiredPoints',
      'requiredCount',
      'tier',
      'isHidden',
    ];

    for (const attr of achievementsAttrs) {
      try {
        await databases.deleteAttribute(databaseId, 'achievements', attr);
        log.info(`Deleted attribute: achievements.${attr}`);
      } catch (error) {
        if (error.code === 404) {
          log.warn(`Attribute achievements.${attr} not found, skipping...`);
        } else {
          throw error;
        }
      }
    }

    // Delete user_achievements attributes
    const userAchievementsAttrs = [
      'userId',
      'achievementId',
      'progress',
      'currentCount',
      'isUnlocked',
      'unlockedAt',
      'createdAt',
    ];

    for (const attr of userAchievementsAttrs) {
      try {
        await databases.deleteAttribute(databaseId, 'user_achievements', attr);
        log.info(`Deleted attribute: user_achievements.${attr}`);
      } catch (error) {
        if (error.code === 404) {
          log.warn(`Attribute user_achievements.${attr} not found, skipping...`);
        } else {
          throw error;
        }
      }
    }

    log.success('Achievements schema attributes rolled back');
  },
};
