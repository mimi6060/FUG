/**
 * Migration: 014_oauth_providers
 * Configure OAuth providers (Google, Apple) via Appwrite Console API
 *
 * This migration requires admin credentials to configure OAuth providers.
 * Credentials are read from environment variables or credential files.
 *
 * Environment variables:
 * - APPWRITE_ADMIN_EMAIL: Admin email for console access
 * - APPWRITE_ADMIN_PASSWORD: Admin password
 * - GOOGLE_CLIENT_ID: Google OAuth client ID
 * - GOOGLE_CLIENT_SECRET: Google OAuth client secret
 * - APPLE_TEAM_ID: Apple Team ID (optional)
 * - APPLE_KEY_ID: Apple Key ID (optional)
 * - APPLE_SERVICE_ID: Apple Service ID (optional)
 * - APPLE_PRIVATE_KEY: Apple private key content (optional)
 */

import { Client } from 'node-appwrite';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '014_oauth_providers',

  /**
   * Load credentials from file or environment
   */
  loadCredentials(log) {
    const credentials = {
      google: { clientId: null, clientSecret: null },
      apple: { teamId: null, keyId: null, serviceId: null, privateKey: null },
    };

    // Try Google credentials from env first, then file
    if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
      credentials.google.clientId = process.env.GOOGLE_CLIENT_ID;
      credentials.google.clientSecret = process.env.GOOGLE_CLIENT_SECRET;
      log.info('Loaded Google credentials from environment');
    } else {
      const googleFile = path.join(setupDir, '.google-credentials');
      if (fs.existsSync(googleFile)) {
        const content = fs.readFileSync(googleFile, 'utf-8');
        const lines = content.split('\n');
        for (const line of lines) {
          const [key, ...valueParts] = line.split('=');
          const value = valueParts.join('=').trim();
          if (key === 'GOOGLE_CLIENT_ID') credentials.google.clientId = value;
          if (key === 'GOOGLE_CLIENT_SECRET') credentials.google.clientSecret = value;
        }
        if (credentials.google.clientId) {
          log.info('Loaded Google credentials from file');
        }
      }
    }

    // Try Apple credentials from env first, then file
    if (process.env.APPLE_TEAM_ID && process.env.APPLE_KEY_ID) {
      credentials.apple.teamId = process.env.APPLE_TEAM_ID;
      credentials.apple.keyId = process.env.APPLE_KEY_ID;
      credentials.apple.serviceId = process.env.APPLE_SERVICE_ID;
      credentials.apple.privateKey = process.env.APPLE_PRIVATE_KEY;
      log.info('Loaded Apple credentials from environment');
    } else {
      const appleFile = path.join(setupDir, '.apple-credentials');
      if (fs.existsSync(appleFile)) {
        const content = fs.readFileSync(appleFile, 'utf-8');
        // Parse the file (handles multiline private key)
        const matches = content.match(/APPLE_(\w+)=("[\s\S]*?"|[^\n]*)/g);
        if (matches) {
          for (const match of matches) {
            const [key, ...valueParts] = match.split('=');
            let value = valueParts.join('=').trim();
            // Remove quotes if present
            if (value.startsWith('"') && value.endsWith('"')) {
              value = value.slice(1, -1);
            }
            if (key === 'APPLE_TEAM_ID') credentials.apple.teamId = value;
            if (key === 'APPLE_KEY_ID') credentials.apple.keyId = value;
            if (key === 'APPLE_SERVICE_ID') credentials.apple.serviceId = value;
            if (key === 'APPLE_PRIVATE_KEY') credentials.apple.privateKey = value;
          }
          if (credentials.apple.teamId) {
            log.info('Loaded Apple credentials from file');
          }
        }
      }
    }

    return credentials;
  },

  /**
   * Load admin credentials from file or environment
   */
  loadAdminCredentials(log) {
    let email = process.env.APPWRITE_ADMIN_EMAIL;
    let password = process.env.APPWRITE_ADMIN_PASSWORD;

    // Try credentials file if env vars not set
    if (!email || !password) {
      const adminFile = path.join(setupDir, '.admin-credentials');
      if (fs.existsSync(adminFile)) {
        const content = fs.readFileSync(adminFile, 'utf-8');
        const lines = content.split('\n');
        for (const line of lines) {
          if (line.startsWith('#')) continue;
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
  },

  /**
   * Create admin session and get session cookie
   */
  async createAdminSession(endpoint, log) {
    const { email, password } = this.loadAdminCredentials(log);

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
      const error = await response.json();
      throw new Error(`Failed to create admin session: ${error.message}`);
    }

    // In Appwrite 1.5+, session secret is in Set-Cookie header, not JSON body
    const setCookie = response.headers.get('set-cookie');
    let sessionSecret = null;

    if (setCookie) {
      // Extract session from cookie: a_session_console=<base64_encoded_json>
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
  },

  /**
   * Configure an OAuth provider
   */
  async configureProvider(endpoint, projectId, sessionSecret, provider, appId, secret, log) {
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
      const error = await response.json();
      throw new Error(`Failed to configure ${provider}: ${error.message}`);
    }

    log.success(`${provider} configured successfully`);
  },

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Load credentials
    const credentials = this.loadCredentials(log);

    // Check if we have any OAuth credentials to configure
    const hasGoogle = credentials.google.clientId && credentials.google.clientSecret;
    const hasApple =
      credentials.apple.teamId &&
      credentials.apple.keyId &&
      credentials.apple.serviceId &&
      credentials.apple.privateKey;

    if (!hasGoogle && !hasApple) {
      log.warn('No OAuth credentials found. Skipping OAuth configuration.');
      log.info('To configure OAuth, create credential files in infrastructure/setup/');
      log.info('  - .google-credentials for Google');
      log.info('  - .apple-credentials for Apple');
      return;
    }

    // Create admin session
    const sessionSecret = await this.createAdminSession(endpoint + '/v1', log);

    // Configure Google
    if (hasGoogle) {
      await this.configureProvider(
        endpoint + '/v1',
        projectId,
        sessionSecret,
        'google',
        credentials.google.clientId,
        credentials.google.clientSecret,
        log
      );
    } else {
      log.warn('Google credentials not found, skipping Google OAuth');
    }

    // Configure Apple
    if (hasApple) {
      // Apple secret format: teamId:keyId:privateKey
      const appleSecret = `${credentials.apple.teamId}:${credentials.apple.keyId}:${credentials.apple.privateKey}`;

      await this.configureProvider(
        endpoint + '/v1',
        projectId,
        sessionSecret,
        'apple',
        credentials.apple.serviceId,
        appleSecret,
        log
      );
    } else {
      log.info('Apple credentials not found, skipping Apple OAuth (optional)');
    }

    log.success('OAuth providers configuration complete');
  },

  /**
   * Reverse the migration (disable OAuth providers)
   */
  async down(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Create admin session
    const sessionSecret = await this.createAdminSession(endpoint + '/v1', log);

    // Disable Google
    try {
      await fetch(`${endpoint}/v1/projects/${projectId}/oauth2`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': 'console',
          Cookie: `a_session_console=${sessionSecret}`,
        },
        body: JSON.stringify({
          provider: 'google',
          appId: '',
          secret: '',
          enabled: false,
        }),
      });
      log.info('Google OAuth disabled');
    } catch (e) {
      log.warn('Could not disable Google OAuth');
    }

    // Disable Apple
    try {
      await fetch(`${endpoint}/v1/projects/${projectId}/oauth2`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': 'console',
          Cookie: `a_session_console=${sessionSecret}`,
        },
        body: JSON.stringify({
          provider: 'apple',
          appId: '',
          secret: '',
          enabled: false,
        }),
      });
      log.info('Apple OAuth disabled');
    } catch (e) {
      log.warn('Could not disable Apple OAuth');
    }

    log.success('OAuth providers disabled');
  },
};
