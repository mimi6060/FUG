import { Client, Databases, Storage, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: export-user-data
 *
 * RGPD Article 20 - Data Portability
 * Exports all user data in JSON format
 *
 * Payload:
 * {
 *   "userId": "string"  // ID of user requesting export
 * }
 */

const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  FOLLOWERS: 'followers',
  USER_ACHIEVEMENTS: 'user_achievements',
  NOTIFICATIONS: 'notifications',
  DATA_EXPORT_REQUESTS: 'data_export_requests',
};

const STORAGE = {
  EXPORTS_BUCKET: 'data-exports',
};

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const storage = new Storage(client);
  const databaseId = process.env.DATABASE_ID || 'fug-db';

  try {
    const payload = JSON.parse(req.body || '{}');
    const { userId } = payload;

    if (!userId) {
      return res.json({ success: false, error: 'userId parameter is required' }, 400);
    }

    log(`Starting data export for user: ${userId}`);

    // Check for existing pending export
    const existingRequests = await databases.listDocuments(
      databaseId,
      COLLECTIONS.DATA_EXPORT_REQUESTS,
      [Query.equal('userId', userId), Query.equal('status', 'pending'), Query.limit(1)]
    );

    if (existingRequests.documents.length > 0) {
      return res.json({
        success: false,
        error: 'An export request is already pending',
        requestId: existingRequests.documents[0].$id,
      }, 409);
    }

    // Create export request
    const now = new Date().toISOString();
    const exportRequest = await databases.createDocument(
      databaseId,
      COLLECTIONS.DATA_EXPORT_REQUESTS,
      ID.unique(),
      {
        userId,
        requestedAt: now,
        status: 'pending',
        downloadUrl: null,
        expiresAt: null,
        completedAt: null,
        errorMessage: null
      }
    );

    log(`Created export request: ${exportRequest.$id}`);

    try {
      // Collect user data
      const exportData = await collectUserData(databases, databaseId, userId, log);
      const jsonContent = JSON.stringify(exportData, null, 2);
      const jsonBuffer = Buffer.from(jsonContent, 'utf-8');
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const filename = `fug-export-${userId}-${timestamp}.json`;

      // Upload to storage
      const file = await storage.createFile(
        STORAGE.EXPORTS_BUCKET,
        ID.unique(),
        new File([jsonBuffer], filename, { type: 'application/json' })
      );

      log(`Uploaded export file: ${file.$id}`);

      const expiresAt = new Date();
      expiresAt.setHours(expiresAt.getHours() + 24);

      const downloadUrl = `${process.env.APPWRITE_FUNCTION_API_ENDPOINT}/storage/buckets/${STORAGE.EXPORTS_BUCKET}/files/${file.$id}/download?project=${process.env.APPWRITE_FUNCTION_PROJECT_ID}`;

      // Update request with download info
      await databases.updateDocument(
        databaseId,
        COLLECTIONS.DATA_EXPORT_REQUESTS,
        exportRequest.$id,
        {
          status: 'completed',
          downloadUrl,
          fileId: file.$id,
          expiresAt: expiresAt.toISOString(),
          completedAt: new Date().toISOString()
        }
      );

      // Create notification
      await databases.createDocument(
        databaseId,
        COLLECTIONS.NOTIFICATIONS,
        ID.unique(),
        {
          userId,
          type: 'data_export_ready',
          title: 'Your data export is ready',
          message: 'Your personal data export is ready for download. The link will expire in 24 hours.',
          data: JSON.stringify({
            exportRequestId: exportRequest.$id,
            downloadUrl,
            expiresAt: expiresAt.toISOString()
          }),
          read: false,
          createdAt: new Date().toISOString(),
        }
      );

      log(`Data export completed for user: ${userId}`);

      return res.json({
        success: true,
        data: {
          requestId: exportRequest.$id,
          status: 'completed',
          downloadUrl,
          expiresAt: expiresAt.toISOString()
        },
      });

    } catch (exportError) {
      await databases.updateDocument(
        databaseId,
        COLLECTIONS.DATA_EXPORT_REQUESTS,
        exportRequest.$id,
        {
          status: 'failed',
          errorMessage: exportError.message,
          completedAt: new Date().toISOString()
        }
      );
      throw exportError;
    }

  } catch (err) {
    error(`Error in export-user-data: ${err.message}`);
    if (err.code === 404) {
      return res.json({ success: false, error: 'User not found' }, 404);
    }
    return res.json({ success: false, error: 'Internal server error' }, 500);
  }
};

async function collectUserData(databases, databaseId, userId, log) {
  const exportData = {
    exportInfo: {
      exportDate: new Date().toISOString(),
      userId,
      applicationName: 'FUG - Fous-toi Une Guinze',
      dataPortabilityNotice: 'This export contains all your personal data (GDPR Article 20).',
    },
    profile: null,
    eventsCreated: [],
    participations: [],
    followers: [],
    following: [],
    achievements: [],
    notifications: [],
  };

  // Collect profile
  try {
    const userProfile = await databases.getDocument(databaseId, COLLECTIONS.USERS, userId);
    exportData.profile = sanitizeDocument(userProfile);
    log('Collected user profile');
  } catch (e) {
    log(`Profile fetch error: ${e.message}`);
  }

  // Collect events created by user
  try {
    const events = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENTS,
      [Query.equal('creatorId', userId), Query.limit(1000)]
    );
    exportData.eventsCreated = events.documents.map(sanitizeDocument);
    log(`Collected ${events.documents.length} events`);
  } catch (e) {
    log(`Events fetch error: ${e.message}`);
  }

  // Collect participations
  try {
    const participations = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      [Query.equal('userId', userId), Query.limit(1000)]
    );
    exportData.participations = participations.documents.map(sanitizeDocument);
    log(`Collected ${participations.documents.length} participations`);
  } catch (e) {
    log(`Participations fetch error: ${e.message}`);
  }

  // Collect followers (people following this user)
  try {
    const followers = await databases.listDocuments(
      databaseId,
      COLLECTIONS.FOLLOWERS,
      [Query.equal('followingId', userId), Query.limit(1000)]
    );
    exportData.followers = followers.documents.map(sanitizeDocument);
    log(`Collected ${followers.documents.length} followers`);
  } catch (e) {
    log(`Followers fetch error: ${e.message}`);
  }

  // Collect following (people this user follows)
  try {
    const following = await databases.listDocuments(
      databaseId,
      COLLECTIONS.FOLLOWERS,
      [Query.equal('followerId', userId), Query.limit(1000)]
    );
    exportData.following = following.documents.map(sanitizeDocument);
    log(`Collected ${following.documents.length} following`);
  } catch (e) {
    log(`Following fetch error: ${e.message}`);
  }

  // Collect achievements
  try {
    const achievements = await databases.listDocuments(
      databaseId,
      COLLECTIONS.USER_ACHIEVEMENTS,
      [Query.equal('userId', userId), Query.limit(1000)]
    );
    exportData.achievements = achievements.documents.map(sanitizeDocument);
    log(`Collected ${achievements.documents.length} achievements`);
  } catch (e) {
    log(`Achievements fetch error: ${e.message}`);
  }

  // Collect notifications (last 100)
  try {
    const notifications = await databases.listDocuments(
      databaseId,
      COLLECTIONS.NOTIFICATIONS,
      [Query.equal('userId', userId), Query.orderDesc('createdAt'), Query.limit(100)]
    );
    exportData.notifications = notifications.documents.map(sanitizeDocument);
    log(`Collected ${notifications.documents.length} notifications`);
  } catch (e) {
    log(`Notifications fetch error: ${e.message}`);
  }

  return exportData;
}

function sanitizeDocument(doc) {
  const sanitized = { ...doc };
  delete sanitized.$collectionId;
  delete sanitized.$databaseId;
  delete sanitized.$permissions;
  return sanitized;
}
