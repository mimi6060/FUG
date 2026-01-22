/**
 * Migration: 017_moderation_actions
 * Created: Moderation actions collection for DSA compliance
 *
 * Creates the moderation_actions collection for tracking:
 * - Content moderation decisions
 * - User appeals (DSA requirement)
 * - Transparent moderation history
 *
 * DSA Compliance:
 * - Notification of moderation decisions
 * - Right to appeal within 72 hours
 * - Clear reasoning for decisions
 */

import { Permission, Role } from 'node-appwrite';

const COLLECTION_ID = 'moderation_actions';
const COLLECTION_NAME = 'Moderation Actions';

export default {
  name: '017_moderation_actions',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Helper function to wait for attribute to be available
    const waitForAttribute = async (attrKey, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        const collection = await databases.getCollection(databaseId, COLLECTION_ID);
        const attr = collection.attributes.find((a) => a.key === attrKey);
        if (attr && attr.status === 'available') {
          return true;
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      throw new Error(`Timeout waiting for attribute ${attrKey}`);
    };

    // Create collection
    try {
      await databases.createCollection(
        databaseId,
        COLLECTION_ID,
        COLLECTION_NAME,
        [
          // Users can read their own moderation actions and update for appeals
          Permission.read(Role.users()),
          Permission.update(Role.users()),
          // Only moderators can create and delete
          Permission.create(Role.team('moderators')),
          Permission.delete(Role.team('moderators')),
        ]
      );
      log.info(`Created collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code === 409) {
        log.warn(`Collection ${COLLECTION_NAME} already exists, continuing with attributes...`);
      } else {
        throw error;
      }
    }

    // reportId - linked report (optional, can be proactive moderation)
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'reportId',
      36,
      false
    );
    log.info('Created attribute: reportId');

    // contentType - type of content moderated
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'contentType',
      ['event', 'user', 'comment'],
      true
    );
    log.info('Created attribute: contentType');

    // contentId - ID of the moderated content
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'contentId',
      36,
      true
    );
    log.info('Created attribute: contentId');

    // targetUserId - user being moderated
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'targetUserId',
      36,
      true
    );
    log.info('Created attribute: targetUserId');

    // action - moderation action taken
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'action',
      ['warning', 'content_removed', 'content_hidden', 'account_suspended', 'account_banned'],
      true
    );
    log.info('Created attribute: action');

    // reason - DSA requires clear reasoning
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'reason',
      1000,
      true
    );
    log.info('Created attribute: reason');

    // moderatorId - who took the action
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'moderatorId',
      36,
      true
    );
    log.info('Created attribute: moderatorId');

    // isAppealed - DSA right to appeal
    await databases.createBooleanAttribute(
      databaseId,
      COLLECTION_ID,
      'isAppealed',
      false,
      false
    );
    log.info('Created attribute: isAppealed');

    // appealText - user's appeal explanation
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'appealText',
      2000,
      false
    );
    log.info('Created attribute: appealText');

    // appealedAt - when appeal was submitted
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'appealedAt',
      false
    );
    log.info('Created attribute: appealedAt');

    // appealStatus - status of the appeal
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'appealStatus',
      ['pending', 'accepted', 'rejected'],
      false
    );
    log.info('Created attribute: appealStatus');

    // appealReviewedAt - when appeal was reviewed (DSA: 72h requirement)
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'appealReviewedAt',
      false
    );
    log.info('Created attribute: appealReviewedAt');

    // appealReviewedBy - who reviewed the appeal
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'appealReviewedBy',
      36,
      false
    );
    log.info('Created attribute: appealReviewedBy');

    // appealDecisionReason - DSA requires motivated final decision
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'appealDecisionReason',
      1000,
      false
    );
    log.info('Created attribute: appealDecisionReason');

    // notificationSentAt - when user was notified (DSA requirement)
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'notificationSentAt',
      false
    );
    log.info('Created attribute: notificationSentAt');

    // createdAt - when action was taken
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('createdAt');

    // Create indexes
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_targetUserId',
        'key',
        ['targetUserId']
      );
      log.info('Created index: idx_targetUserId');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_targetUserId already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_reportId',
        'key',
        ['reportId']
      );
      log.info('Created index: idx_reportId');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_reportId already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_action',
        'key',
        ['action']
      );
      log.info('Created index: idx_action');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_action already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_isAppealed',
        'key',
        ['isAppealed']
      );
      log.info('Created index: idx_isAppealed');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_isAppealed already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_appealStatus',
        'key',
        ['appealStatus']
      );
      log.info('Created index: idx_appealStatus');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_appealStatus already exists');
      } else {
        throw error;
      }
    }

    // Composite index for pending appeals (moderator dashboard)
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_isAppealed_appealStatus',
        'key',
        ['isAppealed', 'appealStatus']
      );
      log.info('Created index: idx_isAppealed_appealStatus');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_isAppealed_appealStatus already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_createdAt',
        'key',
        ['createdAt'],
        ['DESC']
      );
      log.info('Created index: idx_createdAt');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_createdAt already exists');
      } else {
        throw error;
      }
    }

    log.success('Moderation actions schema created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Delete the entire collection
    try {
      await databases.deleteCollection(databaseId, COLLECTION_ID);
      log.info(`Deleted collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code === 404) {
        log.warn(`Collection ${COLLECTION_NAME} not found, skipping...`);
      } else {
        throw error;
      }
    }

    log.success('Moderation actions schema rolled back');
  },
};
