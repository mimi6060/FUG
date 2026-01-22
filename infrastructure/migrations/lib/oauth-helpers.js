/**
 * Shared OAuth helper functions for migrations
 *
 * Used by migrations that need to configure OAuth providers via Appwrite Console API.
 * Handles credential loading from files/environment and admin session management.
 */

import fs from 'fs';
import path from 'path';

/**
 * Load admin credentials from environment or .admin-credentials file
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object with info/warn methods
 * @returns {{email: string|null, password: string|null}}
 */
export function loadAdminCredentials(setupDir, log) {
  let email = process.env.APPWRITE_ADMIN_EMAIL;
  let password = process.env.APPWRITE_ADMIN_PASSWORD;

  if (!email || !password) {
    const adminFile = path.join(setupDir, '.admin-credentials');
    if (fs.existsSync(adminFile)) {
      const content = fs.readFileSync(adminFile, 'utf-8');
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.startsWith('#') || !line.trim()) continue;
        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').trim();
        if (key === 'APPWRITE_ADMIN_EMAIL') email = value;
        if (key === 'APPWRITE_ADMIN_PASSWORD') password = value;
      }
      if (email && password) {
        log.info('Loaded admin credentials from file');
      }
    }
  }

  return { email, password };
}

/**
 * Load Google OAuth credentials from environment or .google-credentials file
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object with info/warn methods
 * @returns {{clientId: string|null, clientSecret: string|null}}
 */
export function loadGoogleCredentials(setupDir, log) {
  let clientId = process.env.GOOGLE_CLIENT_ID;
  let clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    const googleFile = path.join(setupDir, '.google-credentials');
    if (fs.existsSync(googleFile)) {
      const content = fs.readFileSync(googleFile, 'utf-8');
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.startsWith('#') || !line.trim()) continue;
        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').trim();
        if (key === 'GOOGLE_CLIENT_ID') clientId = value;
        if (key === 'GOOGLE_CLIENT_SECRET') clientSecret = value;
      }
      if (clientId && clientSecret) {
        log.info('Loaded Google credentials from file');
      }
    }
  }

  return { clientId, clientSecret };
}

/**
 * Load Apple OAuth credentials from environment or .apple-credentials file
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object with info/warn methods
 * @returns {{teamId: string|null, keyId: string|null, serviceId: string|null, privateKey: string|null}}
 */
export function loadAppleCredentials(setupDir, log) {
  const credentials = {
    teamId: process.env.APPLE_TEAM_ID,
    keyId: process.env.APPLE_KEY_ID,
    serviceId: process.env.APPLE_SERVICE_ID,
    privateKey: process.env.APPLE_PRIVATE_KEY,
  };

  if (!credentials.teamId || !credentials.keyId) {
    const appleFile = path.join(setupDir, '.apple-credentials');
    if (fs.existsSync(appleFile)) {
      const content = fs.readFileSync(appleFile, 'utf-8');
      const matches = content.match(/APPLE_(\w+)=("[\s\S]*?"|[^\n]*)/g);
      if (matches) {
        for (const match of matches) {
          const [key, ...valueParts] = match.split('=');
          let value = valueParts.join('=').trim();
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.slice(1, -1);
          }
          if (key === 'APPLE_TEAM_ID') credentials.teamId = value;
          if (key === 'APPLE_KEY_ID') credentials.keyId = value;
          if (key === 'APPLE_SERVICE_ID') credentials.serviceId = value;
          if (key === 'APPLE_PRIVATE_KEY') credentials.privateKey = value;
        }
        if (credentials.teamId) {
          log.info('Loaded Apple credentials from file');
        }
      }
    }
  }

  return credentials;
}

/**
 * Create an admin session and return the session secret
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object
 * @returns {Promise<string>} Session secret for cookie
 */
export async function createAdminSession(endpoint, setupDir, log) {
  const { email, password } = loadAdminCredentials(setupDir, log);

  if (!email || !password) {
    throw new Error(
      'Admin credentials required. Set APPWRITE_ADMIN_EMAIL and APPWRITE_ADMIN_PASSWORD environment variables, or ensure .admin-credentials file exists.'
    );
  }

  log.info('Creating admin session...');

  const response = await fetch(`${endpoint}/account/sessions/email`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': 'console',
    },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    let errorMessage = `HTTP ${response.status}`;
    try {
      const error = await response.json();
      errorMessage = error.message || errorMessage;
    } catch {
      // Response was not JSON
    }
    throw new Error(`Failed to create admin session: ${errorMessage}`);
  }

  // Extract session from Set-Cookie header (Appwrite 1.5+)
  const setCookie = response.headers.get('set-cookie');
  let sessionSecret = null;

  if (setCookie) {
    const match = setCookie.match(/a_session_console=([^;]+)/);
    if (match) {
      sessionSecret = match[1];
    }
  }

  // Fallback to JSON body for older Appwrite versions
  if (!sessionSecret) {
    const session = await response.json();
    sessionSecret = session.secret;
  }

  if (!sessionSecret) {
    throw new Error('Could not extract session secret from response');
  }

  log.success('Admin session created');
  return sessionSecret;
}

/**
 * Configure an OAuth provider in Appwrite
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} projectId - Project ID
 * @param {string} sessionSecret - Admin session secret
 * @param {string} provider - Provider name (google, apple)
 * @param {string} appId - App/Client ID
 * @param {string} secret - App/Client secret
 * @param {object} log - Logger object
 */
export async function configureOAuthProvider(endpoint, projectId, sessionSecret, provider, appId, secret, log) {
  log.info(`Configuring ${provider}...`);

  const response = await fetch(`${endpoint}/projects/${projectId}/oauth2`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': 'console',
      Cookie: `a_session_console=${sessionSecret}`,
    },
    body: JSON.stringify({
      provider,
      appId,
      secret,
      enabled: true,
    }),
  });

  if (!response.ok) {
    let errorMessage = `HTTP ${response.status}`;
    try {
      const error = await response.json();
      errorMessage = error.message || errorMessage;
    } catch {
      // Response was not JSON
    }
    throw new Error(`Failed to configure ${provider}: ${errorMessage}`);
  }

  log.success(`${provider} configured successfully`);
}

/**
 * Disable an OAuth provider in Appwrite
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} projectId - Project ID
 * @param {string} sessionSecret - Admin session secret
 * @param {string} provider - Provider name (google, apple)
 * @param {object} log - Logger object
 */
export async function disableOAuthProvider(endpoint, projectId, sessionSecret, provider, log) {
  try {
    await fetch(`${endpoint}/projects/${projectId}/oauth2`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': 'console',
        Cookie: `a_session_console=${sessionSecret}`,
      },
      body: JSON.stringify({
        provider,
        appId: '',
        secret: '',
        enabled: false,
      }),
    });
    log.info(`${provider} OAuth disabled`);
  } catch (e) {
    log.warn(`Could not disable ${provider} OAuth: ${e.message}`);
  }
}

// ============================================
// MESSAGING HELPERS (FCM / APNs)
// ============================================

/**
 * Load FCM credentials from environment or service account JSON file
 * Supports both legacy server key and new V1 API with service account
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object
 * @returns {{serviceAccountJson: object|null, serverKey: string|null, senderId: string|null}}
 */
export function loadFcmCredentials(setupDir, log) {
  let serviceAccountJson = null;
  let serverKey = process.env.FCM_SERVER_KEY;
  let senderId = process.env.FCM_SENDER_ID;

  // Try to load service account JSON (V1 API - recommended)
  const serviceAccountFile = path.join(setupDir, 'firebase-service-account.json');
  if (fs.existsSync(serviceAccountFile)) {
    try {
      const content = fs.readFileSync(serviceAccountFile, 'utf-8');
      serviceAccountJson = JSON.parse(content);
      log.info('Loaded Firebase service account from JSON file');
    } catch (e) {
      log.warn(`Failed to parse firebase-service-account.json: ${e.message}`);
    }
  }

  // Fallback to legacy credentials file
  if (!serviceAccountJson && !serverKey) {
    const fcmFile = path.join(setupDir, '.fcm-credentials');
    if (fs.existsSync(fcmFile)) {
      const content = fs.readFileSync(fcmFile, 'utf-8');
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.startsWith('#') || !line.trim()) continue;
        const [key, ...valueParts] = line.split('=');
        const value = valueParts.join('=').trim();
        if (key === 'FCM_SERVER_KEY') serverKey = value;
        if (key === 'FCM_SENDER_ID') senderId = value;
      }
      if (serverKey) {
        log.info('Loaded FCM credentials from legacy file');
      }
    }
  }

  return { serviceAccountJson, serverKey, senderId };
}

/**
 * Load APNs credentials from environment or .apns-credentials file
 * @param {string} setupDir - Path to the setup directory
 * @param {object} log - Logger object
 * @returns {{keyId: string|null, teamId: string|null, bundleId: string|null, authKey: string|null}}
 */
export function loadApnsCredentials(setupDir, log) {
  const credentials = {
    keyId: process.env.APNS_KEY_ID,
    teamId: process.env.APNS_TEAM_ID,
    bundleId: process.env.APNS_BUNDLE_ID,
    authKey: process.env.APNS_AUTH_KEY,
  };

  if (!credentials.keyId || !credentials.teamId) {
    const apnsFile = path.join(setupDir, '.apns-credentials');
    if (fs.existsSync(apnsFile)) {
      const content = fs.readFileSync(apnsFile, 'utf-8');
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.startsWith('#') || !line.trim()) continue;
        const [key, ...valueParts] = line.split('=');
        let value = valueParts.join('=').trim();
        // Handle multi-line auth key
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1);
        }
        if (key === 'APNS_KEY_ID') credentials.keyId = value;
        if (key === 'APNS_TEAM_ID') credentials.teamId = value;
        if (key === 'APNS_BUNDLE_ID') credentials.bundleId = value;
        if (key === 'APNS_AUTH_KEY') credentials.authKey = value;
      }

      // Try to load auth key from .p8 file
      if (!credentials.authKey) {
        const p8Files = fs.readdirSync(setupDir).filter(f => f.endsWith('.p8'));
        if (p8Files.length > 0) {
          const p8Path = path.join(setupDir, p8Files[0]);
          credentials.authKey = fs.readFileSync(p8Path, 'utf-8');
          log.info(`Loaded APNs auth key from ${p8Files[0]}`);
        }
      }

      if (credentials.keyId) {
        log.info('Loaded APNs credentials from file');
      }
    }
  }

  return credentials;
}

/**
 * Configure FCM messaging provider in Appwrite
 * Supports both V1 API (service account) and legacy (server key)
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} projectId - Project ID
 * @param {string} sessionSecret - Admin session secret
 * @param {object} credentials - FCM credentials {serviceAccountJson, serverKey, senderId}
 * @param {object} log - Logger object
 */
export async function configureFcmProvider(endpoint, projectId, sessionSecret, credentials, log) {
  log.info('Configuring FCM messaging provider...');

  // Build request body based on available credentials
  let requestBody;
  if (credentials.serviceAccountJson) {
    // V1 API with service account (recommended)
    log.info('Using FCM V1 API with service account');
    requestBody = {
      providerId: 'fcm-provider',
      name: 'FCM Push Notifications',
      serviceAccountJSON: credentials.serviceAccountJson,
      enabled: true,
    };
  } else if (credentials.serverKey) {
    // Legacy API with server key (deprecated)
    log.warn('Using legacy FCM API (deprecated) - consider migrating to service account');
    requestBody = {
      providerId: 'fcm-provider',
      name: 'FCM Push Notifications',
      serverKey: credentials.serverKey,
      enabled: true,
    };
  } else {
    throw new Error('No FCM credentials available');
  }

  // Create FCM provider via Appwrite Messaging API
  const response = await fetch(`${endpoint}/messaging/providers/fcm`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      Cookie: `a_session_console=${sessionSecret}`,
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    // Check if provider already exists
    if (response.status === 409) {
      log.info('FCM provider already exists, updating...');

      // Build update body (same structure without providerId)
      const updateBody = { ...requestBody };
      delete updateBody.providerId;

      const updateResponse = await fetch(`${endpoint}/messaging/providers/fcm/fcm-provider`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          Cookie: `a_session_console=${sessionSecret}`,
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
 * Configure APNs messaging provider in Appwrite
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} projectId - Project ID
 * @param {string} sessionSecret - Admin session secret
 * @param {object} credentials - APNs credentials {keyId, teamId, bundleId, authKey}
 * @param {object} log - Logger object
 */
export async function configureApnsProvider(endpoint, projectId, sessionSecret, credentials, log) {
  log.info('Configuring APNs messaging provider...');

  const response = await fetch(`${endpoint}/messaging/providers/apns`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Appwrite-Project': projectId,
      Cookie: `a_session_console=${sessionSecret}`,
    },
    body: JSON.stringify({
      providerId: 'apns-provider',
      name: 'APNs Push Notifications',
      authKey: credentials.authKey,
      authKeyId: credentials.keyId,
      teamId: credentials.teamId,
      bundleId: credentials.bundleId,
      enabled: true,
    }),
  });

  if (!response.ok) {
    // Check if provider already exists
    if (response.status === 409) {
      log.info('APNs provider already exists, updating...');
      const updateResponse = await fetch(`${endpoint}/messaging/providers/apns/apns-provider`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          Cookie: `a_session_console=${sessionSecret}`,
        },
        body: JSON.stringify({
          name: 'APNs Push Notifications',
          authKey: credentials.authKey,
          authKeyId: credentials.keyId,
          teamId: credentials.teamId,
          bundleId: credentials.bundleId,
          enabled: true,
        }),
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
 * Disable a messaging provider in Appwrite
 * @param {string} endpoint - Appwrite endpoint (with /v1)
 * @param {string} projectId - Project ID
 * @param {string} sessionSecret - Admin session secret
 * @param {string} providerType - Provider type (fcm or apns)
 * @param {string} providerId - Provider ID
 * @param {object} log - Logger object
 */
export async function disableMessagingProvider(endpoint, projectId, sessionSecret, providerType, providerId, log) {
  try {
    await fetch(`${endpoint}/messaging/providers/${providerType}/${providerId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': projectId,
        Cookie: `a_session_console=${sessionSecret}`,
      },
      body: JSON.stringify({
        enabled: false,
      }),
    });
    log.info(`${providerType.toUpperCase()} messaging provider disabled`);
  } catch (e) {
    log.warn(`Could not disable ${providerType} provider: ${e.message}`);
  }
}
