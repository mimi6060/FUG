/**
 * Migration: 000_bootstrap_verify
 * Created: 2026-01-22
 * Type: bootstrap
 *
 * Verifies that the bootstrap process completed successfully.
 * This migration only runs on fresh installations and ensures
 * the project, database, and basic configuration are in place.
 */

export default {
  name: '000_bootstrap_verify',

  // Bootstrap migrations only run on fresh installations
  type: 'bootstrap',

  /**
   * Run the migration
   * @param {Client} client - Appwrite client
   * @param {Databases} databases - Appwrite Databases service
   * @param {Object} log - Logger instance
   * @param {Object} config - Environment configuration
   * @param {MigrationContext} context - Context with helper methods
   */
  async up(client, databases, log, config, context) {
    const databaseId = config.databaseId;

    log.info('Verifying bootstrap configuration...');

    // Verify database exists and is accessible
    try {
      const db = await databases.get(databaseId);
      log.success(`Database verified: ${db.name} (${db.$id})`);
    } catch (error) {
      if (error.code === 404) {
        throw new Error(
          `Database '${databaseId}' not found. Run bootstrap.sh first to create the project and database.`
        );
      }
      throw error;
    }

    // Log configuration for verification
    log.info(`Project ID: ${config.projectId}`);
    log.info(`Database ID: ${config.databaseId}`);
    log.info(`Endpoint: ${config.endpoint}`);

    log.success('Bootstrap verification completed');
  },

  /**
   * Reverse the migration (no-op for verification)
   * @param {Client} client - Appwrite client
   * @param {Databases} databases - Appwrite Databases service
   * @param {Object} log - Logger instance
   * @param {Object} config - Environment configuration
   */
  async down(client, databases, log, config) {
    log.info('Bootstrap verification rollback (no-op)');
  },
};
