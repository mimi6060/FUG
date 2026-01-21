/**
 * Migration: 015_storage_buckets
 * Created: 2026-01-22
 * Type: upgrade
 *
 * Creates storage buckets for user avatars and event images.
 */

import { Storage, Permission, Role } from 'node-appwrite';

const BUCKETS = [
  {
    id: 'avatars',
    name: 'User Avatars',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSizeLimit: 5 * 1024 * 1024, // 5MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },
  {
    id: 'event-images',
    name: 'Event Images',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSizeLimit: 10 * 1024 * 1024, // 10MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },
];

export default {
  name: '015_storage_buckets',
  type: 'upgrade',

  /**
   * Run the migration
   */
  async up(client, databases, log, config, context) {
    const storage = new Storage(client);

    log.info('Creating storage buckets...');

    for (const bucket of BUCKETS) {
      try {
        // Check if bucket exists
        await storage.getBucket(bucket.id);
        log.info(`Bucket '${bucket.id}' already exists, skipping`);
      } catch (error) {
        if (error.code === 404) {
          // Create bucket
          await storage.createBucket(
            bucket.id,
            bucket.name,
            bucket.permissions,
            false, // fileSecurity - use bucket-level permissions
            true, // enabled
            bucket.fileSizeLimit,
            bucket.allowedExtensions,
            bucket.compression,
            bucket.encryption,
            bucket.antivirus
          );
          log.success(`Created bucket: ${bucket.id} (${bucket.name})`);
        } else {
          throw error;
        }
      }
    }

    log.success('Storage buckets migration completed');
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const storage = new Storage(client);

    log.info('Removing storage buckets...');

    // Delete in reverse order
    for (const bucket of [...BUCKETS].reverse()) {
      try {
        await storage.deleteBucket(bucket.id);
        log.success(`Deleted bucket: ${bucket.id}`);
      } catch (error) {
        if (error.code === 404) {
          log.info(`Bucket '${bucket.id}' does not exist, skipping`);
        } else {
          log.warn(`Could not delete bucket '${bucket.id}': ${error.message}`);
        }
      }
    }

    log.success('Storage buckets rollback completed');
  },
};
