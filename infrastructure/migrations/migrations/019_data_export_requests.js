/**
 * Migration: 019_data_export_requests
 * Created: Data export requests collection for RGPD Article 20 compliance
 *
 * Tracks user data export requests with status and download links.
 */

import { Permission, Role } from 'node-appwrite';

const COLLECTION_ID = 'data_export_requests';
const COLLECTION_NAME = 'Data Export Requests';

export default {
  name: '019_data_export_requests',

  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    const waitForAttribute = async (attrKey, maxWait = 30000) => {
      const start = Date.now();
      while (Date.now() - start < maxWait) {
        const collection = await databases.getCollection(databaseId, COLLECTION_ID);
        const attr = collection.attributes.find((a) => a.key === attrKey);
        if (attr && attr.status === 'available') return true;
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
          Permission.read(Role.users()),
          Permission.create(Role.users()),
          Permission.update(Role.users()),
          Permission.delete(Role.users()),
        ]
      );
      log.info(`Created collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code === 409) {
        log.warn(`Collection ${COLLECTION_NAME} already exists`);
      } else {
        throw error;
      }
    }

    // userId - the user requesting the export
    await databases.createStringAttribute(databaseId, COLLECTION_ID, 'userId', 36, true);
    log.info('Created attribute: userId');

    // requestedAt - when the export was requested
    await databases.createDatetimeAttribute(databaseId, COLLECTION_ID, 'requestedAt', true);
    log.info('Created attribute: requestedAt');

    // status - current status of the export
    await databases.createEnumAttribute(
      databaseId,
      COLLECTION_ID,
      'status',
      ['pending', 'completed', 'failed'],
      false,
      'pending'
    );
    log.info('Created attribute: status');

    // downloadUrl - URL to download the export file
    await databases.createUrlAttribute(databaseId, COLLECTION_ID, 'downloadUrl', false);
    log.info('Created attribute: downloadUrl');

    // fileId - ID of the file in storage
    await databases.createStringAttribute(databaseId, COLLECTION_ID, 'fileId', 36, false);
    log.info('Created attribute: fileId');

    // expiresAt - when the download link expires
    await databases.createDatetimeAttribute(databaseId, COLLECTION_ID, 'expiresAt', false);
    log.info('Created attribute: expiresAt');

    // completedAt - when the export was completed
    await databases.createDatetimeAttribute(databaseId, COLLECTION_ID, 'completedAt', false);
    log.info('Created attribute: completedAt');

    // errorMessage - error message if export failed
    await databases.createStringAttribute(databaseId, COLLECTION_ID, 'errorMessage', 500, false);
    log.info('Created attribute: errorMessage');

    // Wait for attributes to be available
    log.step('Waiting for attributes...');
    await waitForAttribute('errorMessage');

    // Create indexes
    try {
      await databases.createIndex(databaseId, COLLECTION_ID, 'idx_userId', 'key', ['userId']);
      log.info('Created index: idx_userId');
    } catch (error) {
      if (error.code !== 409) throw error;
    }

    try {
      await databases.createIndex(databaseId, COLLECTION_ID, 'idx_userId_status', 'key', ['userId', 'status']);
      log.info('Created index: idx_userId_status');
    } catch (error) {
      if (error.code !== 409) throw error;
    }

    try {
      await databases.createIndex(databaseId, COLLECTION_ID, 'idx_requestedAt', 'key', ['requestedAt'], ['DESC']);
      log.info('Created index: idx_requestedAt');
    } catch (error) {
      if (error.code !== 409) throw error;
    }

    log.success('Data export requests schema created');
  },

  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    try {
      await databases.deleteCollection(databaseId, COLLECTION_ID);
      log.info(`Deleted collection: ${COLLECTION_NAME}`);
    } catch (error) {
      if (error.code !== 404) throw error;
    }
    log.success('Data export requests schema rolled back');
  },
};
