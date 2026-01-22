/**
 * Migration: 023_platforms
 * Created: 2026-01-22
 *
 * Add platforms (Web, Flutter iOS, Flutter Android) to the Appwrite project.
 * This is required for OAuth redirects to work properly.
 */

import path from 'path';
import { fileURLToPath } from 'url';
import { createAdminSession } from '../lib/oauth-helpers.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const setupDir = path.join(__dirname, '../../setup');

export default {
  name: '023_platforms',

  async up(client, databases, log, config) {
    const endpoint = config.endpoint.replace('/v1', '');
    const projectId = config.projectId;

    // Create admin session
    const sessionSecret = await createAdminSession(endpoint + '/v1', setupDir, log);

    const platforms = [
      // Web platform for localhost development
      {
        type: 'web',
        name: 'FUG Web (Development)',
        hostname: 'localhost',
      },
      // Web platform for Docker development (port 8080)
      {
        type: 'web',
        name: 'FUG Web (Docker Dev)',
        hostname: 'localhost:8080',
      },
      // Flutter Web (custom scheme for mobile OAuth callbacks)
      {
        type: 'flutter-web',
        name: 'FUG Flutter Web',
        hostname: 'localhost',
      },
    ];

    for (const platform of platforms) {
      try {
        const response = await fetch(
          `${endpoint}/v1/projects/${projectId}/platforms`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-Appwrite-Project': 'console',
              Cookie: `a_session_console=${sessionSecret}`,
            },
            body: JSON.stringify(platform),
          }
        );

        if (response.ok) {
          log.success(`Platform added: ${platform.name} (${platform.hostname})`);
        } else {
          const error = await response.json();
          if (error.type === 'platform_already_exists') {
            log.info(`Platform already exists: ${platform.name}`);
          } else {
            log.warn(`Failed to add platform ${platform.name}: ${error.message}`);
          }
        }
      } catch (e) {
        log.warn(`Error adding platform ${platform.name}: ${e.message}`);
      }
    }

    log.success('Platforms configuration complete');
  },

  async down(client, databases, log, config) {
    log.info('Platform removal not implemented - remove manually if needed');
  },
};
