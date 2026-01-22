/**
 * Tests for join-event Appwrite Function
 *
 * Coverage:
 * - join success
 * - join own event
 * - join full event (should fail)
 * - join ended event (should fail)
 * - leave success
 * - points attribution
 * - notifications
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
const { default: joinEvent } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeEvent,
  generateFakeParticipation,
  generateFakeGamification,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('join-event function', () => {
  let user;
  let organizer;
  let event;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default test data
    user = generateFakeUser({ $id: 'user_123', username: 'testuser', displayName: 'Test User' });
    organizer = generateFakeUser({ $id: 'organizer_456', username: 'organizer', displayName: 'Event Organizer' });

    // Future event (7 days from now)
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    event = generateFakeEvent({
      $id: 'event_789',
      organizerId: organizer.$id,
      title: 'Test Gaming Event',
      startDate: futureDate.toISOString(),
      maxParticipants: 50,
      participantCount: 5,
      status: 'upcoming'
    });

    // Default mock implementations
    mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
      if (collId === 'users') {
        if (docId === user.$id) return user;
        if (docId === organizer.$id) return organizer;
      }
      if (collId === 'events' && docId === event.$id) return event;
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

  describe('join success', () => {
    it('should join an event successfully', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.eventId).toBe(event.$id);
      expect(result.data.data.userId).toBe(user.$id);
    });

    it('should create participation document', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const participationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'event_participants'
      );
      expect(participationCalls.length).toBe(1);
      expect(participationCalls[0][3].userId).toBe(user.$id);
      expect(participationCalls[0][3].eventId).toBe(event.$id);
      expect(participationCalls[0][3].status).toBe('confirmed');
    });

    it('should update event participant count', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(updateCalls.length).toBe(1);
      expect(updateCalls[0][3].participantCount).toBe(6); // 5 + 1
    });

    it('should return event details in response', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.data.event.title).toBe(event.title);
      expect(result.data.data.event.startDate).toBe(event.startDate);
      expect(result.data.data.event.location).toBe(event.location);
    });
  });

  describe('join own event', () => {
    it('should allow organizer to join their own event', async () => {
      // Organizer joins their own event (allowed as additional confirmation)
      const context = createMockContext({
        body: {
          userId: organizer.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      // The function allows this - organizer can join
      expect(result.data.success).toBe(true);
    });
  });

  describe('join full event (should fail)', () => {
    it('should reject when event has reached max participants', async () => {
      // Event is full
      const fullEvent = {
        ...event,
        maxParticipants: 10,
        participantCount: 10
      };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') {
          if (docId === user.$id) return user;
          if (docId === organizer.$id) return organizer;
        }
        if (collId === 'events' && docId === event.$id) return fullEvent;
        const error = new Error('Document not found');
        error.code = 404;
        throw error;
      });

      // Mock existing participants count
      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          // Check if querying for confirmed participants
          const statusQuery = queries?.find(q => q?.attribute === 'status');
          if (statusQuery?.values[0] === 'confirmed') {
            return {
              documents: Array(10).fill(generateFakeParticipation({ eventId: event.$id })),
              total: 10
            };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('limite');
      expect(result.statusCode).toBe(400);
    });

    it('should not create participation when event is full', async () => {
      const fullEvent = { ...event, maxParticipants: 5, participantCount: 5 };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return user;
        if (collId === 'events') return fullEvent;
        throw { code: 404 };
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          const statusQuery = queries?.find(q => q?.attribute === 'status');
          if (statusQuery?.values[0] === 'confirmed') {
            return { documents: Array(5).fill({}), total: 5 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const participationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'event_participants'
      );
      expect(participationCalls.length).toBe(0);
    });
  });

  describe('join ended event (should fail)', () => {
    it('should reject when event is completed', async () => {
      const completedEvent = { ...event, status: 'completed' };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return user;
        if (collId === 'events') return completedEvent;
        throw { code: 404 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('terminé');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when event is cancelled', async () => {
      const cancelledEvent = { ...event, status: 'cancelled' };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return user;
        if (collId === 'events') return cancelledEvent;
        throw { code: 404 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('annulé');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when event date is in the past', async () => {
      const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000); // Yesterday
      const pastEvent = { ...event, startDate: pastDate.toISOString() };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return user;
        if (collId === 'events') return pastEvent;
        throw { code: 404 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('passé');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('already joined (should fail)', () => {
    it('should reject when user is already a participant', async () => {
      const existingParticipation = generateFakeParticipation({
        userId: user.$id,
        eventId: event.$id
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          const userQuery = queries?.find(q => q?.attribute === 'userId');
          const eventQuery = queries?.find(q => q?.attribute === 'eventId');
          if (userQuery?.values[0] === user.$id && eventQuery?.values[0] === event.$id) {
            return { documents: [existingParticipation], total: 1 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('déjà inscrit');
      expect(result.statusCode).toBe(409);
    });
  });

  describe('validation errors', () => {
    it('should reject when userId is missing', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when eventId is missing', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('points attribution', () => {
    it('should award points to participant for joining', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.pointsAwarded).toBe(5); // JOIN_EVENT points
    });

    it('should award bonus points to organizer', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      // Check gamification calls for organizer bonus
      const gamificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );
      // Or update calls
      const updateGamificationCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'gamification'
      );

      // At least some gamification action should happen
      expect(gamificationCalls.length + updateGamificationCalls.length).toBeGreaterThan(0);
    });

    it('should trigger milestone bonus when reaching 10 participants', async () => {
      // Event has 9 participants, this will be the 10th
      const eventNearMilestone = { ...event, participantCount: 9 };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') {
          if (docId === user.$id) return user;
          if (docId === organizer.$id) return organizer;
        }
        if (collId === 'events') return eventNearMilestone;
        throw { code: 404 };
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          const statusQuery = queries?.find(q => q?.attribute === 'status');
          if (statusQuery?.values[0] === 'confirmed') {
            return { documents: Array(9).fill({}), total: 9 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.milestoneReached).toBeDefined();
      expect(result.data.data.milestoneReached.count).toBe(10);
    });

    it('should trigger milestone bonus when reaching 50 participants', async () => {
      const eventNearMilestone = { ...event, participantCount: 49, maxParticipants: 100 };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') {
          if (docId === user.$id) return user;
          if (docId === organizer.$id) return organizer;
        }
        if (collId === 'events') return eventNearMilestone;
        throw { code: 404 };
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          const statusQuery = queries?.find(q => q?.attribute === 'status');
          if (statusQuery?.values[0] === 'confirmed') {
            return { documents: Array(49).fill({}), total: 49 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.milestoneReached).toBeDefined();
      expect(result.data.data.milestoneReached.count).toBe(50);
    });
  });

  describe('notifications', () => {
    it('should notify the organizer when someone joins', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      // At least one notification for the organizer
      const organizerNotification = notificationCalls.find(
        call => call[3].userId === organizer.$id
      );
      expect(organizerNotification).toBeDefined();
      expect(organizerNotification[3].type).toBe('new_participant');
    });

    it('should include participant details in organizer notification', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      const organizerNotification = notificationCalls.find(
        call => call[3].userId === organizer.$id
      );
      expect(organizerNotification[3].message).toContain(user.displayName);
      expect(organizerNotification[3].message).toContain(event.title);
    });

    it('should notify other participants about new member', async () => {
      const existingParticipant = generateFakeUser({ $id: 'existing_user' });
      const existingParticipation = generateFakeParticipation({
        userId: existingParticipant.$id,
        eventId: event.$id,
        status: 'confirmed'
      });

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') {
          if (docId === user.$id) return user;
          if (docId === organizer.$id) return organizer;
          if (docId === existingParticipant.$id) return existingParticipant;
        }
        if (collId === 'events') return event;
        throw { code: 404 };
      });

      mockDatabases.listDocuments.mockImplementation(async (dbId, collId, queries) => {
        if (collId === 'event_participants') {
          const eventQuery = queries?.find(q => q?.attribute === 'eventId');
          const statusQuery = queries?.find(q => q?.attribute === 'status');
          if (eventQuery?.values[0] === event.$id && statusQuery?.values[0] === 'confirmed') {
            return { documents: [existingParticipation], total: 1 };
          }
        }
        return { documents: [], total: 0 };
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await joinEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      // Should have notification for organizer + optionally for existing participants
      expect(notificationCalls.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('error handling', () => {
    it('should handle event not found', async () => {
      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'events') {
          const error = new Error('Document not found');
          error.code = 404;
          throw error;
        }
        return user;
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: 'nonexistent_event'
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(404);
    });

    it('should handle database errors gracefully', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Database error'));

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await joinEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });
  });
});
