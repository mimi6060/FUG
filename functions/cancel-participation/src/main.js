import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: cancel-participation
 *
 * Gere l'annulation d'une participation a un evenement:
 * - Met a jour le statut de participation a 'cancelled'
 * - Decremente le compteur de participants
 * - Notifie l'organisateur
 *
 * Payload attendu:
 * {
 *   "userId": "string",    // ID de l'utilisateur qui annule
 *   "eventId": "string"    // ID de l'evenement
 * }
 */

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  NOTIFICATIONS: 'notifications',
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

    // Validation des parametres
    if (!userId || !eventId) {
      return res.json({
        success: false,
        error: 'Les parametres userId et eventId sont requis'
      }, 400);
    }

    log(`Annulation de participation: ${userId} pour l'evenement ${eventId}`);

    // Recuperer l'evenement
    const event = await databases.getDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId
    );

    // Verifier si l'evenement n'est pas deja annule ou termine
    if (event.status === 'cancelled') {
      return res.json({
        success: false,
        error: 'Cet evenement a deja ete annule'
      }, 400);
    }

    if (event.status === 'completed') {
      return res.json({
        success: false,
        error: 'Cet evenement est deja termine'
      }, 400);
    }

    // Chercher la participation active de l'utilisateur
    const participations = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      [
        Query.equal('userId', userId),
        Query.equal('eventId', eventId),
        Query.equal('status', 'confirmed')
      ]
    );

    if (participations.documents.length === 0) {
      return res.json({
        success: false,
        error: 'Vous n\'etes pas inscrit a cet evenement'
      }, 404);
    }

    const participation = participations.documents[0];

    // Verifier que l'utilisateur n'est pas l'organisateur
    if (participation.role === 'organizer') {
      return res.json({
        success: false,
        error: 'L\'organisateur ne peut pas annuler sa propre participation. Utilisez l\'annulation d\'evenement.'
      }, 400);
    }

    // Recuperer les informations de l'utilisateur
    const user = await databases.getDocument(
      databaseId,
      COLLECTIONS.USERS,
      userId
    );

    const now = new Date().toISOString();

    // Mettre a jour le statut de participation
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      participation.$id,
      {
        status: 'cancelled',
        cancelledAt: now
      }
    );

    log(`Participation annulee: ${participation.$id}`);

    // Decrementer le compteur de participants
    const newParticipantCount = Math.max(0, (event.participantCount || 1) - 1);
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId,
      {
        participantCount: newParticipantCount,
        updatedAt: now
      }
    );

    // Notifier l'organisateur
    await databases.createDocument(
      databaseId,
      COLLECTIONS.NOTIFICATIONS,
      ID.unique(),
      {
        userId: event.creatorId,
        type: 'event_update',
        title: 'Participant desiste',
        body: `${user.displayName || user.username} s'est desiste de votre evenement "${event.title}"`,
        data: JSON.stringify({
          eventId,
          eventTitle: event.title,
          participantId: userId,
          participantName: user.displayName || user.username,
          remainingParticipants: newParticipantCount
        }),
        isRead: false,
        createdAt: now
      }
    );

    log(`Annulation reussie - Participants restants: ${newParticipantCount}`);

    return res.json({
      success: true,
      data: {
        participationId: participation.$id,
        eventId,
        userId,
        participantCount: newParticipantCount,
        cancelledAt: now,
        event: {
          title: event.title,
          startDate: event.startDate
        }
      }
    });

  } catch (err) {
    error(`Erreur dans cancel-participation: ${err.message}`);

    // Gestion des erreurs specifiques
    if (err.code === 404) {
      return res.json({
        success: false,
        error: 'Evenement ou utilisateur non trouve'
      }, 404);
    }

    return res.json({
      success: false,
      error: 'Erreur interne du serveur',
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    }, 500);
  }
};
