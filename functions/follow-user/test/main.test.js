/**
 * Tests for follow-user Appwrite Function
 *
 * Coverage:
 * - follow success
 * - follow self (should fail)
 * - follow already following (should fail)
 * - unfollow success
 * - unfollow not following (should fail)
 * - points attribution
 * - notification sent
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
    limit: (val) => ({ type: 'limit', values: [val] })
  },
  ID: {
    unique: () => `unique_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }
}));

// Import after mocking
const { default: followUser } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeFollow,
  generateFakeGamification,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('follow-user function', () => {
  let follower;
  let following;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default users
    follower = generateFakeUser({ $id: 'follower_123', username: 'follower', displayName: 'Follower User' });
    following = generateFakeUser({ $id: 'following_456', username: 'following', displayName: 'Following User' });

    // Default mock implementations
    mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
      if (docId === follower.$id) return follower;
      if (docId === following.$id) return following;
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

  describe('follow success', () => {
    it('should create a follow relationship successfully', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.followerId).toBe(follower.$id);
      expect(result.data.data.followingId).toBe(following.$id);
      expect(result.data.data.pointsAwarded).toBeDefined();
    });

    it('should create the follow document in the database', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      // Check that createDocument was called for followers collection
      const followerCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'followers'
      );
      expect(followerCalls.length).toBe(1);
      expect(followerCalls[0][3].followerId).toBe(follower.$id);
      expect(followerCalls[0][3].followingId).toBe(following.$id);
    });

    it('should update follower and following counts', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      // Check updateDocument calls for both users
      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'users'
      );
      expect(updateCalls.length).toBe(2);
    });
  });

  describe('follow self (should fail)', () => {
    it('should reject when user tries to follow themselves', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: follower.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('lui-même');
      expect(result.statusCode).toBe(400);
    });

    it('should not create any documents when following self', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: follower.$id
        }
      });

      await followUser(context);

      expect(mockDatabases.createDocument).not.toHaveBeenCalled();
    });
  });

  describe('follow already following (should fail)', () => {
    it('should reject when follow relationship already exists', async () => {
      // Mock existing follow relationship
      const existingFollow = generateFakeFollow({
        followerId: follower.$id,
        followingId: following.$id
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'followers') {
          return { documents: [existingFollow], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('existe déjà');
      expect(result.statusCode).toBe(409);
    });
  });

  describe('validation errors', () => {
    it('should reject when followerId is missing', async () => {
      const context = createMockContext({
        body: {
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when followingId is missing', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when body is empty', async () => {
      const context = createMockContext({
        body: {}
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });
  });

  describe('user not found', () => {
    it('should handle when follower does not exist', async () => {
      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (docId === following.$id) return following;
        const error = new Error('Document not found');
        error.code = 404;
        throw error;
      });

      const context = createMockContext({
        body: {
          followerId: 'nonexistent_user',
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(404);
    });

    it('should handle when following user does not exist', async () => {
      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (docId === follower.$id) return follower;
        const error = new Error('Document not found');
        error.code = 404;
        throw error;
      });

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: 'nonexistent_user'
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(404);
    });
  });

  describe('points attribution', () => {
    it('should award points to follower for following someone', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        // No existing follow, no existing gamification
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded.follower).toBe(5); // FOLLOW_SOMEONE points
    });

    it('should award points to following user for gaining a follower', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded.following).toBe(10); // GAIN_FOLLOWER points
    });

    it('should create gamification document if it does not exist', async () => {
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      // Check gamification document creation
      const gamificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );
      expect(gamificationCalls.length).toBeGreaterThan(0);
    });

    it('should update existing gamification document with new points', async () => {
      const existingGamification = generateFakeGamification({
        $id: 'gamification_123',
        userId: follower.$id,
        totalPoints: 50,
        level: 1
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'gamification') {
          // Check if it's querying for follower's gamification
          const userIdQuery = queries?.find(q => q?.attribute === 'userId');
          if (userIdQuery?.values[0] === follower.$id) {
            return { documents: [existingGamification], total: 1 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      // Check gamification update
      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );
      expect(updateCalls.length).toBeGreaterThan(0);
    });
  });

  describe('notification sent', () => {
    it('should create a notification for the followed user', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      // Check notification creation
      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );
      expect(notificationCalls.length).toBe(1);
      expect(notificationCalls[0][3].userId).toBe(following.$id);
      expect(notificationCalls[0][3].type).toBe('new_follower');
    });

    it('should include follower name in notification', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );
      expect(notificationCalls[0][3].message).toContain(follower.displayName);
    });

    it('should include follower data in notification payload', async () => {
      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );
      const notificationData = JSON.parse(notificationCalls[0][3].data);
      expect(notificationData.followerId).toBe(follower.$id);
      expect(notificationData.followerName).toBe(follower.displayName);
    });
  });

  describe('error handling', () => {
    it('should handle database errors gracefully', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Database connection error'));

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      const result = await followUser(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });

    it('should log errors appropriately', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Test error'));

      const context = createMockContext({
        body: {
          followerId: follower.$id,
          followingId: following.$id
        }
      });

      await followUser(context);

      expect(context.error).toHaveBeenCalled();
    });
  });
});
