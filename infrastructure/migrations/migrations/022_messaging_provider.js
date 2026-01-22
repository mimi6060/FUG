/**
 * Migration: 022_messaging_provider
 * Created: 2026-01-22
 *
 * Configure FCM and APNs messaging providers in Appwrite.
 *
 * Reads credentials from:
 *   - Environment: FCM_SERVER_KEY, APNS_KEY_ID, APNS_TEAM_ID, etc.
 *   - Or files: infrastructure/setup/.fcm-credentials, .apns-credentials
 *
 * Requires admin credentials:
 *   - APPWRITE_ADMIN_EMAIL
 *   - APPWRITE_ADMIN_PASSWORD
 *   - Or file: infrastructure/setup/.admin-credentials
 */

import path from 'path';
import { fileURLToPath } from 'url';
import {
  createAdminSession,
  loadFcmCredentials,
  loadApnsCredentials,
  configureFcmProvider,
  configureApnsProvider,
  disableMessagingProvider,
} from '../lib/oauth-helpers.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '022_messaging_provider',

  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '') + '/v1';
    const projectId = config.projectId;

    log.info('='.repeat(60));
    log.info('Migration 022: Configuring Push Notification Providers');
    log.info('='.repeat(60));

    // Load credentials
    const fcmCreds = loadFcmCredentials(setupDir, log);
    const apnsCreds = loadApnsCredentials(setupDir, log);

    const hasFcm = !!(fcmCreds.serviceAccountJson || fcmCreds.serverKey);
    const hasApns = !!(apnsCreds.keyId && apnsCreds.teamId && apnsCreds.authKey);

    if (!hasFcm && !hasApns) {
      log.warn('No messaging credentials found. Skipping provider configuration.');
      log.info('');
      log.info('To configure FCM (Android), place your Firebase service account JSON:');
      log.info('  infrastructure/setup/firebase-service-account.json');
      log.info('  (Download from Firebase Console > Project Settings > Service Accounts)');
      log.info('');
      log.info('To configure APNs (iOS), create infrastructure/setup/.apns-credentials:');
      log.info('  APNS_KEY_ID=your_key_id');
      log.info('  APNS_TEAM_ID=your_team_id');
      log.info('  APNS_BUNDLE_ID=your.app.bundle.id');
      log.info('And place your .p8 auth key file in infrastructure/setup/');
      log.info('');

      // Verify fcmToken attribute exists in users collection
      await verifyFcmTokenAttribute(databases, config.databaseId, log);
      return;
    }

    // Create admin session
    let sessionSecret;
    try {
      sessionSecret = await createAdminSession(endpoint, setupDir, log);
    } catch (e) {
      log.error(`Failed to create admin session: ${e.message}`);
      log.info('');
      log.info('Ensure admin credentials are configured:');
      log.info('  - Set APPWRITE_ADMIN_EMAIL and APPWRITE_ADMIN_PASSWORD env vars');
      log.info('  - Or create infrastructure/setup/.admin-credentials file');
      throw e;
    }

    // Configure FCM if credentials available
    if (hasFcm) {
      try {
        await configureFcmProvider(
          endpoint,
          projectId,
          sessionSecret,
          fcmCreds,
          log
        );
        if (fcmCreds.serviceAccountJson) {
          log.info(`FCM Project: ${fcmCreds.serviceAccountJson.project_id}`);
        } else {
          log.info(`FCM Server Key: ${fcmCreds.serverKey.substring(0, 20)}...`);
        }
      } catch (e) {
        log.error(`FCM configuration failed: ${e.message}`);
      }
    } else {
      log.info('FCM credentials not found, skipping Android push configuration');
    }

    // Configure APNs if credentials available
    if (hasApns) {
      try {
        await configureApnsProvider(
          endpoint,
          projectId,
          sessionSecret,
          apnsCreds,
          log
        );
        log.info(`APNs Key ID: ${apnsCreds.keyId}`);
        log.info(`APNs Team ID: ${apnsCreds.teamId}`);
        log.info(`APNs Bundle ID: ${apnsCreds.bundleId || '(not set)'}`);
      } catch (e) {
        log.error(`APNs configuration failed: ${e.message}`);
      }
    } else {
      log.info('APNs credentials not found, skipping iOS push configuration');
    }

    // Verify fcmToken attribute exists
    await verifyFcmTokenAttribute(databases, config.databaseId, log);

    log.info('');
    log.info('='.repeat(60));
    log.info('Migration 022 complete');
    log.info('='.repeat(60));
  },

  async down(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '') + '/v1';
    const projectId = config.projectId;

    log.info('Rolling back migration 022: Disabling messaging providers');

    try {
      const sessionSecret = await createAdminSession(endpoint, setupDir, log);

      // Disable FCM provider
      await disableMessagingProvider(endpoint, projectId, sessionSecret, 'fcm', 'fcm-provider', log);

      // Disable APNs provider
      await disableMessagingProvider(endpoint, projectId, sessionSecret, 'apns', 'apns-provider', log);

    } catch (e) {
      log.warn(`Rollback warning: ${e.message}`);
      log.info('Manual cleanup may be required in Appwrite Console');
    }
  },
};

/**
 * Verify that fcmToken attribute exists in users collection
 */
async function verifyFcmTokenAttribute(databases, databaseId, log) {
  try {
    const attributes = await databases.listAttributes(databaseId, 'users');

    const fcmTokenAttr = attributes.attributes.find(
      (attr) => attr.key === 'fcmToken'
    );

    if (fcmTokenAttr) {
      log.success('Verified: fcmToken attribute exists in users collection');
    } else {
      log.warn('WARNING: fcmToken attribute NOT found in users collection');
      log.warn('Please ensure migration 004_users_location was applied');
    }
  } catch (e) {
    log.warn(`Could not verify fcmToken attribute: ${e.message}`);
  }
}
