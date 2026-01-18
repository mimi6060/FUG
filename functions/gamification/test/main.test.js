/**
 * Tests for gamification Appwrite Function
 *
 * Coverage:
 * - check_achievements success
 * - badge attribution
 * - leaderboard calculation
 * - get_user_stats
 */

import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';

// Mock node-appwrite before importing the function
const mockDatabases = {
  getDocument: jest.fn(),
  listDocuments: jest.fn(),
  createDocument: jest.fn(),
  updateDocument: jest.fn(),
  deleteDocument: jest.fn()
};

const mockClient = {
  setEndpoint: jest.fn().mockReturnThis(),
  setProject: jest.fn().mockReturnThis(),
  setKey: jest.fn().mockReturnThis()
};

jest.unstable_mockModule('node-appwrite', () => ({
  Client: jest.fn(() => mockClient),
  Databases: jest.fn(() => mockDatabases),
  Query: {
    equal: (attr, val) => ({ type: 'equal', attribute: attr, values: [val] }),
    orderDesc: (attr) => ({ type: 'orderDesc', attribute: attr }),
    limit: (val) => ({ type: 'limit', values: [val] })
  },
  ID: {
    unique: () => `unique_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }
}));

// Import after mocking
const { default: gamification } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeGamification,
  generateFakeParticipation,
  generateFakeEvent,
  generateFakeFollow,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('gamification function', () => {
  let user;
  let userGamification;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default test data
    user = generateFakeUser({
      $id: 'user_123',
      username: 'testuser',
      displayName: 'Test User'
    });

    userGamification = generateFakeGamification({
      $id: 'gamification_123',
      userId: user.$id,
      totalPoints: 100,
      level: 2,
      badges: []
    });

    // Default mock implementations
    mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
      if (docId === user.$id) return user;
      const error = new Error('Document not found');
      error.code = 404;
      throw error;
    });

    mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });
    mockDatabases.createDocument.mockImplementation(async (dbId, collId, docId, data) => ({
      $id: docId.includes('unique') ? `doc_${Date.now()}` : docId,
      ...data
    }));
    mockDatabases.updateDocument.mockImplementation(async (dbId, collId, docId, data) => ({
      $id: docId,
      ...data
    }));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('action validation', () => {
    it('should reject when action is missing', async () => {
      const context = createMockContext({
        body: {}
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('action');
      expect(result.statusCode).toBe(400);
    });

    it('should reject unknown action', async () => {
      const context = createMockContext({
        body: { action: 'unknown_action' }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('inconnue');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('check_achievements success', () => {
    beforeEach(() => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [userGamification], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: [], total: 0 };
        }
        if (collId === 'events') {
          return { documents: [], total: 0 };
        }
        if (collId === 'followers') {
          return { documents: [], total: 0 };
        }
        return { documents: [], total: 0 };
      });
    });

    it('should check achievements for a user', async () => {
      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.userId).toBe(user.$id);
      expect(result.data.data.stats).toBeDefined();
    });

    it('should return user stats', async () => {
      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.stats).toHaveProperty('eventsJoined');
      expect(result.data.data.stats).toHaveProperty('eventsCreated');
      expect(result.data.data.stats).toHaveProperty('followersCount');
      expect(result.data.data.stats).toHaveProperty('followingCount');
    });

    it('should require userId for check_achievements', async () => {
      const context = createMockContext({
        body: {
          action: 'check_achievements'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('userId');
      expect(result.statusCode).toBe(400);
    });

    it('should create gamification document if not exists', async () => {
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      await gamification(context);

      const createCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );
      expect(createCalls.length).toBeGreaterThan(0);
    });
  });

  describe('badge attribution', () => {
    it('should award first_event badge when user joins first event', async () => {
      const participation = generateFakeParticipation({
        userId: user.$id,
        status: 'confirmed'
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: [participation], total: 1 }; // 1 event joined
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.newBadgesEarned).toContainEqual(
        expect.objectContaining({ id: 'first_event' })
      );
    });

    it('should award event_enthusiast badge for 10 events joined', async () => {
      const participations = Array(10).fill(null).map(() =>
        generateFakeParticipation({ userId: user.$id, status: 'confirmed' })
      );

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: ['first_event'] }], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: participations, total: 10 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.newBadgesEarned).toContainEqual(
        expect.objectContaining({ id: 'event_enthusiast' })
      );
    });

    it('should award event_creator badge for creating first event', async () => {
      const event = generateFakeEvent({ organizerId: user.$id });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        if (collId === 'events') {
          return { documents: [event], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.newBadgesEarned).toContainEqual(
        expect.objectContaining({ id: 'event_creator' })
      );
    });

    it('should award social_butterfly badge for 10 followers', async () => {
      const followers = Array(10).fill(null).map(() =>
        generateFakeFollow({ followingId: user.$id })
      );

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        if (collId === 'followers') {
          const query = queries?.find(q => q?.attribute === 'followingId');
          if (query?.values[0] === user.$id) {
            return { documents: followers, total: 10 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.newBadgesEarned).toContainEqual(
        expect.objectContaining({ id: 'social_butterfly' })
      );
    });

    it('should not award already earned badges', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return {
            documents: [{ ...userGamification, badges: ['first_event'] }],
            total: 1
          };
        }
        if (collId === 'event_participants') {
          return { documents: [generateFakeParticipation({ userId: user.$id, status: 'confirmed' })], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.newBadgesEarned).not.toContainEqual(
        expect.objectContaining({ id: 'first_event' })
      );
    });

    it('should create notifications for new badges', async () => {
      const participation = generateFakeParticipation({
        userId: user.$id,
        status: 'confirmed'
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: [participation], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      await gamification(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      expect(notificationCalls.length).toBeGreaterThan(0);
      expect(notificationCalls[0][3].type).toBe('badge_earned');
    });
  });

  describe('award_badge action', () => {
    it('should manually award a badge to user', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'award_badge',
          userId: user.$id,
          badgeId: 'early_adopter'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.badge.id).toBe('early_adopter');
    });

    it('should require userId for award_badge', async () => {
      const context = createMockContext({
        body: {
          action: 'award_badge',
          badgeId: 'early_adopter'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('userId');
    });

    it('should require badgeId for award_badge', async () => {
      const context = createMockContext({
        body: {
          action: 'award_badge',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('badgeId');
    });

    it('should reject unknown badge', async () => {
      const context = createMockContext({
        body: {
          action: 'award_badge',
          userId: user.$id,
          badgeId: 'unknown_badge'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('inconnu');
    });

    it('should reject if user already has badge', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return {
            documents: [{ ...userGamification, badges: ['early_adopter'] }],
            total: 1
          };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'award_badge',
          userId: user.$id,
          badgeId: 'early_adopter'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('déjà');
      expect(result.statusCode).toBe(409);
    });
  });

  describe('leaderboard calculation', () => {
    it('should calculate leaderboard successfully', async () => {
      const gamificationDocs = [
        generateFakeGamification({ userId: 'user_1', totalPoints: 500, level: 5 }),
        generateFakeGamification({ userId: 'user_2', totalPoints: 300, level: 3 }),
        generateFakeGamification({ userId: 'user_3', totalPoints: 100, level: 1 })
      ];

      const users = {
        user_1: generateFakeUser({ $id: 'user_1', username: 'top_player' }),
        user_2: generateFakeUser({ $id: 'user_2', username: 'mid_player' }),
        user_3: generateFakeUser({ $id: 'user_3', username: 'new_player' })
      };

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: gamificationDocs, total: 3 };
        }
        return { documents: [], total: 0 };
      });

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (users[docId]) return users[docId];
        const error = new Error('Not found');
        error.code = 404;
        throw error;
      });

      // Mock updateDocument for leaderboard (will fail, triggering create)
      mockDatabases.updateDocument.mockRejectedValue(new Error('Not found'));

      const context = createMockContext({
        body: {
          action: 'calculate_leaderboard',
          period: 'weekly'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.period).toBe('weekly');
      expect(result.data.data.leaderboard.length).toBe(3);
    });

    it('should order leaderboard by points descending', async () => {
      const gamificationDocs = [
        generateFakeGamification({ userId: 'user_low', totalPoints: 100 }),
        generateFakeGamification({ userId: 'user_high', totalPoints: 500 }),
        generateFakeGamification({ userId: 'user_mid', totalPoints: 300 })
      ];

      const users = {
        user_low: generateFakeUser({ $id: 'user_low' }),
        user_high: generateFakeUser({ $id: 'user_high' }),
        user_mid: generateFakeUser({ $id: 'user_mid' })
      };

      mockDatabases.listDocuments.mockResolvedValue({ documents: gamificationDocs, total: 3 });
      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => users[docId] || {});
      mockDatabases.updateDocument.mockRejectedValue(new Error('Not found'));

      const context = createMockContext({
        body: {
          action: 'calculate_leaderboard',
          period: 'all_time'
        }
      });

      const result = await gamification(context);

      // First user should have highest points
      expect(result.data.data.leaderboard[0].rank).toBe(1);
    });

    it('should support different periods', async () => {
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });
      mockDatabases.updateDocument.mockRejectedValue(new Error('Not found'));

      const periods = ['daily', 'weekly', 'monthly', 'all_time'];

      for (const period of periods) {
        const context = createMockContext({
          body: {
            action: 'calculate_leaderboard',
            period
          }
        });

        const result = await gamification(context);

        expect(result.data.success).toBe(true);
        expect(result.data.data.period).toBe(period);
      }
    });

    it('should save leaderboard to database', async () => {
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });
      mockDatabases.updateDocument.mockRejectedValue(new Error('Not found'));

      const context = createMockContext({
        body: {
          action: 'calculate_leaderboard',
          period: 'weekly'
        }
      });

      await gamification(context);

      const leaderboardCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'leaderboard'
      );
      expect(leaderboardCalls.length).toBe(1);
      expect(leaderboardCalls[0][2]).toBe('leaderboard_weekly');
    });
  });

  describe('get_user_stats', () => {
    beforeEach(() => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [userGamification], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: [], total: 5 }; // 5 events joined
        }
        if (collId === 'events') {
          return { documents: [], total: 2 }; // 2 events created
        }
        if (collId === 'followers') {
          return { documents: [], total: 15 }; // 15 followers or following
        }
        return { documents: [], total: 0 };
      });
    });

    it('should return user stats successfully', async () => {
      const context = createMockContext({
        body: {
          action: 'get_user_stats',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.userId).toBe(user.$id);
      expect(result.data.data.stats).toBeDefined();
      expect(result.data.data.gamification).toBeDefined();
      expect(result.data.data.badges).toBeDefined();
    });

    it('should return gamification progress info', async () => {
      const context = createMockContext({
        body: {
          action: 'get_user_stats',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.gamification).toHaveProperty('totalPoints');
      expect(result.data.data.gamification).toHaveProperty('level');
      expect(result.data.data.gamification).toHaveProperty('progressToNextLevel');
      expect(result.data.data.gamification).toHaveProperty('progressPercentage');
    });

    it('should return earned and available badges', async () => {
      const gamificationWithBadges = {
        ...userGamification,
        badges: ['first_event', 'event_creator']
      };

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [gamificationWithBadges], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'get_user_stats',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.badges.earned.length).toBe(2);
      expect(result.data.data.badges.totalEarned).toBe(2);
      expect(result.data.data.badges.available.length).toBeGreaterThan(0);
    });

    it('should include badge progress for unearned badges', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [{ ...userGamification, badges: [] }], total: 1 };
        }
        if (collId === 'event_participants') {
          return { documents: [], total: 5 }; // 5 events joined (50% progress to 10)
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'get_user_stats',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      const eventEnthusiastBadge = result.data.data.badges.available.find(
        b => b.id === 'event_enthusiast'
      );
      expect(eventEnthusiastBadge).toBeDefined();
      expect(eventEnthusiastBadge.progress).toBeDefined();
      expect(eventEnthusiastBadge.progress.current).toBe(5);
      expect(eventEnthusiastBadge.progress.target).toBe(10);
    });

    it('should require userId for get_user_stats', async () => {
      const context = createMockContext({
        body: {
          action: 'get_user_stats'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('userId');
    });
  });

  describe('get_badges action', () => {
    it('should return all available badges', async () => {
      const context = createMockContext({
        body: {
          action: 'get_badges'
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.badges).toBeDefined();
      expect(Array.isArray(result.data.data.badges)).toBe(true);
      expect(result.data.data.badges.length).toBeGreaterThan(0);
    });

    it('should return badge details', async () => {
      const context = createMockContext({
        body: {
          action: 'get_badges'
        }
      });

      const result = await gamification(context);

      const firstBadge = result.data.data.badges[0];
      expect(firstBadge).toHaveProperty('id');
      expect(firstBadge).toHaveProperty('name');
      expect(firstBadge).toHaveProperty('description');
      expect(firstBadge).toHaveProperty('icon');
    });
  });

  describe('level calculation', () => {
    it('should correctly calculate user level based on points', async () => {
      const gamificationHighLevel = generateFakeGamification({
        userId: user.$id,
        totalPoints: 1000,
        level: 5
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          return { documents: [gamificationHighLevel], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          action: 'get_user_stats',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.data.gamification.level).toBe(5);
    });
  });

  describe('error handling', () => {
    it('should handle database errors gracefully', async () => {
      mockDatabases.listDocuments.mockRejectedValue(new Error('Database error'));

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      const result = await gamification(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });

    it('should log errors appropriately', async () => {
      mockDatabases.listDocuments.mockRejectedValue(new Error('Test error'));

      const context = createMockContext({
        body: {
          action: 'check_achievements',
          userId: user.$id
        }
      });

      await gamification(context);

      expect(context.error).toHaveBeenCalled();
    });
  });
});
