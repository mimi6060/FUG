/**
 * Migration: Add preferredLanguage attribute to users collection
 * MOD-010: Internationalization - Store user language preference
 *
 * This attribute stores the user's preferred language code (fr, en, nl)
 * Used to persist language choice across devices and sessions
 */

export default {
  name: '020_user_preferred_language',

  async up(client, databases, log, config) {
    const databaseId = config.databaseId;

    log.info('Adding preferredLanguage attribute to users collection...');

    try {
      await databases.createStringAttribute(
        databaseId,
        'users',
        'preferredLanguage',
        2, // Max length for language code (fr, en, nl)
        false, // Not required - null means use system default
        null, // No default
        false // Not array
      );

      log.success('preferredLanguage attribute created');

      // Wait for attribute to be available
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Create index for potential filtering by language
      await databases.createIndex(
        databaseId,
        'users',
        'idx_preferredLanguage',
        'key',
        ['preferredLanguage'],
        ['ASC']
      );

      log.success('Index on preferredLanguage created');
    } catch (error) {
      if (error.code === 409) {
        log.warn('Attribute already exists, skipping...');
      } else {
        throw error;
      }
    }
  },

  async down(client, databases, log, config) {
    const databaseId = config.databaseId;

    log.info('Removing preferredLanguage attribute from users collection...');

    try {
      await databases.deleteIndex(databaseId, 'users', 'idx_preferredLanguage');
      log.info('Index removed');
    } catch (error) {
      log.warn('Index removal failed or not found: ' + error.message);
    }

    try {
      await databases.deleteAttribute(databaseId, 'users', 'preferredLanguage');
      log.success('preferredLanguage attribute removed');
    } catch (error) {
      log.warn('Attribute removal failed or not found: ' + error.message);
    }
  },
};
