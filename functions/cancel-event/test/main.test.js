/**
 * Tests for cancel-event Appwrite Function
 *
 * Coverage:
 * - cancel success
 * - cancel by non-organizer (should fail)
 * - cancel already cancelled event (should fail)
 * - cancel completed event (should fail)
 * - notifications to all participants
 * - participant status updates
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
const { default: cancelEvent } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeEvent,
  generateFakeParticipation,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('cancel-event function', () => {
  let organizer;
  let participant1;
  let participant2;
  let event;
  let organizerParticipation;
  let participation1;
  let participation2;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default test data
    organizer = generateFakeUser({
      $id: 'organizer_456',
      username: 'organizer',
      displayName: 'Event Organizer'
    });
    participant1 = generateFakeUser({
      $id: 'user_123',
      username: 'testuser1',
      displayName: 'Test User 1'
    });
    participant2 = generateFakeUser({
      $id: 'user_789',
      username: 'testuser2',
      displayName: 'Test User 2'
    });

    // Future event
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    event = generateFakeEvent({
      $id: 'event_001',
      creatorId: organizer.$id,
      organizerId: organizer.$id,
      title: 'Test Gaming Event',
      startDate: futureDate.toISOString(),
      participantCount: 3,
      status: 'published'
    });

    organizerParticipation = generateFakeParticipation({
      $id: 'participation_org',
      userId: organizer.$id,
      eventId: event.$id,
      status: 'confirmed',
      role: 'organizer'
    });

    participation1 = generateFakeParticipation({
      $id: 'participation_001',
      userId: participant1.$id,
      eventId: event.$id,
      status: 'confirmed',
      role: 'participant'
    });

    participation2 = generateFakeParticipation({
      $id: 'participation_002',
      userId: participant2.$id,
      eventId: event.$id,
      status: 'confirmed',
      role: 'participant'
    });

    // Default mock implementations
    mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
      if (collId === 'users') {
        if (docId === organizer.$id) return organizer;
        if (docId === participant1.$id) return participant1;
        if (docId === participant2.$id) return participant2;
      }
      if (collId === 'events' && docId === event.$id) return event;
      const error = new Error('Document not found');
      error.code = 404;
      throw error;
    });

    mockDatabases.listDocuments.mockResolvedValue({
      documents: [organizerParticipation, participation1, participation2],
      total: 3
    });

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

  describe('cancel success', () => {
    it('should cancel event successfully', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.eventId).toBe(event.$id);
      expect(result.data.data.status).toBe('cancelled');
      expect(result.data.data.cancelledAt).toBeDefined();
    });

    it('should cancel event with reason', async () => {
      const reason = 'Probleme de sante';
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id,
          reason
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.reason).toBe(reason);
    });

    it('should update event status to cancelled', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      await cancelEvent(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(updateCalls.length).toBe(1);
      expect(updateCalls[0][3].status).toBe('cancelled');
    });

    it('should update all participant statuses to cancelled', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      await cancelEvent(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'event_participants'
      );
      // All 3 participants (including organizer)
      expect(updateCalls.length).toBe(3);
      updateCalls.forEach(call => {
        expect(call[3].status).toBe('cancelled');
        expect(call[3].cancelledAt).toBeDefined();
      });
    });

    it('should return correct participant notification count (excluding organizer)', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      // 2 participants notified (excluding organizer)
      expect(result.data.data.participantsNotified).toBe(2);
    });
  });

  describe('cancel by non-organizer (should fail)', () => {
    it('should reject when user is not the organizer', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: participant1.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('organisateur');
      expect(result.statusCode).toBe(403);
    });
  });

  describe('cancel already cancelled event (should fail)', () => {
    it('should reject when event is already cancelled', async () => {
      const cancelledEvent = { ...event, status: 'cancelled' };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return organizer;
        if (collId === 'events') return cancelledEvent;
        throw { code: 404 };
      });

      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('deja ete annule');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('cancel completed event (should fail)', () => {
    it('should reject when event is already completed', async () => {
      const completedEvent = { ...event, status: 'completed' };

      mockDatabases.getDocument.mockImplementation(async (dbId, collId, docId) => {
        if (collId === 'users') return organizer;
        if (collId === 'events') return completedEvent;
        throw { code: 404 };
      });

      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('termine');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('notifications to all participants', () => {
    it('should notify all participants except organizer', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      await cancelEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      expect(notificationCalls.length).toBe(2);

      // Check notifications are for participants, not organizer
      const notifiedUserIds = notificationCalls.map(call => call[3].userId);
      expect(notifiedUserIds).toContain(participant1.$id);
      expect(notifiedUserIds).toContain(participant2.$id);
      expect(notifiedUserIds).not.toContain(organizer.$id);
    });

    it('should include event_cancelled type in notifications', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      await cancelEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      notificationCalls.forEach(call => {
        expect(call[3].type).toBe('event_cancelled');
        expect(call[3].title).toContain('annule');
      });
    });

    it('should include reason in notification if provided', async () => {
      const reason = 'Mauvais temps prevu';
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id,
          reason
        }
      });

      await cancelEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      notificationCalls.forEach(call => {
        expect(call[3].body).toContain(reason);
      });
    });

    it('should include event details in notification data', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      await cancelEvent(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      const notificationData = JSON.parse(notificationCalls[0][3].data);
      expect(notificationData.eventId).toBe(event.$id);
      expect(notificationData.eventTitle).toBe(event.title);
      expect(notificationData.organizerName).toBe(organizer.displayName);
    });
  });

  describe('validation errors', () => {
    it('should reject when eventId is missing', async () => {
      const context = createMockContext({
        body: {
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
    });

    it('should reject when organizerId is missing', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('requis');
      expect(result.statusCode).toBe(400);
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
        return organizer;
      });

      const context = createMockContext({
        body: {
          eventId: 'nonexistent_event',
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(404);
    });

    it('should handle database errors gracefully', async () => {
      mockDatabases.getDocument.mockRejectedValue(new Error('Database error'));

      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });
  });

  describe('edge cases', () => {
    it('should handle event with no participants', async () => {
      mockDatabases.listDocuments.mockResolvedValue({
        documents: [organizerParticipation],
        total: 1
      });

      const context = createMockContext({
        body: {
          eventId: event.$id,
          organizerId: organizer.$id
        }
      });

      const result = await cancelEvent(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.participantsNotified).toBe(0);
    });
  });
});
