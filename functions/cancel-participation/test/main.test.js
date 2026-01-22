/**
 * Tests for cancel-participation Appwrite Function
 *
 * Coverage:
 * - cancel success
 * - cancel when not participant (should fail)
 * - cancel cancelled event (should fail)
 * - cancel as organizer (should fail)
 * - notifications
 * - participant count update
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
const { default: cancelParticipation } = await import('../src/main.js');

// Import test utilities
import {
  createMockContext,
  generateFakeUser,
  generateFakeEvent,
  generateFakeParticipation,
  setupTestEnvironment
} from '../../test-utils/index.js';

describe('cancel-participation function', () => {
  let user;
  let organizer;
  let event;
  let participation;

  beforeEach(() => {
    setupTestEnvironment();
    jest.clearAllMocks();

    // Setup default test data
    user = generateFakeUser({ $id: 'user_123', username: 'testuser', displayName: 'Test User' });
    organizer = generateFakeUser({ $id: 'organizer_456', username: 'organizer', displayName: 'Event Organizer' });

    // Future event
    const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    event = generateFakeEvent({
      $id: 'event_789',
      creatorId: organizer.$id,
      organizerId: organizer.$id,
      title: 'Test Gaming Event',
      startDate: futureDate.toISOString(),
      participantCount: 5,
      status: 'published'
    });

    participation = generateFakeParticipation({
      $id: 'participation_001',
      userId: user.$id,
      eventId: event.$id,
      status: 'confirmed',
      role: 'participant'
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

    mockDatabases.listDocuments.mockResolvedValue({
      documents: [participation],
      total: 1
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
    it('should cancel participation successfully', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(true);
      expect(result.data.data.eventId).toBe(event.$id);
      expect(result.data.data.userId).toBe(user.$id);
      expect(result.data.data.cancelledAt).toBeDefined();
    });

    it('should update participation status to cancelled', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await cancelParticipation(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'event_participants'
      );
      expect(updateCalls.length).toBe(1);
      expect(updateCalls[0][3].status).toBe('cancelled');
      expect(updateCalls[0][3].cancelledAt).toBeDefined();
    });

    it('should decrement event participant count', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await cancelParticipation(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(updateCalls.length).toBe(1);
      expect(updateCalls[0][3].participantCount).toBe(4); // 5 - 1
    });

    it('should not go below zero participants', async () => {
      event.participantCount = 0;

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await cancelParticipation(context);

      const updateCalls = mockDatabases.updateDocument.mock.calls.filter(
        call => call[1] === 'events'
      );
      expect(updateCalls[0][3].participantCount).toBe(0);
    });
  });

  describe('cancel when not participant (should fail)', () => {
    it('should reject when user is not a participant', async () => {
      mockDatabases.listDocuments.mockResolvedValue({
        documents: [],
        total: 0
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('pas inscrit');
      expect(result.statusCode).toBe(404);
    });
  });

  describe('cancel cancelled event (should fail)', () => {
    it('should reject when event is already cancelled', async () => {
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

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('annule');
      expect(result.statusCode).toBe(400);
    });

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

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('termine');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('cancel as organizer (should fail)', () => {
    it('should reject when user is the organizer', async () => {
      const organizerParticipation = {
        ...participation,
        userId: organizer.$id,
        role: 'organizer'
      };

      mockDatabases.listDocuments.mockResolvedValue({
        documents: [organizerParticipation],
        total: 1
      });

      const context = createMockContext({
        body: {
          userId: organizer.$id,
          eventId: event.$id
        }
      });

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(false);
      expect(result.data.error).toContain('organisateur');
      expect(result.statusCode).toBe(400);
    });
  });

  describe('notifications', () => {
    it('should notify the organizer when someone cancels', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await cancelParticipation(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      expect(notificationCalls.length).toBe(1);
      const notification = notificationCalls[0][3];
      expect(notification.userId).toBe(event.creatorId);
      expect(notification.type).toBe('event_update');
      expect(notification.title).toContain('desiste');
    });

    it('should include participant details in notification', async () => {
      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: event.$id
        }
      });

      await cancelParticipation(context);

      const notificationCalls = mockDatabases.createDocument.mock.calls.filter(
        call => call[1] === 'notifications'
      );

      const notification = notificationCalls[0][3];
      expect(notification.body).toContain(user.displayName);
      expect(notification.body).toContain(event.title);
    });
  });

  describe('validation errors', () => {
    it('should reject when userId is missing', async () => {
      const context = createMockContext({
        body: {
          eventId: event.$id
        }
      });

      const result = await cancelParticipation(context);

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

      const result = await cancelParticipation(context);

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
        return user;
      });

      const context = createMockContext({
        body: {
          userId: user.$id,
          eventId: 'nonexistent_event'
        }
      });

      const result = await cancelParticipation(context);

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

      const result = await cancelParticipation(context);

      expect(result.data.success).toBe(false);
      expect(result.statusCode).toBe(500);
    });
  });
});
