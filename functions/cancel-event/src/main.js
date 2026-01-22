import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: cancel-event
 *
 * Gere l'annulation d'un evenement par l'organisateur:
 * - Met a jour le statut de l'evenement a 'cancelled'
 * - Met a jour tous les participants a 'cancelled'
 * - Notifie tous les participants
 *
 * Payload attendu:
 * {
 *   "eventId": "string",       // ID de l'evenement a annuler
 *   "organizerId": "string",   // ID de l'organisateur (pour verification)
 *   "reason": "string"         // Raison de l'annulation (optionnel)
 * }
 */

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  NOTIFICATIONS: 'notifications',
};

// Limite de participants par lot de notification
const NOTIFICATION_BATCH_SIZE = 10;

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
    const { eventId, organizerId, reason } = payload;

    // Validation des parametres
    if (!eventId || !organizerId) {
      return res.json({
        success: false,
        error: 'Les parametres eventId et organizerId sont requis'
      }, 400);
    }

    log(`Annulation d'evenement: ${eventId} par ${organizerId}`);

    // Recuperer l'evenement
    const event = await databases.getDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId
    );

    // Verifier que l'utilisateur est l'organisateur
    if (event.creatorId !== organizerId) {
      return res.json({
        success: false,
        error: 'Seul l\'organisateur peut annuler cet evenement'
      }, 403);
    }

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
        error: 'Impossible d\'annuler un evenement termine'
      }, 400);
    }

    const now = new Date().toISOString();

    // Mettre a jour le statut de l'evenement
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      eventId,
      {
        status: 'cancelled',
        updatedAt: now
      }
    );

    log(`Evenement annule: ${eventId}`);

    // Recuperer les informations de l'organisateur
    const organizer = await databases.getDocument(
      databaseId,
      COLLECTIONS.USERS,
      organizerId
    );

    // Recuperer tous les participants confirmes (sauf l'organisateur)
    const participants = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      [
        Query.equal('eventId', eventId),
        Query.equal('status', 'confirmed'),
        Query.limit(100)
      ]
    );

    const participantsToNotify = participants.documents.filter(
      p => p.userId !== organizerId
    );

    log(`Notification de ${participantsToNotify.length} participants`);

    // Mettre a jour le statut de tous les participants
    const updatePromises = participants.documents.map(participant =>
      databases.updateDocument(
        databaseId,
        COLLECTIONS.EVENT_PARTICIPANTS,
        participant.$id,
        {
          status: 'cancelled',
          cancelledAt: now
        }
      )
    );

    await Promise.all(updatePromises);

    // Preparer le message de notification
    const notificationBody = reason
      ? `L'evenement "${event.title}" organise par ${organizer.displayName || organizer.username} a ete annule. Raison: ${reason}`
      : `L'evenement "${event.title}" organise par ${organizer.displayName || organizer.username} a ete annule.`;

    // Notifier tous les participants par lots
    const notificationData = JSON.stringify({
      eventId,
      eventTitle: event.title,
      organizerId,
      organizerName: organizer.displayName || organizer.username,
      reason: reason || null,
      originalDate: event.startDate
    });

    for (let i = 0; i < participantsToNotify.length; i += NOTIFICATION_BATCH_SIZE) {
      const batch = participantsToNotify.slice(i, i + NOTIFICATION_BATCH_SIZE);

      const notificationPromises = batch.map(participant =>
        databases.createDocument(
          databaseId,
          COLLECTIONS.NOTIFICATIONS,
          ID.unique(),
          {
            userId: participant.userId,
            type: 'event_cancelled',
            title: 'Evenement annule',
            body: notificationBody,
            data: notificationData,
            isRead: false,
            createdAt: now
          }
        )
      );

      await Promise.all(notificationPromises);
    }

    log(`Annulation complete - ${participantsToNotify.length} participants notifies`);

    return res.json({
      success: true,
      data: {
        eventId,
        status: 'cancelled',
        participantsNotified: participantsToNotify.length,
        cancelledAt: now,
        reason: reason || null,
        event: {
          title: event.title,
          originalDate: event.startDate
        }
      }
    });

  } catch (err) {
    error(`Erreur dans cancel-event: ${err.message}`);

    // Gestion des erreurs specifiques
    if (err.code === 404) {
      return res.json({
        success: false,
        error: 'Evenement non trouve'
      }, 404);
    }

    return res.json({
      success: false,
      error: 'Erreur interne du serveur',
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    }, 500);
  }
};
