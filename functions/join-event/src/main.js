import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: join-event
 *
 * Gère l'inscription à un événement:
 * - Ajoute le participant à l'événement
 * - Vérifie la limite de participants
 * - Notifie les participants existants
 * - Attribue des points de gamification
 *
 * Payload attendu:
 * {
 *   "userId": "string",    // ID de l'utilisateur qui rejoint
 *   "eventId": "string"    // ID de l'événement
 * }
 */

// Configuration des points
const POINTS = {
  JOIN_EVENT: 15,           // Points gagnés en rejoignant un événement
  EVENT_MILESTONE_10: 25,   // Bonus quand l'événement atteint 10 participants
  EVENT_MILESTONE_50: 50,   // Bonus quand l'événement atteint 50 participants
  ORGANIZER_BONUS: 5        // Points pour l'organisateur par nouveau participant
};

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
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
    const { userId, eventId } = payload;

    // Validation des paramètres
    if (!userId || !eventId) {
      return res.json({
        success: false,
        error: 'Les paramètres userId et eventId sont requis'
      }, 400);
    }

    log(`Inscription à l'événement: ${userId} -> ${eventId}`);

    // Récupérer l'événement
    const event = await databases.getDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId
    );

    // Vérifier si l'événement est encore ouvert
    if (event.status === 'cancelled') {
      return res.json({
        success: false,
        error: 'Cet événement a été annulé'
      }, 400);
    }

    if (event.status === 'completed') {
      return res.json({
        success: false,
        error: 'Cet événement est terminé'
      }, 400);
    }

    // Vérifier si l'événement n'est pas passé
    const eventDate = new Date(event.startDate);
    if (eventDate < new Date()) {
      return res.json({
        success: false,
        error: 'Cet événement est déjà passé'
      }, 400);
    }

    // Vérifier si l'utilisateur est déjà inscrit
    const existingParticipation = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      [
        Query.equal('userId', userId),
        Query.equal('eventId', eventId)
      ]
    );

    if (existingParticipation.documents.length > 0) {
      return res.json({
        success: false,
        error: 'Vous êtes déjà inscrit à cet événement'
      }, 409);
    }

    // Compter les participants actuels
    const currentParticipants = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      [
        Query.equal('eventId', eventId),
        Query.equal('status', 'confirmed')
      ]
    );

    const participantCount = currentParticipants.documents.length;

    // Vérifier la limite de participants
    if (event.maxParticipants && participantCount >= event.maxParticipants) {
      return res.json({
        success: false,
        error: 'L\'événement a atteint sa limite de participants'
      }, 400);
    }

    // Récupérer les informations de l'utilisateur
    const user = await databases.getDocument(
      databaseId,
      COLLECTIONS.USERS,
      userId
    );

    // Créer la participation
    const participation = await databases.createDocument(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      ID.unique(),
      {
        userId,
        eventId,
        status: 'confirmed',
        joinedAt: new Date().toISOString()
      }
    );

    log(`Participation créée: ${participation.$id}`);

    // Mettre à jour le compteur de participants de l'événement
    const newParticipantCount = participantCount + 1;
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId,
      {
        participantCount: newParticipantCount
      }
    );

    // Notifier l'organisateur
    await databases.createDocument(
      databaseId,
      COLLECTIONS.NOTIFICATIONS,
      ID.unique(),
      {
        userId: event.organizerId,
        type: 'new_participant',
        title: 'Nouveau participant',
        message: `${user.displayName || user.username} a rejoint votre événement "${event.title}"`,
        data: JSON.stringify({
          eventId,
          eventTitle: event.title,
          participantId: userId,
          participantName: user.displayName || user.username,
          totalParticipants: newParticipantCount
        }),
        read: false,
        createdAt: new Date().toISOString()
      }
    );

    // Notifier les autres participants (optionnel, limité aux 5 derniers)
    if (participantCount > 0 && participantCount <= 20) {
      const recentParticipants = currentParticipants.documents.slice(-5);

      const notificationPromises = recentParticipants
        .filter(p => p.userId !== userId && p.userId !== event.organizerId)
        .map(participant =>
          databases.createDocument(
            databaseId,
            COLLECTIONS.NOTIFICATIONS,
            ID.unique(),
            {
              userId: participant.userId,
              type: 'event_update',
              title: 'Nouveau participant',
              message: `${user.displayName || user.username} a également rejoint "${event.title}"`,
              data: JSON.stringify({
                eventId,
                eventTitle: event.title,
                newParticipantName: user.displayName || user.username,
                totalParticipants: newParticipantCount
              }),
              read: false,
              createdAt: new Date().toISOString()
            }
          )
        );

      await Promise.all(notificationPromises);
    }

    // Attribuer les points de gamification
    let totalPointsAwarded = POINTS.JOIN_EVENT;

    // Points pour le participant
    await addGamificationPoints(
      databases,
      databaseId,
      userId,
      POINTS.JOIN_EVENT,
      'join_event',
      log
    );

    // Bonus pour l'organisateur
    await addGamificationPoints(
      databases,
      databaseId,
      event.organizerId,
      POINTS.ORGANIZER_BONUS,
      'event_participant_joined',
      log
    );

    // Vérifier les milestones
    let milestoneReached = null;

    if (newParticipantCount === 10) {
      milestoneReached = { count: 10, points: POINTS.EVENT_MILESTONE_10 };
      await addGamificationPoints(
        databases,
        databaseId,
        event.organizerId,
        POINTS.EVENT_MILESTONE_10,
        'event_milestone_10',
        log
      );
    } else if (newParticipantCount === 50) {
      milestoneReached = { count: 50, points: POINTS.EVENT_MILESTONE_50 };
      await addGamificationPoints(
        databases,
        databaseId,
        event.organizerId,
        POINTS.EVENT_MILESTONE_50,
        'event_milestone_50',
        log
      );
    }

    log(`Inscription réussie - Participants: ${newParticipantCount}`);

    return res.json({
      success: true,
      data: {
        participationId: participation.$id,
        eventId,
        userId,
        participantCount: newParticipantCount,
        pointsAwarded: totalPointsAwarded,
        milestoneReached,
        event: {
          title: event.title,
          startDate: event.startDate,
          location: event.location
        }
      }
    });

  } catch (err) {
    error(`Erreur dans join-event: ${err.message}`);

    // Gestion des erreurs spécifiques
    if (err.code === 404) {
      return res.json({
        success: false,
        error: 'Événement ou utilisateur non trouvé'
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

    const now = new Date().toISOString();

    if (gamification) {
      // Mettre à jour les points existants
      const newTotal = (gamification.totalPoints || 0) + points;
      const newLevel = calculateLevel(newTotal);

      await databases.updateDocument(
        databaseId,
        COLLECTIONS.GAMIFICATION,
        gamification.$id,
        {
          totalPoints: newTotal,
          level: newLevel,
          lastAction: action,
          lastUpdated: now
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
          lastUpdated: now
        }
      );
    }

    log(`Points ajoutés: ${points} pour ${userId} (action: ${action})`);
  } catch (err) {
    log(`Erreur lors de l'ajout des points: ${err.message}`);
  }
}

/**
 * Calcule le niveau basé sur les points totaux
 */
function calculateLevel(totalPoints) {
  // Formule: chaque niveau nécessite 100 * niveau points
  // Niveau 1: 0-99, Niveau 2: 100-299, Niveau 3: 300-599, etc.
  let level = 1;
  let pointsRequired = 0;

  while (totalPoints >= pointsRequired + (100 * level)) {
    pointsRequired += 100 * level;
    level++;
  }

  return level;
}
