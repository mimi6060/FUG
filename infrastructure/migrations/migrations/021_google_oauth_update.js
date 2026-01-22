/**
 * Migration: 021_google_oauth_update
 * Created: 2026-01-22
 *
 * Configure Google OAuth provider in Appwrite.
 * Reads credentials from:
 *   - Environment: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET
 *   - Or file: infrastructure/setup/.google-credentials
 *
 * Requires admin credentials:
 *   - APPWRITE_ADMIN_EMAIL
 *   - APPWRITE_ADMIN_PASSWORD
 *   - Or file: infrastructure/setup/.admin-credentials
 */

import path from 'path';
import { fileURLToPath } from 'url';
import {
  loadGoogleCredentials,
  createAdminSession,
  configureOAuthProvider,
  disableOAuthProvider,
} from '../lib/oauth-helpers.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '021_google_oauth_update',

  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Load credentials
    const { clientId, clientSecret } = loadGoogleCredentials(setupDir, log);

    if (!clientId || !clientSecret) {
      log.warn('Google credentials not found. Skipping Google OAuth configuration.');
      log.info('To configure, create infrastructure/setup/.google-credentials with:');
      log.info('  GOOGLE_CLIENT_ID=your_client_id');
      log.info('  GOOGLE_CLIENT_SECRET=your_client_secret');
      return;
    }

    // Create admin session
    const sessionSecret = await createAdminSession(endpoint + '/v1', setupDir, log);

    // Configure Google OAuth
    await configureOAuthProvider(
      endpoint + '/v1',
      projectId,
      sessionSecret,
      'google',
      clientId,
      clientSecret,
      log
    );

    log.info(`Client ID: ${clientId.substring(0, 20)}...`);
  },

  async down(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Create admin session
    const sessionSecret = await createAdminSession(endpoint + '/v1', setupDir, log);

    // Disable Google OAuth
    await disableOAuthProvider(endpoint + '/v1', projectId, sessionSecret, 'google', log);
  },
};
