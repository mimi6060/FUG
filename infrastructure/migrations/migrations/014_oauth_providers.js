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

import path from 'path';
import { fileURLToPath } from 'url';
import {
  loadGoogleCredentials,
  loadAppleCredentials,
  createAdminSession,
  configureOAuthProvider,
  disableOAuthProvider,
} from '../lib/oauth-helpers.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '014_oauth_providers',

  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Load credentials
    const googleCreds = loadGoogleCredentials(setupDir, log);
    const appleCreds = loadAppleCredentials(setupDir, log);

    const hasGoogle = googleCreds.clientId && googleCreds.clientSecret;
    const hasApple =
      appleCreds.teamId && appleCreds.keyId && appleCreds.serviceId && appleCreds.privateKey;

    if (!hasGoogle && !hasApple) {
      log.warn('No OAuth credentials found. Skipping OAuth configuration.');
      log.info('To configure OAuth, create credential files in infrastructure/setup/');
      log.info('  - .google-credentials for Google');
      log.info('  - .apple-credentials for Apple');
      return;
    }

    // Create admin session
    const sessionSecret = await createAdminSession(endpoint + '/v1', setupDir, log);

    // Configure Google
    if (hasGoogle) {
      await configureOAuthProvider(
        endpoint + '/v1',
        projectId,
        sessionSecret,
        'google',
        googleCreds.clientId,
        googleCreds.clientSecret,
        log
      );
    } else {
      log.warn('Google credentials not found, skipping Google OAuth');
    }

    // Configure Apple
    if (hasApple) {
      const appleSecret = `${appleCreds.teamId}:${appleCreds.keyId}:${appleCreds.privateKey}`;
      await configureOAuthProvider(
        endpoint + '/v1',
        projectId,
        sessionSecret,
        'apple',
        appleCreds.serviceId,
        appleSecret,
        log
      );
    } else {
      log.info('Apple credentials not found, skipping Apple OAuth (optional)');
    }

    log.success('OAuth providers configuration complete');
  },

  async down(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Create admin session
    const sessionSecret = await createAdminSession(endpoint + '/v1', setupDir, log);

    // Disable providers
    await disableOAuthProvider(endpoint + '/v1', projectId, sessionSecret, 'google', log);
    await disableOAuthProvider(endpoint + '/v1', projectId, sessionSecret, 'apple', log);

    log.success('OAuth providers disabled');
  },
};
