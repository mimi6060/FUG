/**
 * Migration: 016_content_reports
 * Created: Content reports collection for DSA compliance
 *
 * Creates the reports collection with:
 * - reporterId: string (required) - User making the report
 * - contentType: enum (required) - Type of content being reported
 * - contentId: string (required) - ID of reported content
 * - category: enum (required) - Category of the report
 * - description: string (optional) - Additional details
 * - status: enum (default: pending) - Current status
 * - moderatorId: string (optional) - Moderator who reviewed
 * - moderatorNote: string (optional) - Internal note
 * - actionTaken: enum (optional) - Action taken
 * - createdAt: datetime (required) - When report was created
 * - reviewedAt: datetime (optional) - When report was reviewed
 */

import { Permission, Role } from 'node-appwrite';

const COLLECTION_ID = 'reports';
const COLLECTION_NAME = 'Content Reports';

export default {
  name: '016_content_reports',

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
          // Users can create reports and read their own
          Permission.create(Role.users()),
          Permission.read(Role.users()),
          // Only admins/team can update and delete
          Permission.update(Role.team('moderators')),
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

    // reporterId - the user making the report
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'reporterId',
      36,
      true
    );
    log.info('Created attribute: reporterId');

    // contentType - type of content being reported
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'contentType',
      ['event', 'user', 'comment'],
      true
    );
    log.info('Created attribute: contentType');

    // contentId - ID of the reported content
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'contentId',
      36,
      true
    );
    log.info('Created attribute: contentId');

    // category - report category (DSA required categories)
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'category',
      ['illegal', 'inappropriate', 'spam', 'other'],
      true
    );
    log.info('Created attribute: category');

    // description - optional details about the report
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'description',
      1000,
      false
    );
    log.info('Created attribute: description');

    // status - current status of the report
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'status',
      ['pending', 'reviewed', 'actioned', 'dismissed'],
      false,
      'pending'
    );
    log.info('Created attribute: status');

    // moderatorId - ID of moderator who reviewed
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'moderatorId',
      36,
      false
    );
    log.info('Created attribute: moderatorId');

    // moderatorNote - internal note from moderator
    await databases.createStringAttribute(
      databaseId,
      COLLECTION_ID,
      'moderatorNote',
      1000,
      false
    );
    log.info('Created attribute: moderatorNote');

    // actionTaken - what action was taken
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'actionTaken',
      ['warning', 'removed', 'banned', 'none'],
      false
    );
    log.info('Created attribute: actionTaken');

    // createdAt - when the report was created
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'createdAt',
      true
    );
    log.info('Created attribute: createdAt');

    // reviewedAt - when the report was reviewed
    await databases.createDatetimeAttribute(
      databaseId,
      COLLECTION_ID,
      'reviewedAt',
      false
    );
    log.info('Created attribute: reviewedAt');

    // Wait for attributes to be available
    log.step('Waiting for attributes to be available...');
    await waitForAttribute('reviewedAt');

    // Create indexes
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_reporterId',
        'key',
        ['reporterId']
      );
      log.info('Created index: idx_reporterId');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_reporterId already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_contentId',
        'key',
        ['contentId']
      );
      log.info('Created index: idx_contentId');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_contentId already exists');
      } else {
        throw error;
      }
    }

    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_status',
        'key',
        ['status']
      );
      log.info('Created index: idx_status');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_status already exists');
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

    // Composite index for filtering by content type and status
    try {
      await databases.createIndex(
        databaseId,
        COLLECTION_ID,
        'idx_contentType_status',
        'key',
        ['contentType', 'status']
      );
      log.info('Created index: idx_contentType_status');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Index idx_contentType_status already exists');
      } else {
        throw error;
      }
    }

    log.success('Content reports schema created');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    // Delete the entire collection (this also deletes all attributes and indexes)
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

    log.success('Content reports schema rolled back');
  },
};
