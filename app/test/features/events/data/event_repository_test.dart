import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';

import 'package:fug_app/features/events/data/event_repository.dart';
import 'package:fug_app/features/events/domain/event_model.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late EventRepository eventRepository;
  late MockAppwriteService mockAppwriteService;
  late MockDatabases mockDatabases;

  setUpAll(() {
    setUpTestHelpers();
  });

  setUp(() {
    mockAppwriteService = MockAppwriteService();
    mockDatabases = MockDatabases();

    when(() => mockAppwriteService.databases).thenReturn(mockDatabases);

    eventRepository = EventRepository(appwrite: mockAppwriteService);
  });

  group('EventRepository', () {
    group('createEvent()', () {
      test('devrait creer un evenement avec succes', () async {
        // Arrange
        final eventJson = TestData.createEventJson(
          id: 'new-event-id',
          title: 'Tech Meetup',
          description: 'A tech event',
          organizerId: 'org-123',
          organizerName: 'Tech Org',
          categoryId: 'cat-tech',
          address: '123 Main St',
          latitude: 48.8566,
          longitude: 2.3522,
        );

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        final result = await eventRepository.createEvent(
          title: 'Tech Meetup',
          description: 'A tech event',
          organizerId: 'org-123',
          organizerName: 'Tech Org',
          categoryId: 'cat-tech',
          address: '123 Main St',
          latitude: 48.8566,
          longitude: 2.3522,
          startDate: DateTime(2024, 6, 15, 18, 0),
          endDate: DateTime(2024, 6, 15, 22, 0),
        );

        // Assert
        expect(result, isA<EventModel>());
        expect(result.title, equals('Tech Meetup'));
        expect(result.organizerId, equals('org-123'));
        verify(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).called(1);
      });

      test('devrait creer un evenement avec parametres optionnels', () async {
        // Arrange
        final eventJson = TestData.createEventJson(
          id: 'new-event-id',
          title: 'Premium Event',
          price: 1500,
          maxParticipants: 100,
          venueName: 'Grand Hotel',
          tags: ['premium', 'networking'],
        );

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        final result = await eventRepository.createEvent(
          title: 'Premium Event',
          description: 'Description',
          organizerId: 'org-123',
          organizerName: 'Organizer',
          categoryId: 'cat-1',
          address: 'Address',
          latitude: 48.0,
          longitude: 2.0,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(hours: 4)),
          price: 1500,
          maxParticipants: 100,
          venueName: 'Grand Hotel',
          tags: ['premium', 'networking'],
        );

        // Assert
        expect(result.price, equals(1500));
        expect(result.maxParticipants, equals(100));
      });

      test('devrait lancer EventException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenThrow(
          AppwriteException('Database error', 500),
        );

        // Act & Assert
        expect(
          () => eventRepository.createEvent(
            title: 'Test',
            description: 'Test',
            organizerId: 'org-1',
            organizerName: 'Org',
            categoryId: 'cat-1',
            address: 'Address',
            latitude: 48.0,
            longitude: 2.0,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(hours: 1)),
          ),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('getEvent()', () {
      test('devrait retourner un evenement par ID', () async {
        // Arrange
        const eventId = 'event-123';
        final eventJson = TestData.createEventJson(
          id: eventId,
          title: 'Test Event',
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        final result = await eventRepository.getEvent(eventId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(eventId));
        expect(result.title, equals('Test Event'));
      });

      test('devrait retourner null si l\'evenement n\'existe pas', () async {
        // Arrange
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(
          AppwriteException('Document not found', 404),
        );

        // Act
        final result = await eventRepository.getEvent('non-existent');

        // Assert
        expect(result, isNull);
      });

      test('devrait lancer EventException pour autres erreurs', () async {
        // Arrange
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(
          AppwriteException('Server error', 500),
        );

        // Act & Assert
        expect(
          () => eventRepository.getEvent('event-123'),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('updateEvent()', () {
      test('devrait mettre a jour un evenement avec succes', () async {
        // Arrange
        const eventId = 'event-123';
        final updatedJson = TestData.createEventJson(
          id: eventId,
          title: 'Updated Title',
          price: 2000,
        );

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => createMockDocument(updatedJson),
        );

        // Act
        final result = await eventRepository.updateEvent(
          eventId: eventId,
          title: 'Updated Title',
          price: 2000,
        );

        // Assert
        expect(result.title, equals('Updated Title'));
        expect(result.price, equals(2000));
      });

      test('devrait mettre a jour le statut', () async {
        // Arrange
        const eventId = 'event-123';
        final updatedJson = TestData.createEventJson(
          id: eventId,
          status: 'cancelled',
        );

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => createMockDocument(updatedJson),
        );

        // Act
        final result = await eventRepository.updateEvent(
          eventId: eventId,
          status: EventStatus.cancelled,
        );

        // Assert
        expect(result.status, equals(EventStatus.cancelled));
      });

      test('devrait lancer EventException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
            )).thenThrow(
          AppwriteException('Forbidden', 403),
        );

        // Act & Assert
        expect(
          () => eventRepository.updateEvent(
            eventId: 'event-123',
            title: 'New Title',
          ),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('deleteEvent()', () {
      test('devrait supprimer un evenement avec succes', () async {
        // Arrange
        const eventId = 'event-123';

        when(() => mockDatabases.deleteDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer((_) async => {});

        // Act
        await eventRepository.deleteEvent(eventId);

        // Assert
        verify(() => mockDatabases.deleteDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).called(1);
      });

      test('devrait lancer EventException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.deleteDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(
          AppwriteException('Forbidden', 403),
        );

        // Act & Assert
        expect(
          () => eventRepository.deleteEvent('event-123'),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('listEvents()', () {
      test('devrait lister les evenements avec pagination', () async {
        // Arrange
        final eventsJson = List.generate(
          5,
          (i) => TestData.createEventJson(id: 'event-$i', title: 'Event $i'),
        );

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.listEvents(limit: 5);

        // Assert
        expect(result.length, equals(5));
        expect(result[0].id, equals('event-0'));
        expect(result[4].id, equals('event-4'));
      });

      test('devrait filtrer par categorie', () async {
        // Arrange
        final eventsJson = [
          TestData.createEventJson(id: 'event-1', categoryId: 'cat-tech'),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.listEvents(categoryId: 'cat-tech');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].categoryId, equals('cat-tech'));
      });

      test('devrait filtrer par statut', () async {
        // Arrange
        final eventsJson = [
          TestData.createEventJson(id: 'event-1', status: 'draft'),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.listEvents(status: EventStatus.draft);

        // Assert
        expect(result.length, equals(1));
      });

      test('devrait lancer EventException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenThrow(
          AppwriteException('Error', 500),
        );

        // Act & Assert
        expect(
          () => eventRepository.listEvents(),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('getUpcomingEvents()', () {
      test('devrait retourner les evenements a venir', () async {
        // Arrange
        final futureDate = DateTime.now().add(const Duration(days: 7));
        final eventsJson = [
          TestData.createEventJson(
            id: 'event-1',
            title: 'Future Event',
            startDate: futureDate,
          ),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.getUpcomingEvents();

        // Assert
        expect(result.length, equals(1));
        expect(result[0].title, equals('Future Event'));
      });
    });

    group('getEventsByOrganizer()', () {
      test('devrait retourner les evenements d\'un organisateur', () async {
        // Arrange
        const organizerId = 'org-123';
        final eventsJson = [
          TestData.createEventJson(id: 'event-1', organizerId: organizerId),
          TestData.createEventJson(id: 'event-2', organizerId: organizerId),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.getEventsByOrganizer(organizerId);

        // Assert
        expect(result.length, equals(2));
        expect(result.every((e) => e.organizerId == organizerId), isTrue);
      });
    });

    group('getNearbyEvents()', () {
      test('devrait retourner les evenements proches', () async {
        // Arrange
        const userLat = 48.8566;
        const userLon = 2.3522;
        final eventsJson = [
          TestData.createEventJson(
            id: 'event-1',
            latitude: 48.8570,
            longitude: 2.3525,
          ),
          TestData.createEventJson(
            id: 'event-2',
            latitude: 48.8560,
            longitude: 2.3520,
          ),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.getNearbyEvents(
          latitude: userLat,
          longitude: userLon,
          radiusKm: 10,
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('devrait respecter la limite de resultats', () async {
        // Arrange
        final eventsJson = List.generate(
          10,
          (i) => TestData.createEventJson(
            id: 'event-$i',
            latitude: 48.8566 + (i * 0.001),
            longitude: 2.3522 + (i * 0.001),
          ),
        );

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.getNearbyEvents(
          latitude: 48.8566,
          longitude: 2.3522,
          limit: 5,
        );

        // Assert
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('devrait filtrer par categorie', () async {
        // Arrange
        final eventsJson = [
          TestData.createEventJson(
            id: 'event-1',
            categoryId: 'cat-sports',
            latitude: 48.8566,
            longitude: 2.3522,
          ),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.getNearbyEvents(
          latitude: 48.8566,
          longitude: 2.3522,
          categoryId: 'cat-sports',
        );

        // Assert
        expect(result.isNotEmpty, isTrue);
      });

      test('devrait lancer EventException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenThrow(
          AppwriteException('Error', 500),
        );

        // Act & Assert
        expect(
          () => eventRepository.getNearbyEvents(
            latitude: 48.8566,
            longitude: 2.3522,
          ),
          throwsA(isA<EventException>()),
        );
      });
    });

    group('searchEvents()', () {
      test('devrait rechercher des evenements par texte', () async {
        // Arrange
        final eventsJson = [
          TestData.createEventJson(id: 'event-1', title: 'Tech Meetup'),
          TestData.createEventJson(id: 'event-2', title: 'Tech Conference'),
        ];

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer(
          (_) async => createMockDocumentList(eventsJson),
        );

        // Act
        final result = await eventRepository.searchEvents(query: 'Tech');

        // Assert
        expect(result.length, equals(2));
        expect(result.every((e) => e.title.contains('Tech')), isTrue);
      });
    });

    group('incrementParticipants()', () {
      test('devrait incrementer le nombre de participants', () async {
        // Arrange
        const eventId = 'event-123';
        final eventJson = TestData.createEventJson(
          id: eventId,
          maxParticipants: 100,
          currentParticipants: 50,
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        await eventRepository.incrementParticipants(eventId);

        // Assert
        verify(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).called(1);
      });

      test('devrait lancer EventException si evenement complet', () async {
        // Arrange
        const eventId = 'event-123';
        final eventJson = TestData.createEventJson(
          id: eventId,
          maxParticipants: 10,
          currentParticipants: 10, // Complet
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act & Assert
        expect(
          () => eventRepository.incrementParticipants(eventId),
          throwsA(
            isA<EventException>().having(
              (e) => e.message,
              'message',
              contains('complet'),
            ),
          ),
        );
      });

      test('devrait lancer EventException si evenement non trouve', () async {
        // Arrange
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(
          AppwriteException('Not found', 404),
        );

        // Act & Assert
        expect(
          () => eventRepository.incrementParticipants('non-existent'),
          throwsA(
            isA<EventException>().having(
              (e) => e.code,
              'code',
              equals(404),
            ),
          ),
        );
      });
    });

    group('decrementParticipants()', () {
      test('devrait decrementer le nombre de participants', () async {
        // Arrange
        const eventId = 'event-123';
        final eventJson = TestData.createEventJson(
          id: eventId,
          currentParticipants: 50,
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        await eventRepository.decrementParticipants(eventId);

        // Assert
        verify(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
              data: any(named: 'data'),
            )).called(1);
      });

      test('ne devrait rien faire si currentParticipants <= 0', () async {
        // Arrange
        const eventId = 'event-123';
        final eventJson = TestData.createEventJson(
          id: eventId,
          currentParticipants: 0,
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: eventId,
            )).thenAnswer(
          (_) async => createMockDocument(eventJson),
        );

        // Act
        await eventRepository.decrementParticipants(eventId);

        // Assert
        verifyNever(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
            ));
      });
    });
  });

  group('EventException', () {
    test('devrait contenir le message et le code', () {
      // Arrange & Act
      final exception = EventException('Test error', code: 400);

      // Assert
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals(400));
    });

    test('toString devrait retourner une representation lisible', () {
      // Arrange
      final exception = EventException('Test error');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('EventException: Test error'));
    });
  });
}
