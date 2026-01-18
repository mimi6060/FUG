import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: create-event
 *
 * Gère la création d'un événement:
 * - Crée l'événement dans la base de données
 * - Notifie tous les followers du créateur
 * - Attribue des points de gamification
 *
 * Payload attendu:
 * {
 *   "organizerId": "string",      // ID de l'utilisateur créateur
 *   "title": "string",            // Titre de l'événement
 *   "description": "string",      // Description
 *   "startDate": "string",        // Date de début (ISO 8601)
 *   "endDate": "string",          // Date de fin (ISO 8601) - optionnel
 *   "location": "string",         // Lieu de l'événement
 *   "latitude": number,           // Latitude - optionnel
 *   "longitude": number,          // Longitude - optionnel
 *   "category": "string",         // Catégorie (gaming, esport, etc.)
 *   "maxParticipants": number,    // Limite de participants - optionnel
 *   "imageUrl": "string",         // URL de l'image - optionnel
 *   "tags": ["string"]            // Tags - optionnel
 * }
 */

// Configuration des points
const POINTS = {
  CREATE_EVENT: 25,           // Points gagnés en créant un événement
  FIRST_EVENT_BONUS: 50,      // Bonus pour le premier événement créé
  MILESTONE_5_EVENTS: 100,    // Bonus après 5 événements créés
  MILESTONE_10_EVENTS: 200    // Bonus après 10 événements créés
};

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  FOLLOWERS: 'followers',
  NOTIFICATIONS: 'notifications',
  GAMIFICATION: 'gamification'
};

// Catégories d'événements valides
const VALID_CATEGORIES = [
  'gaming',
  'esport',
  'tournament',
  'lan_party',
  'streaming',
  'meetup',
  'workshop',
  'conference',
  'other'
];

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
    const {
      organizerId,
      title,
      description,
      startDate,
      endDate,
      location,
      latitude,
      longitude,
      category,
      maxParticipants,
      imageUrl,
      tags
    } = payload;

    // Validation des paramètres requis
    if (!organizerId || !title || !description || !startDate || !location || !category) {
      return res.json({
        success: false,
        error: 'Les paramètres organizerId, title, description, startDate, location et category sont requis'
      }, 400);
    }

    // Validation du titre
    if (title.length < 5 || title.length > 100) {
      return res.json({
        success: false,
        error: 'Le titre doit contenir entre 5 et 100 caractères'
      }, 400);
    }

    // Validation de la description
    if (description.length < 20 || description.length > 2000) {
      return res.json({
        success: false,
        error: 'La description doit contenir entre 20 et 2000 caractères'
      }, 400);
    }

    // Validation de la catégorie
    if (!VALID_CATEGORIES.includes(category)) {
      return res.json({
        success: false,
        error: `Catégorie invalide. Catégories valides: ${VALID_CATEGORIES.join(', ')}`
      }, 400);
    }

    // Validation de la date
    const eventStartDate = new Date(startDate);
    if (isNaN(eventStartDate.getTime())) {
      return res.json({
        success: false,
        error: 'Format de date invalide'
      }, 400);
    }

    if (eventStartDate < new Date()) {
      return res.json({
        success: false,
        error: 'La date de l\'événement doit être dans le futur'
      }, 400);
    }

    log(`Création d'événement par: ${organizerId}`);

    // Vérifier que l'organisateur existe
    const organizer = await databases.getDocument(
      databaseId,
      COLLECTIONS.USERS,
      organizerId
    );

    // Compter les événements existants de l'organisateur
    const organizerEvents = await databases.listDocuments(
      databaseId,
      COLLECTIONS.EVENTS,
      [
        Query.equal('organizerId', organizerId)
      ]
    );

    const eventCount = organizerEvents.documents.length;
    const isFirstEvent = eventCount === 0;

    // Créer l'événement
    const now = new Date().toISOString();
    const eventData = {
      organizerId,
      title,
      description,
      startDate,
      endDate: endDate || null,
      location,
      latitude: latitude || null,
      longitude: longitude || null,
      category,
      maxParticipants: maxParticipants || null,
      imageUrl: imageUrl || null,
      tags: tags || [],
      status: 'upcoming',
      participantCount: 0,
      createdAt: now,
      updatedAt: now
    };

    const event = await databases.createDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      ID.unique(),
      eventData
    );

    log(`Événement créé: ${event.$id}`);

    // Ajouter automatiquement l'organisateur comme participant
    await databases.createDocument(
      databaseId,
      COLLECTIONS.EVENT_PARTICIPANTS,
      ID.unique(),
      {
        userId: organizerId,
        eventId: event.$id,
        status: 'confirmed',
        role: 'organizer',
        joinedAt: now
      }
    );

    // Mettre à jour le compteur
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.EVENTS,
      event.$id,
      {
        participantCount: 1
      }
    );

    // Récupérer les followers de l'organisateur
    const followers = await databases.listDocuments(
      databaseId,
      COLLECTIONS.FOLLOWERS,
      [
        Query.equal('followingId', organizerId),
        Query.limit(100) // Limiter pour les performances
      ]
    );

    log(`Notification de ${followers.documents.length} followers`);

    // Notifier les followers
    const notificationPromises = followers.documents.map(follower =>
      databases.createDocument(
        databaseId,
        COLLECTIONS.NOTIFICATIONS,
        ID.unique(),
        {
          userId: follower.followerId,
          type: 'new_event',
          title: 'Nouvel événement',
          message: `${organizer.displayName || organizer.username} a créé un nouvel événement: "${title}"`,
          data: JSON.stringify({
            eventId: event.$id,
            eventTitle: title,
            eventDate: startDate,
            eventLocation: location,
            eventCategory: category,
            organizerId,
            organizerName: organizer.displayName || organizer.username,
            organizerAvatar: organizer.avatarUrl
          }),
          read: false,
          createdAt: now
        }
      )
    );

    // Exécuter les notifications en parallèle par lots
    const batchSize = 10;
    for (let i = 0; i < notificationPromises.length; i += batchSize) {
      const batch = notificationPromises.slice(i, i + batchSize);
      await Promise.all(batch);
    }

    // Attribuer les points de gamification
    let totalPointsAwarded = POINTS.CREATE_EVENT;
    const bonuses = [];

    // Points de base pour la création
    await addGamificationPoints(
      databases,
      databaseId,
      organizerId,
      POINTS.CREATE_EVENT,
      'create_event',
      log
    );

    // Bonus premier événement
    if (isFirstEvent) {
      await addGamificationPoints(
        databases,
        databaseId,
        organizerId,
        POINTS.FIRST_EVENT_BONUS,
        'first_event_bonus',
        log
      );
      totalPointsAwarded += POINTS.FIRST_EVENT_BONUS;
      bonuses.push({ type: 'first_event', points: POINTS.FIRST_EVENT_BONUS });
    }

    // Vérifier les milestones
    const newEventCount = eventCount + 1;

    if (newEventCount === 5) {
      await addGamificationPoints(
        databases,
        databaseId,
        organizerId,
        POINTS.MILESTONE_5_EVENTS,
        'milestone_5_events',
        log
      );
      totalPointsAwarded += POINTS.MILESTONE_5_EVENTS;
      bonuses.push({ type: 'milestone_5_events', points: POINTS.MILESTONE_5_EVENTS });
    } else if (newEventCount === 10) {
      await addGamificationPoints(
        databases,
        databaseId,
        organizerId,
        POINTS.MILESTONE_10_EVENTS,
        'milestone_10_events',
        log
      );
      totalPointsAwarded += POINTS.MILESTONE_10_EVENTS;
      bonuses.push({ type: 'milestone_10_events', points: POINTS.MILESTONE_10_EVENTS });
    }

    log(`Événement créé avec succès - Points: ${totalPointsAwarded}`);

    return res.json({
      success: true,
      data: {
        eventId: event.$id,
        title,
        category,
        startDate,
        location,
        organizerId,
        followersNotified: followers.documents.length,
        pointsAwarded: totalPointsAwarded,
        bonuses,
        totalEventsCreated: newEventCount
      }
    });

  } catch (err) {
    error(`Erreur dans create-event: ${err.message}`);

    // Gestion des erreurs spécifiques
    if (err.code === 404) {
      return res.json({
        success: false,
        error: 'Organisateur non trouvé'
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
  let level = 1;
  let pointsRequired = 0;

  while (totalPoints >= pointsRequired + (100 * level)) {
    pointsRequired += 100 * level;
    level++;
  }

  return level;
}
