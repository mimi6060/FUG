import { Client, Databases, Query, ID } from 'node-appwrite';

/**
 * Appwrite Function: gamification
 *
 * Système de gamification complet:
 * - Vérifie et attribue les achievements
 * - Attribue les badges
 * - Calcule et met à jour le leaderboard
 *
 * Payload attendu:
 * {
 *   "action": "string",         // Type d'action: "check_achievements", "calculate_leaderboard", "award_badge"
 *   "userId": "string",         // ID de l'utilisateur (optionnel pour leaderboard global)
 *   "badgeId": "string",        // ID du badge à attribuer (pour action "award_badge")
 *   "period": "string"          // Période pour le leaderboard: "daily", "weekly", "monthly", "all_time"
 * }
 */

// Définition des badges disponibles
const BADGES = {
  // Badges de participation
  FIRST_EVENT: {
    id: 'first_event',
    name: 'Premier Pas',
    description: 'A rejoint son premier événement',
    icon: 'badge-first-event',
    condition: (stats) => stats.eventsJoined >= 1
  },
  EVENT_ENTHUSIAST: {
    id: 'event_enthusiast',
    name: 'Enthousiaste',
    description: 'A participé à 10 événements',
    icon: 'badge-enthusiast',
    condition: (stats) => stats.eventsJoined >= 10
  },
  EVENT_VETERAN: {
    id: 'event_veteran',
    name: 'Vétéran',
    description: 'A participé à 50 événements',
    icon: 'badge-veteran',
    condition: (stats) => stats.eventsJoined >= 50
  },

  // Badges de création
  EVENT_CREATOR: {
    id: 'event_creator',
    name: 'Organisateur',
    description: 'A créé son premier événement',
    icon: 'badge-creator',
    condition: (stats) => stats.eventsCreated >= 1
  },
  EVENT_MASTER: {
    id: 'event_master',
    name: 'Maître Organisateur',
    description: 'A créé 10 événements',
    icon: 'badge-master',
    condition: (stats) => stats.eventsCreated >= 10
  },
  EVENT_LEGEND: {
    id: 'event_legend',
    name: 'Légende',
    description: 'A créé 25 événements',
    icon: 'badge-legend',
    condition: (stats) => stats.eventsCreated >= 25
  },

  // Badges sociaux
  SOCIAL_BUTTERFLY: {
    id: 'social_butterfly',
    name: 'Papillon Social',
    description: 'A 10 followers',
    icon: 'badge-social',
    condition: (stats) => stats.followersCount >= 10
  },
  INFLUENCER: {
    id: 'influencer',
    name: 'Influenceur',
    description: 'A 100 followers',
    icon: 'badge-influencer',
    condition: (stats) => stats.followersCount >= 100
  },
  COMMUNITY_STAR: {
    id: 'community_star',
    name: 'Star de la Communauté',
    description: 'A 500 followers',
    icon: 'badge-star',
    condition: (stats) => stats.followersCount >= 500
  },

  // Badges de niveau
  LEVEL_5: {
    id: 'level_5',
    name: 'Apprenti',
    description: 'A atteint le niveau 5',
    icon: 'badge-level-5',
    condition: (stats) => stats.level >= 5
  },
  LEVEL_10: {
    id: 'level_10',
    name: 'Expert',
    description: 'A atteint le niveau 10',
    icon: 'badge-level-10',
    condition: (stats) => stats.level >= 10
  },
  LEVEL_25: {
    id: 'level_25',
    name: 'Maître',
    description: 'A atteint le niveau 25',
    icon: 'badge-level-25',
    condition: (stats) => stats.level >= 25
  },

  // Badges spéciaux
  EARLY_ADOPTER: {
    id: 'early_adopter',
    name: 'Early Adopter',
    description: 'Fait partie des premiers utilisateurs',
    icon: 'badge-early-adopter',
    condition: () => false // Attribué manuellement
  },
  COMMUNITY_HELPER: {
    id: 'community_helper',
    name: 'Aide de la Communauté',
    description: 'A aidé de nombreux membres',
    icon: 'badge-helper',
    condition: () => false // Attribué manuellement
  }
};

// Configuration des collections
const COLLECTIONS = {
  USERS: 'users',
  EVENTS: 'events',
  EVENT_PARTICIPANTS: 'event_participants',
  FOLLOWERS: 'followers',
  GAMIFICATION: 'gamification',
  LEADERBOARD: 'leaderboard',
  NOTIFICATIONS: 'notifications'
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
    const { action, userId, badgeId, period = 'weekly' } = payload;

    // Validation de l'action
    if (!action) {
      return res.json({
        success: false,
        error: 'Le paramètre action est requis'
      }, 400);
    }

    log(`Action gamification: ${action}`);

    switch (action) {
      case 'check_achievements':
        return await checkAchievements(databases, databaseId, userId, res, log);

      case 'calculate_leaderboard':
        return await calculateLeaderboard(databases, databaseId, period, res, log);

      case 'award_badge':
        return await awardBadge(databases, databaseId, userId, badgeId, res, log);

      case 'get_user_stats':
        return await getUserStats(databases, databaseId, userId, res, log);

      case 'get_badges':
        return res.json({
          success: true,
          data: {
            badges: Object.values(BADGES).map(b => ({
              id: b.id,
              name: b.name,
              description: b.description,
              icon: b.icon
            }))
          }
        });

      default:
        return res.json({
          success: false,
          error: `Action inconnue: ${action}. Actions valides: check_achievements, calculate_leaderboard, award_badge, get_user_stats, get_badges`
        }, 400);
    }

  } catch (err) {
    error(`Erreur dans gamification: ${err.message}`);

    return res.json({
      success: false,
      error: 'Erreur interne du serveur',
      details: process.env.NODE_ENV === 'development' ? err.message : undefined
    }, 500);
  }
};

/**
 * Vérifie et attribue les achievements pour un utilisateur
 */
async function checkAchievements(databases, databaseId, userId, res, log) {
  if (!userId) {
    return res.json({
      success: false,
      error: 'Le paramètre userId est requis pour check_achievements'
    }, 400);
  }

  log(`Vérification des achievements pour: ${userId}`);

  // Récupérer les statistiques de l'utilisateur
  const stats = await getUserStatistics(databases, databaseId, userId);

  // Récupérer le document de gamification actuel
  let gamification;
  const existing = await databases.listDocuments(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    [Query.equal('userId', userId)]
  );

  if (existing.documents.length > 0) {
    gamification = existing.documents[0];
  } else {
    // Créer le document de gamification s'il n'existe pas
    gamification = await databases.createDocument(
      databaseId,
      COLLECTIONS.GAMIFICATION,
      ID.unique(),
      {
        userId,
        totalPoints: 0,
        level: 1,
        badges: [],
        lastUpdated: new Date().toISOString()
      }
    );
  }

  const currentBadges = gamification.badges || [];
  const newBadges = [];

  // Vérifier chaque badge
  for (const [key, badge] of Object.entries(BADGES)) {
    // Skip si l'utilisateur a déjà ce badge
    if (currentBadges.includes(badge.id)) {
      continue;
    }

    // Vérifier la condition du badge
    if (badge.condition(stats)) {
      newBadges.push(badge);
      log(`Nouveau badge débloqué: ${badge.name}`);
    }
  }

  // Attribuer les nouveaux badges
  if (newBadges.length > 0) {
    const updatedBadges = [...currentBadges, ...newBadges.map(b => b.id)];

    await databases.updateDocument(
      databaseId,
      COLLECTIONS.GAMIFICATION,
      gamification.$id,
      {
        badges: updatedBadges,
        lastUpdated: new Date().toISOString()
      }
    );

    // Créer des notifications pour les nouveaux badges
    const notificationPromises = newBadges.map(badge =>
      databases.createDocument(
        databaseId,
        COLLECTIONS.NOTIFICATIONS,
        ID.unique(),
        {
          userId,
          type: 'badge_earned',
          title: 'Nouveau badge !',
          message: `Vous avez obtenu le badge "${badge.name}"`,
          data: JSON.stringify({
            badgeId: badge.id,
            badgeName: badge.name,
            badgeDescription: badge.description,
            badgeIcon: badge.icon
          }),
          read: false,
          createdAt: new Date().toISOString()
        }
      )
    );

    await Promise.all(notificationPromises);
  }

  return res.json({
    success: true,
    data: {
      userId,
      stats,
      currentBadges: currentBadges.length,
      newBadgesEarned: newBadges.map(b => ({
        id: b.id,
        name: b.name,
        description: b.description
      })),
      totalBadges: currentBadges.length + newBadges.length
    }
  });
}

/**
 * Calcule et met à jour le leaderboard
 */
async function calculateLeaderboard(databases, databaseId, period, res, log) {
  log(`Calcul du leaderboard: ${period}`);

  // Déterminer la date de début selon la période
  const now = new Date();
  let startDate;

  switch (period) {
    case 'daily':
      startDate = new Date(now.setHours(0, 0, 0, 0));
      break;
    case 'weekly':
      const dayOfWeek = now.getDay();
      startDate = new Date(now.setDate(now.getDate() - dayOfWeek));
      startDate.setHours(0, 0, 0, 0);
      break;
    case 'monthly':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      break;
    case 'all_time':
    default:
      startDate = new Date(0); // Depuis toujours
      break;
  }

  // Récupérer tous les documents de gamification
  const gamificationDocs = await databases.listDocuments(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    [
      Query.orderDesc('totalPoints'),
      Query.limit(100)
    ]
  );

  // Enrichir avec les données utilisateur
  const leaderboardEntries = [];

  for (const doc of gamificationDocs.documents) {
    try {
      const user = await databases.getDocument(
        databaseId,
        COLLECTIONS.USERS,
        doc.userId
      );

      leaderboardEntries.push({
        userId: doc.userId,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        totalPoints: doc.totalPoints,
        level: doc.level,
        badgeCount: (doc.badges || []).length
      });
    } catch (e) {
      // Utilisateur supprimé, ignorer
      log(`Utilisateur non trouvé: ${doc.userId}`);
    }
  }

  // Assigner les rangs
  leaderboardEntries.forEach((entry, index) => {
    entry.rank = index + 1;
  });

  // Sauvegarder le leaderboard
  const leaderboardId = `leaderboard_${period}`;

  try {
    // Essayer de mettre à jour le document existant
    await databases.updateDocument(
      databaseId,
      COLLECTIONS.LEADERBOARD,
      leaderboardId,
      {
        period,
        entries: JSON.stringify(leaderboardEntries.slice(0, 50)),
        lastCalculated: new Date().toISOString()
      }
    );
  } catch (e) {
    // Créer le document s'il n'existe pas
    await databases.createDocument(
      databaseId,
      COLLECTIONS.LEADERBOARD,
      leaderboardId,
      {
        period,
        entries: JSON.stringify(leaderboardEntries.slice(0, 50)),
        lastCalculated: new Date().toISOString()
      }
    );
  }

  log(`Leaderboard mis à jour: ${leaderboardEntries.length} entrées`);

  return res.json({
    success: true,
    data: {
      period,
      totalEntries: leaderboardEntries.length,
      leaderboard: leaderboardEntries.slice(0, 50),
      lastCalculated: new Date().toISOString()
    }
  });
}

/**
 * Attribue un badge spécifique à un utilisateur
 */
async function awardBadge(databases, databaseId, userId, badgeId, res, log) {
  if (!userId || !badgeId) {
    return res.json({
      success: false,
      error: 'Les paramètres userId et badgeId sont requis pour award_badge'
    }, 400);
  }

  // Vérifier que le badge existe
  const badge = Object.values(BADGES).find(b => b.id === badgeId);
  if (!badge) {
    return res.json({
      success: false,
      error: `Badge inconnu: ${badgeId}`
    }, 400);
  }

  log(`Attribution du badge ${badgeId} à ${userId}`);

  // Récupérer le document de gamification
  const existing = await databases.listDocuments(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    [Query.equal('userId', userId)]
  );

  let gamification;

  if (existing.documents.length > 0) {
    gamification = existing.documents[0];
  } else {
    // Créer le document s'il n'existe pas
    gamification = await databases.createDocument(
      databaseId,
      COLLECTIONS.GAMIFICATION,
      ID.unique(),
      {
        userId,
        totalPoints: 0,
        level: 1,
        badges: [],
        lastUpdated: new Date().toISOString()
      }
    );
  }

  const currentBadges = gamification.badges || [];

  // Vérifier si l'utilisateur a déjà ce badge
  if (currentBadges.includes(badgeId)) {
    return res.json({
      success: false,
      error: 'L\'utilisateur possède déjà ce badge'
    }, 409);
  }

  // Attribuer le badge
  const updatedBadges = [...currentBadges, badgeId];

  await databases.updateDocument(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    gamification.$id,
    {
      badges: updatedBadges,
      lastUpdated: new Date().toISOString()
    }
  );

  // Créer une notification
  await databases.createDocument(
    databaseId,
    COLLECTIONS.NOTIFICATIONS,
    ID.unique(),
    {
      userId,
      type: 'badge_earned',
      title: 'Nouveau badge !',
      message: `Vous avez reçu le badge "${badge.name}"`,
      data: JSON.stringify({
        badgeId: badge.id,
        badgeName: badge.name,
        badgeDescription: badge.description,
        badgeIcon: badge.icon
      }),
      read: false,
      createdAt: new Date().toISOString()
    }
  );

  log(`Badge attribué avec succès`);

  return res.json({
    success: true,
    data: {
      userId,
      badge: {
        id: badge.id,
        name: badge.name,
        description: badge.description,
        icon: badge.icon
      },
      totalBadges: updatedBadges.length
    }
  });
}

/**
 * Récupère les statistiques complètes d'un utilisateur
 */
async function getUserStats(databases, databaseId, userId, res, log) {
  if (!userId) {
    return res.json({
      success: false,
      error: 'Le paramètre userId est requis pour get_user_stats'
    }, 400);
  }

  log(`Récupération des stats pour: ${userId}`);

  const stats = await getUserStatistics(databases, databaseId, userId);

  // Récupérer le document de gamification
  const existing = await databases.listDocuments(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    [Query.equal('userId', userId)]
  );

  let gamification = {
    totalPoints: 0,
    level: 1,
    badges: []
  };

  if (existing.documents.length > 0) {
    gamification = existing.documents[0];
  }

  // Calculer les points nécessaires pour le prochain niveau
  const currentLevel = gamification.level || 1;
  const pointsForNextLevel = calculatePointsForLevel(currentLevel + 1);
  const currentLevelPoints = calculatePointsForLevel(currentLevel);
  const progressToNextLevel = gamification.totalPoints - currentLevelPoints;
  const pointsNeeded = pointsForNextLevel - currentLevelPoints;

  // Enrichir les badges avec leurs informations
  const earnedBadges = (gamification.badges || []).map(badgeId => {
    const badge = Object.values(BADGES).find(b => b.id === badgeId);
    return badge ? {
      id: badge.id,
      name: badge.name,
      description: badge.description,
      icon: badge.icon
    } : null;
  }).filter(Boolean);

  // Badges disponibles (non encore obtenus)
  const availableBadges = Object.values(BADGES)
    .filter(b => !gamification.badges?.includes(b.id))
    .map(b => ({
      id: b.id,
      name: b.name,
      description: b.description,
      icon: b.icon,
      progress: calculateBadgeProgress(b, stats)
    }));

  return res.json({
    success: true,
    data: {
      userId,
      stats,
      gamification: {
        totalPoints: gamification.totalPoints || 0,
        level: currentLevel,
        progressToNextLevel,
        pointsNeeded,
        progressPercentage: Math.round((progressToNextLevel / pointsNeeded) * 100)
      },
      badges: {
        earned: earnedBadges,
        available: availableBadges,
        totalEarned: earnedBadges.length,
        totalAvailable: Object.keys(BADGES).length
      }
    }
  });
}

/**
 * Récupère les statistiques brutes d'un utilisateur
 */
async function getUserStatistics(databases, databaseId, userId) {
  // Événements rejoints
  const eventsJoined = await databases.listDocuments(
    databaseId,
    COLLECTIONS.EVENT_PARTICIPANTS,
    [
      Query.equal('userId', userId),
      Query.equal('status', 'confirmed')
    ]
  );

  // Événements créés
  const eventsCreated = await databases.listDocuments(
    databaseId,
    COLLECTIONS.EVENTS,
    [Query.equal('organizerId', userId)]
  );

  // Followers
  const followers = await databases.listDocuments(
    databaseId,
    COLLECTIONS.FOLLOWERS,
    [Query.equal('followingId', userId)]
  );

  // Following
  const following = await databases.listDocuments(
    databaseId,
    COLLECTIONS.FOLLOWERS,
    [Query.equal('followerId', userId)]
  );

  // Gamification
  const gamification = await databases.listDocuments(
    databaseId,
    COLLECTIONS.GAMIFICATION,
    [Query.equal('userId', userId)]
  );

  const level = gamification.documents.length > 0
    ? gamification.documents[0].level || 1
    : 1;

  return {
    eventsJoined: eventsJoined.total,
    eventsCreated: eventsCreated.total,
    followersCount: followers.total,
    followingCount: following.total,
    level
  };
}

/**
 * Calcule les points nécessaires pour atteindre un niveau
 */
function calculatePointsForLevel(level) {
  // Formule: somme de (100 * n) pour n de 1 à level-1
  // = 100 * (level-1) * level / 2
  if (level <= 1) return 0;
  return 50 * (level - 1) * level;
}

/**
 * Calcule la progression vers un badge
 */
function calculateBadgeProgress(badge, stats) {
  // Extraire les seuils des conditions (simplifié)
  const conditionStr = badge.condition.toString();

  if (conditionStr.includes('eventsJoined')) {
    const match = conditionStr.match(/eventsJoined\s*>=\s*(\d+)/);
    if (match) {
      const target = parseInt(match[1]);
      return {
        current: stats.eventsJoined,
        target,
        percentage: Math.min(100, Math.round((stats.eventsJoined / target) * 100))
      };
    }
  }

  if (conditionStr.includes('eventsCreated')) {
    const match = conditionStr.match(/eventsCreated\s*>=\s*(\d+)/);
    if (match) {
      const target = parseInt(match[1]);
      return {
        current: stats.eventsCreated,
        target,
        percentage: Math.min(100, Math.round((stats.eventsCreated / target) * 100))
      };
    }
  }

  if (conditionStr.includes('followersCount')) {
    const match = conditionStr.match(/followersCount\s*>=\s*(\d+)/);
    if (match) {
      const target = parseInt(match[1]);
      return {
        current: stats.followersCount,
        target,
        percentage: Math.min(100, Math.round((stats.followersCount / target) * 100))
      };
    }
  }

  if (conditionStr.includes('level')) {
    const match = conditionStr.match(/level\s*>=\s*(\d+)/);
    if (match) {
      const target = parseInt(match[1]);
      return {
        current: stats.level,
        target,
        percentage: Math.min(100, Math.round((stats.level / target) * 100))
      };
    }
  }

  // Badge manuel
  return {
    current: 0,
    target: 1,
    percentage: 0,
    manual: true
  };
}
