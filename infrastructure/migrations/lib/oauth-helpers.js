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
