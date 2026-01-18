/**
 * Test Utilities for FUG Appwrite Functions
 *
 * Shared helpers for creating mocks and test data
 */

import { jest } from '@jest/globals';

/**
 * Creates a mock Appwrite context with req, res, log, and error
 * @param {Object} options - Configuration options
 * @param {Object} options.body - Request body (will be JSON stringified)
 * @param {Object} options.headers - Request headers
 * @returns {Object} Mock context object
 */
export function createMockContext(options = {}) {
  const { body = {}, headers = {} } = options;

  const responses = [];

  return {
    req: {
      body: JSON.stringify(body),
      headers,
      method: options.method || 'POST',
      path: options.path || '/',
      query: options.query || {}
    },
    res: {
      json: jest.fn((data, statusCode = 200) => {
        responses.push({ data, statusCode });
        return { data, statusCode };
      }),
      send: jest.fn((data, statusCode = 200) => {
        responses.push({ data, statusCode });
        return { data, statusCode };
      }),
      empty: jest.fn(() => {
        responses.push({ data: null, statusCode: 204 });
        return { data: null, statusCode: 204 };
      })
    },
    log: jest.fn(),
    error: jest.fn(),
    // Helper to get last response
    getLastResponse: () => responses[responses.length - 1],
    getResponses: () => responses
  };
}

/**
 * Creates a mock Databases instance with common methods
 * @param {Object} mockData - Mock data configuration
 * @returns {Object} Mock Databases instance
 */
export function createMockDatabases(mockData = {}) {
  const documents = mockData.documents || {};
  const createdDocuments = [];
  const updatedDocuments = [];

  return {
    getDocument: jest.fn(async (databaseId, collectionId, documentId) => {
      const key = `${collectionId}:${documentId}`;
      if (documents[key]) {
        return { ...documents[key], $id: documentId };
      }
      // Check if document exists by scanning
      for (const [k, v] of Object.entries(documents)) {
        if (v.$id === documentId || k.endsWith(`:${documentId}`)) {
          return { ...v, $id: documentId };
        }
      }
      const error = new Error('Document not found');
      error.code = 404;
      throw error;
    }),

    listDocuments: jest.fn(async (databaseId, collectionId, queries = []) => {
      const collectionDocs = [];

      // Get all documents for the collection
      for (const [key, doc] of Object.entries(documents)) {
        if (key.startsWith(`${collectionId}:`)) {
          collectionDocs.push(doc);
        }
      }

      // Filter based on queries (simplified query parsing)
      let filteredDocs = [...collectionDocs];

      for (const query of queries) {
        if (query && typeof query === 'object' && query.type === 'equal') {
          filteredDocs = filteredDocs.filter(doc =>
            doc[query.attribute] === query.values[0]
          );
        }
      }

      return {
        documents: filteredDocs,
        total: filteredDocs.length
      };
    }),

    createDocument: jest.fn(async (databaseId, collectionId, documentId, data) => {
      const doc = {
        $id: documentId === 'unique()' ? `doc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}` : documentId,
        $createdAt: new Date().toISOString(),
        $updatedAt: new Date().toISOString(),
        ...data
      };
      createdDocuments.push({ collectionId, doc });
      documents[`${collectionId}:${doc.$id}`] = doc;
      return doc;
    }),

    updateDocument: jest.fn(async (databaseId, collectionId, documentId, data) => {
      const key = `${collectionId}:${documentId}`;
      if (!documents[key]) {
        // Try to find by $id
        for (const [k, v] of Object.entries(documents)) {
          if (v.$id === documentId) {
            const updated = { ...v, ...data, $updatedAt: new Date().toISOString() };
            documents[k] = updated;
            updatedDocuments.push({ collectionId, documentId, data });
            return updated;
          }
        }
        const error = new Error('Document not found');
        error.code = 404;
        throw error;
      }
      const updated = { ...documents[key], ...data, $updatedAt: new Date().toISOString() };
      documents[key] = updated;
      updatedDocuments.push({ collectionId, documentId, data });
      return updated;
    }),

    deleteDocument: jest.fn(async (databaseId, collectionId, documentId) => {
      const key = `${collectionId}:${documentId}`;
      if (documents[key]) {
        delete documents[key];
        return true;
      }
      return true;
    }),

    // Test helpers
    getCreatedDocuments: () => createdDocuments,
    getUpdatedDocuments: () => updatedDocuments,
    getDocuments: () => documents,
    addDocument: (collectionId, doc) => {
      documents[`${collectionId}:${doc.$id}`] = doc;
    },
    clearDocuments: () => {
      for (const key of Object.keys(documents)) {
        delete documents[key];
      }
      createdDocuments.length = 0;
      updatedDocuments.length = 0;
    }
  };
}

/**
 * Creates a mock Messaging instance
 * @returns {Object} Mock Messaging instance
 */
export function createMockMessaging() {
  const sentMessages = [];

  return {
    createEmail: jest.fn(async (messageId, subject, content, recipients) => {
      const message = { messageId, subject, content, recipients, type: 'email' };
      sentMessages.push(message);
      return message;
    }),

    createSms: jest.fn(async (messageId, content, recipients) => {
      const message = { messageId, content, recipients, type: 'sms' };
      sentMessages.push(message);
      return message;
    }),

    createPush: jest.fn(async (messageId, title, body, recipients, data) => {
      const message = { messageId, title, body, recipients, data, type: 'push' };
      sentMessages.push(message);
      return message;
    }),

    // Test helpers
    getSentMessages: () => sentMessages,
    clearMessages: () => {
      sentMessages.length = 0;
    }
  };
}

/**
 * Generates a fake user object
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake user object
 */
export function generateFakeUser(overrides = {}) {
  const id = overrides.$id || `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    $updatedAt: new Date().toISOString(),
    username: `user_${id.slice(-6)}`,
    displayName: `User ${id.slice(-6)}`,
    email: `user_${id.slice(-6)}@test.fug.app`,
    avatarUrl: `https://avatars.fug.app/${id}`,
    bio: 'Test user bio',
    followersCount: 0,
    followingCount: 0,
    eventsCount: 0,
    isVerified: false,
    status: 'active',
    ...overrides
  };
}

/**
 * Generates a fake event object
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake event object
 */
export function generateFakeEvent(overrides = {}) {
  const id = overrides.$id || `event_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const now = new Date();
  const futureDate = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 days from now

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    $updatedAt: new Date().toISOString(),
    organizerId: overrides.organizerId || `organizer_${Math.random().toString(36).substr(2, 9)}`,
    title: `Test Event ${id.slice(-6)}`,
    description: 'This is a test event description with enough characters to pass validation.',
    startDate: futureDate.toISOString(),
    endDate: new Date(futureDate.getTime() + 3 * 60 * 60 * 1000).toISOString(), // 3 hours after start
    location: 'Test Location, Paris',
    latitude: 48.8566,
    longitude: 2.3522,
    category: 'gaming',
    maxParticipants: 50,
    participantCount: 0,
    imageUrl: `https://images.fug.app/events/${id}`,
    tags: ['test', 'gaming'],
    status: 'upcoming',
    ...overrides
  };
}

/**
 * Generates a fake follow relationship
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake follow object
 */
export function generateFakeFollow(overrides = {}) {
  const id = overrides.$id || `follow_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    followerId: overrides.followerId || `follower_${Math.random().toString(36).substr(2, 9)}`,
    followingId: overrides.followingId || `following_${Math.random().toString(36).substr(2, 9)}`,
    createdAt: new Date().toISOString(),
    ...overrides
  };
}

/**
 * Generates a fake participation object
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake participation object
 */
export function generateFakeParticipation(overrides = {}) {
  const id = overrides.$id || `participation_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    userId: overrides.userId || `user_${Math.random().toString(36).substr(2, 9)}`,
    eventId: overrides.eventId || `event_${Math.random().toString(36).substr(2, 9)}`,
    status: 'confirmed',
    role: 'participant',
    joinedAt: new Date().toISOString(),
    ...overrides
  };
}

/**
 * Generates a fake gamification object
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake gamification object
 */
export function generateFakeGamification(overrides = {}) {
  const id = overrides.$id || `gamification_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    $updatedAt: new Date().toISOString(),
    userId: overrides.userId || `user_${Math.random().toString(36).substr(2, 9)}`,
    totalPoints: 0,
    level: 1,
    badges: [],
    lastAction: null,
    lastUpdated: new Date().toISOString(),
    ...overrides
  };
}

/**
 * Generates a fake notification object
 * @param {Object} overrides - Properties to override
 * @returns {Object} Fake notification object
 */
export function generateFakeNotification(overrides = {}) {
  const id = overrides.$id || `notification_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  return {
    $id: id,
    $createdAt: new Date().toISOString(),
    userId: overrides.userId || `user_${Math.random().toString(36).substr(2, 9)}`,
    type: 'general',
    title: 'Test Notification',
    message: 'This is a test notification',
    data: '{}',
    read: false,
    createdAt: new Date().toISOString(),
    ...overrides
  };
}

/**
 * Creates mock Query object matching Appwrite SDK
 * @returns {Object} Mock Query object
 */
export function createMockQuery() {
  return {
    equal: (attribute, value) => ({ type: 'equal', attribute, values: [value] }),
    notEqual: (attribute, value) => ({ type: 'notEqual', attribute, values: [value] }),
    lessThan: (attribute, value) => ({ type: 'lessThan', attribute, values: [value] }),
    greaterThan: (attribute, value) => ({ type: 'greaterThan', attribute, values: [value] }),
    lessThanEqual: (attribute, value) => ({ type: 'lessThanEqual', attribute, values: [value] }),
    greaterThanEqual: (attribute, value) => ({ type: 'greaterThanEqual', attribute, values: [value] }),
    search: (attribute, value) => ({ type: 'search', attribute, values: [value] }),
    orderAsc: (attribute) => ({ type: 'orderAsc', attribute }),
    orderDesc: (attribute) => ({ type: 'orderDesc', attribute }),
    limit: (value) => ({ type: 'limit', values: [value] }),
    offset: (value) => ({ type: 'offset', values: [value] }),
    cursorAfter: (id) => ({ type: 'cursorAfter', values: [id] }),
    cursorBefore: (id) => ({ type: 'cursorBefore', values: [id] })
  };
}

/**
 * Creates a mock ID object matching Appwrite SDK
 * @returns {Object} Mock ID object
 */
export function createMockID() {
  return {
    unique: () => `unique_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    custom: (id) => id
  };
}

/**
 * Setup environment variables for testing
 */
export function setupTestEnvironment() {
  process.env.APPWRITE_FUNCTION_API_ENDPOINT = 'https://test.appwrite.io/v1';
  process.env.APPWRITE_FUNCTION_PROJECT_ID = 'test_project';
  process.env.APPWRITE_API_KEY = 'test_api_key';
  process.env.DATABASE_ID = 'test_database';
  process.env.NODE_ENV = 'test';
}

/**
 * Creates a complete test harness with all mocks
 * @param {Object} options - Configuration options
 * @returns {Object} Test harness with context, databases, and helpers
 */
export function createTestHarness(options = {}) {
  setupTestEnvironment();

  const mockDatabases = createMockDatabases(options.documents || {});
  const mockMessaging = createMockMessaging();
  const mockContext = createMockContext(options.context || {});

  return {
    context: mockContext,
    databases: mockDatabases,
    messaging: mockMessaging,
    Query: createMockQuery(),
    ID: createMockID(),

    // Helpers
    addUser: (user) => {
      const fullUser = generateFakeUser(user);
      mockDatabases.addDocument('users', fullUser);
      return fullUser;
    },
    addEvent: (event) => {
      const fullEvent = generateFakeEvent(event);
      mockDatabases.addDocument('events', fullEvent);
      return fullEvent;
    },
    addFollow: (follow) => {
      const fullFollow = generateFakeFollow(follow);
      mockDatabases.addDocument('followers', fullFollow);
      return fullFollow;
    },
    addParticipation: (participation) => {
      const fullParticipation = generateFakeParticipation(participation);
      mockDatabases.addDocument('event_participants', fullParticipation);
      return fullParticipation;
    },
    addGamification: (gamification) => {
      const fullGamification = generateFakeGamification(gamification);
      mockDatabases.addDocument('gamification', fullGamification);
      return fullGamification;
    },

    // Reset all mocks
    reset: () => {
      mockDatabases.clearDocuments();
      mockMessaging.clearMessages();
      jest.clearAllMocks();
    }
  };
}

export default {
  createMockContext,
  createMockDatabases,
  createMockMessaging,
  generateFakeUser,
  generateFakeEvent,
  generateFakeFollow,
  generateFakeParticipation,
  generateFakeGamification,
  generateFakeNotification,
  createMockQuery,
  createMockID,
  setupTestEnvironment,
  createTestHarness
};
