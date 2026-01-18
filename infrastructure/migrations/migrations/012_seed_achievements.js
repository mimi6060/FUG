/**
 * Migration: 012_seed_achievements
 * Created: Seed initial achievements data
 *
 * Inserts the base achievements for the gamification system
 */

import { ID } from 'node-appwrite';

// Achievement definitions
const ACHIEVEMENTS = [
  // ========================================
  // SOCIAL ACHIEVEMENTS
  // ========================================
  {
    achievementId: 'first_follower',
    name: 'Premier Fan',
    description: 'Obtenir votre premier follower',
    icon: 'person_add',
    category: 'social',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'social_butterfly',
    name: 'Papillon Social',
    description: 'Avoir 10 followers',
    icon: 'people',
    category: 'social',
    requiredPoints: 0,
    requiredCount: 10,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'influencer',
    name: 'Influenceur',
    description: 'Avoir 50 followers',
    icon: 'star',
    category: 'social',
    requiredPoints: 0,
    requiredCount: 50,
    tier: 'gold',
    isHidden: false,
  },
  {
    achievementId: 'celebrity',
    name: 'Celebrite',
    description: 'Avoir 100 followers',
    icon: 'verified',
    category: 'social',
    requiredPoints: 0,
    requiredCount: 100,
    tier: 'platinum',
    isHidden: false,
  },
  {
    achievementId: 'first_follow',
    name: 'Premier Abonnement',
    description: 'Suivre votre premier utilisateur',
    icon: 'favorite',
    category: 'social',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },

  // ========================================
  // EVENTS ACHIEVEMENTS
  // ========================================
  {
    achievementId: 'first_event',
    name: 'Organisateur Debutant',
    description: 'Creer votre premier evenement',
    icon: 'event',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'event_master',
    name: 'Maitre des Evenements',
    description: 'Creer 10 evenements',
    icon: 'event_available',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 10,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'event_legend',
    name: 'Legende des Evenements',
    description: 'Creer 50 evenements',
    icon: 'emoji_events',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 50,
    tier: 'gold',
    isHidden: false,
  },
  {
    achievementId: 'first_participation',
    name: 'Premier Pas',
    description: 'Participer a votre premier evenement',
    icon: 'directions_walk',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'event_enthusiast',
    name: 'Enthousiaste',
    description: 'Participer a 10 evenements',
    icon: 'directions_run',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 10,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'event_addict',
    name: 'Accro aux Evenements',
    description: 'Participer a 50 evenements',
    icon: 'sports_score',
    category: 'events',
    requiredPoints: 0,
    requiredCount: 50,
    tier: 'gold',
    isHidden: false,
  },

  // ========================================
  // ENGAGEMENT ACHIEVEMENTS
  // ========================================
  {
    achievementId: 'early_bird',
    name: 'Leve-Tot',
    description: 'Etre le premier inscrit a un evenement',
    icon: 'wb_sunny',
    category: 'engagement',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'reliable',
    name: 'Fiable',
    description: 'Assister a 5 evenements consecutifs',
    icon: 'verified_user',
    category: 'engagement',
    requiredPoints: 0,
    requiredCount: 5,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'perfect_attendance',
    name: 'Assiduite Parfaite',
    description: 'Ne jamais manquer un evenement inscrit (10+)',
    icon: 'military_tech',
    category: 'engagement',
    requiredPoints: 0,
    requiredCount: 10,
    tier: 'gold',
    isHidden: false,
  },

  // ========================================
  // MILESTONES ACHIEVEMENTS
  // ========================================
  {
    achievementId: 'level_5',
    name: 'Niveau 5',
    description: 'Atteindre le niveau 5',
    icon: 'looks_5',
    category: 'milestones',
    requiredPoints: 0,
    requiredCount: 5,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'level_10',
    name: 'Niveau 10',
    description: 'Atteindre le niveau 10',
    icon: 'looks_one',
    category: 'milestones',
    requiredPoints: 0,
    requiredCount: 10,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'level_25',
    name: 'Niveau 25',
    description: 'Atteindre le niveau 25',
    icon: 'workspace_premium',
    category: 'milestones',
    requiredPoints: 0,
    requiredCount: 25,
    tier: 'gold',
    isHidden: false,
  },
  {
    achievementId: 'level_50',
    name: 'Niveau 50',
    description: 'Atteindre le niveau 50',
    icon: 'diamond',
    category: 'milestones',
    requiredPoints: 0,
    requiredCount: 50,
    tier: 'platinum',
    isHidden: false,
  },
  {
    achievementId: 'points_100',
    name: 'Centurion',
    description: 'Accumuler 100 points',
    icon: 'hundred',
    category: 'milestones',
    requiredPoints: 100,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: false,
  },
  {
    achievementId: 'points_1000',
    name: 'Millionnaire',
    description: 'Accumuler 1000 points',
    icon: 'monetization_on',
    category: 'milestones',
    requiredPoints: 1000,
    requiredCount: 1,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'points_10000',
    name: 'Legend',
    description: 'Accumuler 10000 points',
    icon: 'auto_awesome',
    category: 'milestones',
    requiredPoints: 10000,
    requiredCount: 1,
    tier: 'gold',
    isHidden: false,
  },

  // ========================================
  // SPECIAL ACHIEVEMENTS
  // ========================================
  {
    achievementId: 'beta_tester',
    name: 'Beta Testeur',
    description: 'Faire partie des premiers utilisateurs',
    icon: 'bug_report',
    category: 'special',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'gold',
    isHidden: true,
  },
  {
    achievementId: 'night_owl',
    name: 'Oiseau de Nuit',
    description: 'Creer un evenement apres minuit',
    icon: 'nightlight',
    category: 'special',
    requiredPoints: 0,
    requiredCount: 1,
    tier: 'bronze',
    isHidden: true,
  },
  {
    achievementId: 'weekend_warrior',
    name: 'Guerrier du Weekend',
    description: 'Participer a 5 evenements le weekend',
    icon: 'weekend',
    category: 'special',
    requiredPoints: 0,
    requiredCount: 5,
    tier: 'silver',
    isHidden: false,
  },
  {
    achievementId: 'explorer',
    name: 'Explorateur',
    description: 'Participer a des evenements dans 5 categories differentes',
    icon: 'explore',
    category: 'special',
    requiredPoints: 0,
    requiredCount: 5,
    tier: 'silver',
    isHidden: false,
  },
];

export default {
  name: '012_seed_achievements',

  /**
   * Run the migration
   */
  async up(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'achievements';

    log.step('Seeding achievements...');

    let created = 0;
    let skipped = 0;

    for (const achievement of ACHIEVEMENTS) {
      try {
        await databases.createDocument(
          databaseId,
          collectionId,
          ID.unique(),
          achievement
        );
        log.info(`Created achievement: ${achievement.name}`);
        created++;
      } catch (error) {
        if (error.code === 409) {
          log.warn(`Achievement ${achievement.name} already exists, skipping...`);
          skipped++;
        } else {
          throw error;
        }
      }
    }

    log.success(`Seeded ${created} achievements (${skipped} skipped)`);
  },

  /**
   * Reverse the migration
   */
  async down(client, databases, log, config) {
    const databaseId = config.databaseId;
    const collectionId = 'achievements';

    log.step('Removing seeded achievements...');

    // Get all documents
    let deleted = 0;
    let cursor = null;

    do {
      const queries = [{ limit: 100 }];
      if (cursor) {
        queries.push({ cursorAfter: cursor });
      }

      const result = await databases.listDocuments(databaseId, collectionId, queries);

      for (const doc of result.documents) {
        try {
          await databases.deleteDocument(databaseId, collectionId, doc.$id);
          log.info(`Deleted achievement: ${doc.name}`);
          deleted++;
        } catch (error) {
          log.warn(`Failed to delete ${doc.name}: ${error.message}`);
        }
      }

      cursor = result.documents.length > 0 ? result.documents[result.documents.length - 1].$id : null;
    } while (cursor);

    log.success(`Deleted ${deleted} achievements`);
  },
};
