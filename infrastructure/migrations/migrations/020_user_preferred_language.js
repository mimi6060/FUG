/**
 * Migration: Add preferredLanguage attribute to users collection
 * MOD-010: Internationalization - Store user language preference
 *
 * This attribute stores the user's preferred language code (fr, en, nl)
 * Used to persist language choice across devices and sessions
 */

export const up = async (db, appwrite) => {
  const { databases } = appwrite;

  console.log('Adding preferredLanguage attribute to users collection...');

  try {
    await databases.createStringAttribute(
      db,
      'users',
      'preferredLanguage',
      2, // Max length for language code (fr, en, nl)
      false, // Not required - null means use system default
      null, // No default
      false // Not array
    );

    console.log('preferredLanguage attribute created successfully');

    // Wait for attribute to be available
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Create index for potential filtering by language
    await databases.createIndex(
      db,
      'users',
      'idx_preferredLanguage',
      'key',
      ['preferredLanguage'],
      ['ASC']
    );

    console.log('Index on preferredLanguage created');
  } catch (error) {
    if (error.code === 409) {
      console.log('Attribute already exists, skipping...');
    } else {
      throw error;
    }
  }
};

export const down = async (db, appwrite) => {
  const { databases } = appwrite;

  console.log('Removing preferredLanguage attribute from users collection...');

  try {
    await databases.deleteIndex(db, 'users', 'idx_preferredLanguage');
    console.log('Index removed');
  } catch (error) {
    console.log('Index removal failed or not found:', error.message);
  }

  try {
    await databases.deleteAttribute(db, 'users', 'preferredLanguage');
    console.log('preferredLanguage attribute removed');
  } catch (error) {
    console.log('Attribute removal failed or not found:', error.message);
  }
};
