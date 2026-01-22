/**
 * Migration: 021_google_oauth_update
 * Created: 2026-01-22
 * Type: upgrade
 *
 * Configure Google OAuth provider in Appwrite.
 * Reads credentials from:
 *   - Environment: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
 *   - Or file: infrastructure/setup/.google-credentials
 *
 * Requires admin credentials:
 *   - APPWRITE_ADMIN_EMAIL
 *   - APPWRITE_ADMIN_PASSWORD
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '021_google_oauth_update',
  type: 'upgrade',

  /**
   * Load Google credentials from file or environment
   */
  loadGoogleCredentials(log) {
    let clientId = null;
    let clientSecret = null;

    // Try environment variables first
    if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
      clientId = process.env.GOOGLE_CLIENT_ID;
      clientSecret = process.env.GOOGLE_CLIENT_SECRET;
      log.info('Loaded Google credentials from environment');
    } else {
      // Try credentials file
      const googleFile = path.join(setupDir, '.google-credentials');
      if (fs.existsSync(googleFile)) {
        const content = fs.readFileSync(googleFile, 'utf-8');
        const lines = content.split('\n');
        for (const line of lines) {
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

    // Extract session from Set-Cookie header
    const setCookie = response.headers.get('set-cookie');
    let sessionSecret = null;

    if (setCookie) {
      const match = setCookie.match(/a_session_console=([^;]+)/);
      if (match) {
        sessionSecret = match[1];
      }
    }

    // Fallback to JSON body
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
   * Run the migration - Configure Google OAuth
   */
  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Load credentials
    const { clientId, clientSecret } = this.loadGoogleCredentials(log);

    if (!clientId || !clientSecret) {
      log.warn('Google credentials not found. Skipping Google OAuth configuration.');
      log.info('To configure, create infrastructure/setup/.google-credentials with:');
      log.info('  GOOGLE_CLIENT_ID=your_client_id');
      log.info('  GOOGLE_CLIENT_SECRET=your_client_secret');
      return;
    }

    // Create admin session
    const sessionSecret = await this.createAdminSession(endpoint + '/v1', log);

    // Configure Google OAuth
    log.info('Configuring Google OAuth provider...');

    const response = await fetch(`${endpoint}/v1/projects/${projectId}/oauth2`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': 'console',
        Cookie: `a_session_console=${sessionSecret}`,
      },
      body: JSON.stringify({
        provider: 'google',
        appId: clientId,
        secret: clientSecret,
        enabled: true,
      }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(`Failed to configure Google OAuth: ${error.message}`);
    }

    log.success('Google OAuth provider configured successfully');
    log.info(`Client ID: ${clientId.substring(0, 20)}...`);
  },

  /**
   * Reverse the migration - Disable Google OAuth
   */
  async down(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Create admin session
    const sessionSecret = await this.createAdminSession(endpoint + '/v1', log);

    // Disable Google OAuth
    log.info('Disabling Google OAuth provider...');

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
      log.success('Google OAuth disabled');
    } catch (e) {
      log.warn('Could not disable Google OAuth: ' + e.message);
    }
  },
};
