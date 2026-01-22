/**
 * Migration: 022_messaging_provider
 * Created: 2026-01-22
 *
 * Configure FCM and APNs messaging providers in Appwrite.
 *
 * Reads credentials from:
 *   - Firebase: infrastructure/setup/firebase-service-account.json
 *   - APNs: infrastructure/setup/.apns-credentials + .p8 file
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

      await verifyFcmTokenAttribute(databases, config.databaseId, log);
      return;
    }

    // Create admin session to create API key
    let sessionSecret;
    try {
      sessionSecret = await createAdminSession(endpoint, setupDir, log);
    } catch (e) {
      log.error(`Failed to create admin session: ${e.message}`);
      throw e;
    }

    // Create API key with providers scopes
    log.info('Creating API key with providers scopes...');
    const apiKey = await createProvidersApiKey(endpoint, projectId, sessionSecret, log);

    // Configure FCM if credentials available
    if (hasFcm) {
      try {
        await configureFcmProvider(endpoint, projectId, apiKey, fcmCreds, log);
        if (fcmCreds.serviceAccountJson) {
          log.info(`FCM Project: ${fcmCreds.serviceAccountJson.project_id}`);
        }
      } catch (e) {
        if (e.message.includes('already exists')) {
          log.info('FCM provider already configured');
        } else {
          log.error(`FCM configuration failed: ${e.message}`);
        }
      }
    } else {
      log.info('FCM credentials not found, skipping Android push configuration');
    }

    // Configure APNs if credentials available
    if (hasApns) {
      try {
        await configureApnsProvider(endpoint, projectId, apiKey, apnsCreds, log);
        log.info(`APNs Key ID: ${apnsCreds.keyId}`);
        log.info(`APNs Team ID: ${apnsCreds.teamId}`);
        log.info(`APNs Bundle ID: ${apnsCreds.bundleId || '(not set)'}`);
      } catch (e) {
        if (e.message.includes('already exists')) {
          log.info('APNs provider already configured');
        } else {
          log.error(`APNs configuration failed: ${e.message}`);
        }
      }
    } else {
      log.info('APNs credentials not found, skipping iOS push configuration');
    }

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
      const apiKey = await createProvidersApiKey(endpoint, projectId, sessionSecret, log);

      // Delete FCM provider
      await deleteMessagingProvider(endpoint, projectId, apiKey, 'fcm-provider', log);

      // Delete APNs provider
      await deleteMessagingProvider(endpoint, projectId, apiKey, 'apns-provider', log);

    } catch (e) {
      log.warn(`Rollback warning: ${e.message}`);
      log.info('Manual cleanup may be required in Appwrite Console');
    }
  },
};

/**
 * Create or get API key with providers scopes
 */
async function createProvidersApiKey(endpoint, projectId, sessionSecret, log) {
  const keyName = 'Messaging Providers Migration Key';

  // Try to create new key
  const response = await fetch(`${endpoint}/projects/${projectId}/keys`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': 'console',
      Cookie: `a_session_console=${sessionSecret}`,
    },
    body: JSON.stringify({
      name: keyName,
      scopes: ['providers.read', 'providers.write'],
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(`Failed to create API key: ${error.message || response.status}`);
  }

  const key = await response.json();
  log.success('API key created with providers scopes');
  return key.secret;
}

/**
 * Configure FCM messaging provider
 */
async function configureFcmProvider(endpoint, projectId, apiKey, credentials, log) {
  log.info('Configuring FCM messaging provider...');

  let requestBody;
  if (credentials.serviceAccountJson) {
    log.info('Using FCM V1 API with service account');
    requestBody = {
      providerId: 'fcm-provider',
      name: 'FCM Push Notifications',
      serviceAccountJSON: credentials.serviceAccountJson,
      enabled: true,
    };
  } else if (credentials.serverKey) {
    log.warn('Using legacy FCM API (deprecated)');
    requestBody = {
      providerId: 'fcm-provider',
      name: 'FCM Push Notifications',
      serverKey: credentials.serverKey,
      enabled: true,
    };
  } else {
    throw new Error('No FCM credentials available');
  }

  const response = await fetch(`${endpoint}/messaging/providers/fcm`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    if (response.status === 409) {
      // Provider exists, update it
      log.info('FCM provider already exists, updating...');
      const updateBody = { ...requestBody };
      delete updateBody.providerId;

      const updateResponse = await fetch(`${endpoint}/messaging/providers/fcm/fcm-provider`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
        body: JSON.stringify(updateBody),
      });

      if (!updateResponse.ok) {
        const error = await updateResponse.json().catch(() => ({}));
        throw new Error(`Failed to update FCM provider: ${error.message || updateResponse.status}`);
      }
      log.success('FCM provider updated');
      return;
    }

    const error = await response.json().catch(() => ({}));
    throw new Error(`Failed to create FCM provider: ${error.message || response.status}`);
  }

  log.success('FCM provider configured');
}

/**
 * Configure APNs messaging provider
 */
async function configureApnsProvider(endpoint, projectId, apiKey, credentials, log) {
  log.info('Configuring APNs messaging provider...');

  const requestBody = {
    providerId: 'apns-provider',
    name: 'APNs Push Notifications',
    authKey: credentials.authKey,
    authKeyId: credentials.keyId,
    teamId: credentials.teamId,
    bundleId: credentials.bundleId || 'com.fug.app',
    enabled: true,
  };

  const response = await fetch(`${endpoint}/messaging/providers/apns`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      'X-Appwrite-Key': apiKey,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    if (response.status === 409) {
      log.info('APNs provider already exists, updating...');
      const updateBody = { ...requestBody };
      delete updateBody.providerId;

      const updateResponse = await fetch(`${endpoint}/messaging/providers/apns/apns-provider`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
        body: JSON.stringify(updateBody),
      });

      if (!updateResponse.ok) {
        const error = await updateResponse.json().catch(() => ({}));
        throw new Error(`Failed to update APNs provider: ${error.message || updateResponse.status}`);
      }
      log.success('APNs provider updated');
      return;
    }

    const error = await response.json().catch(() => ({}));
    throw new Error(`Failed to create APNs provider: ${error.message || response.status}`);
  }

  log.success('APNs provider configured');
}

/**
 * Delete a messaging provider
 */
async function deleteMessagingProvider(endpoint, projectId, apiKey, providerId, log) {
  try {
    const response = await fetch(`${endpoint}/messaging/providers/${providerId}`, {
      method: 'DELETE',
      headers: {
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
      },
    });

    if (response.ok || response.status === 404) {
      log.info(`${providerId} deleted`);
    } else {
      log.warn(`Could not delete ${providerId}`);
    }
  } catch (e) {
    log.warn(`Could not delete ${providerId}: ${e.message}`);
  }
}

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
