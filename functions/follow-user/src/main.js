import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: follow-user
 *
 * Gère le suivi d'un utilisateur:
 * - Crée la relation follower/following
 * - Notifie l'utilisateur suivi
 * - Attribue des points de gamification
 *
 * Payload attendu:
 * {
 *   "followerId": "string",   // ID de l'utilisateur qui suit
 *   "followingId": "string"   // ID de l'utilisateur suivi
 * }
 */

// Configuration des points
const POINTS = {
  FOLLOW_SOMEONE: 5,      // Points gagnés en suivant quelqu'un
  GAIN_FOLLOWER: 10       // Points gagnés en recevant un follower
};

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  FOLLOWERS: 'followers',
  NOTIFICATIONS: 'notifications',
  GAMIFICATION: 'gamification'
};

export default async ({ req, res, log, error }) => {
  // Initialisation du client Appwrite
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const databaseId = process.env.DATABASE_ID;

  try {
    // Parsing du payload
    const payload = JSON.parse(req.body || '{}');
    const { followerId, followingId } = payload;

    // Validation des paramètres
    if (!followerId || !followingId) {
      return res.json({
        success: false,
        error: 'Les paramètres followerId et followingId sont requis'
      }, 400);
    }

    if (followerId === followingId) {
      return res.json({
        success: false,
        error: 'Un utilisateur ne peut pas se suivre lui-même'
      }, 400);
    }

    log(`Création du suivi: ${followerId} -> ${followingId}`);

    // Vérifier si la relation existe déjà
    const existingFollow = await databases.listDocuments(
      databaseId,
      COLLECTIONS.FOLLOWERS,
      [
        Query.equal('followerId', followerId),
        Query.equal('followingId', followingId)
      ]
    );

    if (existingFollow.documents.length > 0) {
      return res.json({
        success: false,
        error: 'Cette relation de suivi existe déjà'
      }, 409);
    }

    // Vérifier que les deux utilisateurs existent
    const [follower, following] = await Promise.all([
      databases.getDocument(databaseId, COLLECTIONS.USERS, followerId),
      databases.getDocument(databaseId, COLLECTIONS.USERS, followingId)
    ]);

    // Créer la relation de suivi
    const followRelation = await databases.createDocument(
      databaseId,
      COLLECTIONS.FOLLOWERS,
      ID.unique(),
      {
        followerId,
        followingId,
        createdAt: new Date().toISOString()
      }
    );

    log(`Relation créée: ${followRelation.$id}`);

    // Mettre à jour les compteurs des utilisateurs
    await Promise.all([
      // Incrémenter followingCount du follower
      databases.updateDocument(
        databaseId,
        COLLECTIONS.USERS,
        followerId,
        {
          followingCount: (follower.followingCount || 0) + 1
        }
      ),
      // Incrémenter followersCount du following
      databases.updateDocument(
        databaseId,
        COLLECTIONS.USERS,
        followingId,
        {
          followersCount: (following.followersCount || 0) + 1
        }
      )
    ]);

    // Créer une notification pour l'utilisateur suivi
    const notification = await databases.createDocument(
      databaseId,
      COLLECTIONS.NOTIFICATIONS,
      ID.unique(),
      {
        userId: followingId,
        type: 'new_follower',
        title: 'Nouveau follower',
        message: `${follower.displayName || follower.username} a commencé à vous suivre`,
        data: JSON.stringify({
          followerId,
          followerName: follower.displayName || follower.username,
          followerAvatar: follower.avatarUrl
        }),
        read: false,
        createdAt: new Date().toISOString()
      }
    );

    log(`Notification créée: ${notification.$id}`);

    // Attribuer les points de gamification
    await Promise.all([
      // Points pour celui qui suit
      addGamificationPoints(databases, databaseId, followerId, POINTS.FOLLOW_SOMEONE, 'follow_user', log),
      // Points pour celui qui est suivi
      addGamificationPoints(databases, databaseId, followingId, POINTS.GAIN_FOLLOWER, 'gain_follower', log)
    ]);

    return res.json({
      success: true,
      data: {
        followId: followRelation.$id,
        followerId,
        followingId,
        pointsAwarded: {
          follower: POINTS.FOLLOW_SOMEONE,
          following: POINTS.GAIN_FOLLOWER
        }
      }
    });

  } catch (err) {
    error(`Erreur dans follow-user: ${err.message}`);

    // Gestion des erreurs spécifiques
    if (err.code === 404) {
      return res.json({
        success: false,
        error: 'Utilisateur non trouvé'
      }, 404);
    }

    return res.json({
      success: false,
      error: 'Erreur interne du serveur',
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    }, 500);
  }
};

/**
 * Ajoute des points de gamification à un utilisateur
 */
async function addGamificationPoints(databases, databaseId, userId, points, action, log) {
  try {
    // Récupérer ou créer le document de gamification
    let gamification;

    try {
      const existing = await databases.listDocuments(
        databaseId,
        COLLECTIONS.GAMIFICATION,
        [Query.equal('userId', userId)]
      );

      if (existing.documents.length > 0) {
        gamification = existing.documents[0];
      }
    } catch (e) {
      // Document n'existe pas encore
    }

    if (gamification) {
      // Mettre à jour les points existants
      await databases.updateDocument(
        databaseId,
        COLLECTIONS.GAMIFICATION,
        gamification.$id,
        {
          totalPoints: (gamification.totalPoints || 0) + points,
          lastAction: action,
          lastUpdated: new Date().toISOString()
        }
      );
    } else {
      // Créer un nouveau document de gamification
      await databases.createDocument(
        databaseId,
        COLLECTIONS.GAMIFICATION,
        ID.unique(),
        {
          userId,
          totalPoints: points,
          level: 1,
          badges: [],
          lastAction: action,
          lastUpdated: new Date().toISOString()
        }
      );
    }

    log(`Points ajoutés: ${points} pour ${userId} (action: ${action})`);
  } catch (err) {
    log(`Erreur lors de l'ajout des points: ${err.message}`);
  }
}
