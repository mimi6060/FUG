/**
 * Migration: 022_messaging_provider
 * Created: 2026-01-22
 *
 * Documentation migration for Appwrite Messaging configuration.
 *
 * Appwrite Messaging enables push notifications via:
 * - FCM (Firebase Cloud Messaging) for Android
 * - APNs (Apple Push Notification service) for iOS
 *
 * IMPORTANT: The actual provider configuration is done via
 * Appwrite Console or CLI, not via API migrations.
 *
 * This migration serves as documentation and verification
 * that the fcmToken attribute exists in the users collection.
 */

export default {
  name: '022_messaging_provider',

  async up(client, databases, log, config) {
    log.info('='.repeat(60));
    log.info('Migration 022: Appwrite Messaging Setup Documentation');
    log.info('='.repeat(60));

    log.info('');
    log.info('PREREQUISITES:');
    log.info('-'.repeat(40));
    log.info('1. fcmToken attribute in users collection (added in migration 004)');
    log.info('');

    log.info('APPWRITE MESSAGING CONFIGURATION:');
    log.info('-'.repeat(40));
    log.info('Configure providers in Appwrite Console > Settings > Messaging:');
    log.info('');

    log.info('FOR FCM (Android):');
    log.info('  1. Go to Firebase Console > Project Settings > Cloud Messaging');
    log.info('  2. Copy the Server Key (Legacy) or Service Account JSON');
    log.info('  3. In Appwrite Console > Messaging > Providers');
    log.info('  4. Add new FCM provider with the credentials');
    log.info('');

    log.info('FOR APNs (iOS):');
    log.info('  1. Go to Apple Developer > Certificates, Identifiers & Profiles');
    log.info('  2. Create an APNs Key (.p8 file)');
    log.info('  3. Note the Key ID and Team ID');
    log.info('  4. In Appwrite Console > Messaging > Providers');
    log.info('  5. Add new APNs provider with:');
    log.info('     - Auth Key (.p8 file)');
    log.info('     - Key ID');
    log.info('     - Team ID');
    log.info('     - Bundle ID (from your app)');
    log.info('');

    log.info('ENVIRONMENT VARIABLES (optional, for CI/CD):');
    log.info('-'.repeat(40));
    log.info('  FCM_SERVER_KEY      - Firebase Server Key');
    log.info('  APNS_KEY_ID         - Apple Key ID');
    log.info('  APNS_TEAM_ID        - Apple Team ID');
    log.info('  APNS_BUNDLE_ID      - iOS App Bundle ID');
    log.info('  APNS_KEY_PATH       - Path to .p8 file');
    log.info('');

    log.info('FLUTTER APP INTEGRATION:');
    log.info('-'.repeat(40));
    log.info('  1. Add firebase_messaging package to pubspec.yaml');
    log.info('  2. Initialize Firebase in main.dart');
    log.info('  3. Use PushNotificationService.registerDevice() after login');
    log.info('  4. Use PushNotificationService.unregisterDevice() on logout');
    log.info('');

    log.info('APPWRITE FUNCTIONS INTEGRATION:');
    log.info('-'.repeat(40));
    log.info('  Functions use Messaging API to send push notifications:');
    log.info('  - follow-user: notifies when someone follows a user');
    log.info('  - join-event: notifies organizer when someone joins');
    log.info('');

    // Verify fcmToken attribute exists in users collection
    try {
      const attributes = await databases.listAttributes(
        config.databaseId,
        'users'
      );

      const fcmTokenAttr = attributes.attributes.find(
        (attr) => attr.key === 'fcmToken'
      );

      if (fcmTokenAttr) {
        log.info('VERIFICATION: fcmToken attribute exists in users collection');
      } else {
        log.warn('WARNING: fcmToken attribute NOT found in users collection');
        log.warn('Please run migration 004_users_location first');
      }
    } catch (e) {
      log.warn(`Could not verify fcmToken attribute: ${e.message}`);
    }

    log.info('');
    log.info('='.repeat(60));
    log.info('Migration 022 complete - Please configure providers manually');
    log.info('='.repeat(60));
  },

  async down(client, databases, log, config) {
    log.info('Migration 022 rollback: No action needed (documentation only)');
    log.info('Note: Provider configuration in Appwrite Console is not affected');
  },
};
