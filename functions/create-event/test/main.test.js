/**
 * Tests for create-event Appwrite Function
 *
 * Coverage:
 * - create success
 * - create without required fields (should fail)
 * - create with past date (should fail)
 * - notifications to followers
 * - points attribution
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
const { default: createEvent } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeFollow,
  generateFakeGamification,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('create-event function', () => {
  let organizer;
  let follower1;
  let follower2;
  let validEventPayload;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default test data
    organizer = generateFakeUser({
      $id: 'organizer_123',
      username: 'organizer',
      displayName: 'Event Organizer'
    });

    follower1 = generateFakeUser({ $id: 'follower_1' });
    follower2 = generateFakeUser({ $id: 'follower_2' });

    // Valid event payload
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days from now
    validEventPayload = {
      organizerId: organizer.$id,
      title: 'Epic Gaming Tournament',
      description: 'Join us for an amazing gaming tournament with prizes and fun! This is a detailed description.',
      startDate: futureDate.toISOString(),
      location: 'Paris Gaming Arena',
      category: 'gaming',
      maxParticipants: 50,
      tags: ['tournament', 'gaming', 'esport']
    };

    // Default mock implementations
    mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
      if (docId === organizer.$id) return organizer;
      const error = new Error('Document not found');
      error.code = 404;
      throw error;
    });

    mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });
    mockDatabases.createDocument.mockImplementation(async (dbId, collId, docId, data) => ({
      $id: docId.includes('unique') ? `doc_${Date.now()}_${Math.random().toString(36).substr(2, 6)}` : docId,
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

  describe('create success', () => {
    it('should create an event successfully with all required fields', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.eventId).toBeDefined();
      expect(result.data.data.title).toBe(validEventPayload.title);
      expect(result.data.data.category).toBe(validEventPayload.category);
    });

    it('should create event document in database', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const eventCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(eventCalls.length).toBe(1);
      expect(eventCalls[0][3].title).toBe(validEventPayload.title);
      expect(eventCalls[0][3].description).toBe(validEventPayload.description);
      expect(eventCalls[0][3].organizerId).toBe(organizer.$id);
      expect(eventCalls[0][3].status).toBe('upcoming');
    });

    it('should automatically add organizer as participant', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const participantCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'event_participants'
      );
      expect(participantCalls.length).toBe(1);
      expect(participantCalls[0][3].userId).toBe(organizer.$id);
      expect(participantCalls[0][3].role).toBe('organizer');
      expect(participantCalls[0][3].status).toBe('confirmed');
    });

    it('should set initial participant count to 1', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(updateCalls.length).toBe(1);
      expect(updateCalls[0][3].participantCount).toBe(1);
    });

    it('should create event with optional fields', async () => {
      const payloadWithOptionals = {
        ...validEventPayload,
        endDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString(),
        latitude: 48.8566,
        longitude: 2.3522,
        imageUrl: 'https://example.com/image.jpg'
      };

      const context = createMockContext({
        body: payloadWithOptionals
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
    });

    it('should return total events created count', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.data.totalEventsCreated).toBe(1);
    });
  });

  describe('create without required fields (should fail)', () => {
    it('should reject when organizerId is missing', async () => {
      const { organizerId, ...payloadWithoutOrganizer } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutOrganizer
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when title is missing', async () => {
      const { title, ...payloadWithoutTitle } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutTitle
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when description is missing', async () => {
      const { description, ...payloadWithoutDescription } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutDescription
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });

    it('should reject when startDate is missing', async () => {
      const { startDate, ...payloadWithoutDate } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutDate
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });

    it('should reject when location is missing', async () => {
      const { location, ...payloadWithoutLocation } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutLocation
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });

    it('should reject when category is missing', async () => {
      const { category, ...payloadWithoutCategory } = validEventPayload;

      const context = createMockContext({
        body: payloadWithoutCategory
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });

    it('should reject when title is too short', async () => {
      const context = createMockContext({
        body: { ...validEventPayload, title: 'Hi' } // Less than 5 chars
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('titre');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when title is too long', async () => {
      const context = createMockContext({
        body: { ...validEventPayload, title: 'A'.repeat(101) } // More than 100 chars
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('titre');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when description is too short', async () => {
      const context = createMockContext({
        body: { ...validEventPayload, description: 'Short' } // Less than 20 chars
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('description');
      expect(result.statusCode).toBe(400);
    });

    it('should reject invalid category', async () => {
      const context = createMockContext({
        body: { ...validEventPayload, category: 'invalid_category' }
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('Catégorie invalide');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('create with past date (should fail)', () => {
    it('should reject when startDate is in the past', async () => {
      const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000); // Yesterday

      const context = createMockContext({
        body: { ...validEventPayload, startDate: pastDate.toISOString() }
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('futur');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when startDate is now (edge case)', async () => {
      const now = new Date(Date.now() - 1000); // 1 second ago

      const context = createMockContext({
        body: { ...validEventPayload, startDate: now.toISOString() }
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(400);
    });

    it('should reject invalid date format', async () => {
      const context = createMockContext({
        body: { ...validEventPayload, startDate: 'invalid-date' }
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('date');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('notifications to followers', () => {
    beforeEach(() => {
      // Setup followers
      const follow1 = generateFakeFollow({
        followerId: follower1.$id,
        followingId: organizer.$id
      });
      const follow2 = generateFakeFollow({
        followerId: follower2.$id,
        followingId: organizer.$id
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'followers') {
          return { documents: [follow1, follow2], total: 2 };
        }
        if (collId === 'events') {
          return { documents: [], total: 0 }; // No existing events
        }
        return { documents: [], total: 0 };
      });
    });

    it('should notify all followers when event is created', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      // Should have notifications for both followers
      expect(notificationCalls.length).toBe(2);
    });

    it('should include event details in notification', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      expect(notificationCalls[0][3].type).toBe('new_event');
      expect(notificationCalls[0][3].message).toContain(validEventPayload.title);
      expect(notificationCalls[0][3].message).toContain(organizer.displayName);
    });

    it('should include event data in notification payload', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      const notificationData = JSON.parse(notificationCalls[0][3].data);
      expect(notificationData.eventTitle).toBe(validEventPayload.title);
      expect(notificationData.eventLocation).toBe(validEventPayload.location);
      expect(notificationData.eventCategory).toBe(validEventPayload.category);
    });

    it('should return followers notified count', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.data.followersNotified).toBe(2);
    });

    it('should handle organizer with no followers', async () => {
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.followersNotified).toBe(0);
    });
  });

  describe('points attribution', () => {
    it('should award base points for creating an event', async () => {
      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBeGreaterThanOrEqual(25); // CREATE_EVENT points
    });

    it('should award first event bonus for first event', async () => {
      // No existing events for organizer
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBe(75); // 25 + 50 first event bonus
      expect(result.data.data.bonuses).toContainEqual(
        expect.objectContaining({ type: 'first_event' })
      );
    });

    it('should not award first event bonus if not first event', async () => {
      // Organizer has existing events
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'events') {
          return { documents: [{ $id: 'existing_event' }], total: 1 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBe(25); // Only base points
      expect(result.data.data.bonuses).toHaveLength(0);
    });

    it('should award milestone bonus for 5th event', async () => {
      // Organizer has 4 existing events
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'events') {
          return { documents: Array(4).fill({ $id: 'event' }), total: 4 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBe(125); // 25 + 100 milestone
      expect(result.data.data.bonuses).toContainEqual(
        expect.objectContaining({ type: 'milestone_5_events' })
      );
    });

    it('should award milestone bonus for 10th event', async () => {
      // Organizer has 9 existing events
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'events') {
          return { documents: Array(9).fill({ $id: 'event' }), total: 9 };
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBe(225); // 25 + 200 milestone
      expect(result.data.data.bonuses).toContainEqual(
        expect.objectContaining({ type: 'milestone_10_events' })
      );
    });

    it('should create gamification document for new user', async () => {
      mockDatabases.listDocuments.mockResolvedValue({ documents: [], total: 0 });

      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      const gamificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );

      expect(gamificationCalls.length).toBeGreaterThan(0);
    });
  });

  describe('valid categories', () => {
    const validCategories = [
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

    validCategories.forEach(category => {
      it(`should accept category: ${category}`, async () => {
        const context = createMockContext({
          body: { ...validEventPayload, category }
        });

        const result = await createEvent(context);

        expect(result.data.success).toBe(true);
        expect(result.data.data.category).toBe(category);
      });
    });
  });

  describe('organizer not found', () => {
    it('should handle when organizer does not exist', async () => {
      mockDatabases.getDocument.mockRejectedValue(
        Object.assign(new Error('Document not found'), { code: 404 })
      );

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(404);
    });
  });

  describe('error handling', () => {
    it('should handle database errors gracefully', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Database error'));

      const context = createMockContext({
        body: validEventPayload
      });

      const result = await createEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });

    it('should log errors appropriately', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Test error'));

      const context = createMockContext({
        body: validEventPayload
      });

      await createEvent(context);

      expect(context.error).toHaveBeenCalled();
    });
  });
});
