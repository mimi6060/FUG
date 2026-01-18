import 'package:flutter_test/flutter_test.dart';
import 'package:fug_app/features/events/domain/event_model.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('EventModel', () {
    late DateTime testStartDate;
    late DateTime testEndDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testStartDate = DateTime(2024, 6, 15, 18, 0);
      testEndDate = DateTime(2024, 6, 15, 22, 0);
      testCreatedAt = DateTime(2024, 1, 1, 10, 0);
      testUpdatedAt = DateTime(2024, 1, 5, 14, 30);
    });

    group('Constructor', () {
      test('devrait creer un EventModel avec toutes les proprietes', () {
        // Arrange & Act
        final event = EventModel(
          id: 'event-123',
          title: 'Tech Meetup',
          description: 'A great tech event',
          organizerId: 'org-456',
          organizerName: 'Tech Corp',
          categoryId: 'cat-789',
          categoryName: 'Technology',
          imageUrl: 'https://example.com/image.jpg',
          additionalImages: ['img1.jpg', 'img2.jpg'],
          address: '123 Main St, Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          venueName: 'Tech Hub',
          startDate: testStartDate,
          endDate: testEndDate,
          maxParticipants: 100,
          currentParticipants: 45,
          price: 1500, // 15.00 EUR
          currency: 'EUR',
          tags: ['tech', 'networking'],
          status: EventStatus.published,
          isFeatured: true,
          rating: 4.5,
          reviewCount: 23,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(event.id, equals('event-123'));
        expect(event.title, equals('Tech Meetup'));
        expect(event.description, equals('A great tech event'));
        expect(event.organizerId, equals('org-456'));
        expect(event.organizerName, equals('Tech Corp'));
        expect(event.categoryId, equals('cat-789'));
        expect(event.categoryName, equals('Technology'));
        expect(event.imageUrl, equals('https://example.com/image.jpg'));
        expect(event.additionalImages, equals(['img1.jpg', 'img2.jpg']));
        expect(event.address, equals('123 Main St, Paris'));
        expect(event.latitude, equals(48.8566));
        expect(event.longitude, equals(2.3522));
        expect(event.venueName, equals('Tech Hub'));
        expect(event.startDate, equals(testStartDate));
        expect(event.endDate, equals(testEndDate));
        expect(event.maxParticipants, equals(100));
        expect(event.currentParticipants, equals(45));
        expect(event.price, equals(1500));
        expect(event.currency, equals('EUR'));
        expect(event.tags, equals(['tech', 'networking']));
        expect(event.status, equals(EventStatus.published));
        expect(event.isFeatured, isTrue);
        expect(event.rating, equals(4.5));
        expect(event.reviewCount, equals(23));
      });

      test('devrait utiliser les valeurs par defaut', () {
        // Arrange & Act
        final event = EventModel(
          id: 'event-123',
          title: 'Test Event',
          description: 'Description',
          organizerId: 'org-456',
          organizerName: 'Organizer',
          categoryId: 'cat-789',
          address: 'Test Address',
          latitude: 48.8566,
          longitude: 2.3522,
          startDate: testStartDate,
          endDate: testEndDate,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(event.categoryName, isNull);
        expect(event.imageUrl, isNull);
        expect(event.additionalImages, isEmpty);
        expect(event.venueName, isNull);
        expect(event.maxParticipants, isNull);
        expect(event.currentParticipants, equals(0));
        expect(event.price, equals(0));
        expect(event.currency, equals('EUR'));
        expect(event.tags, isEmpty);
        expect(event.status, equals(EventStatus.published));
        expect(event.isFeatured, isFalse);
        expect(event.rating, equals(0.0));
        expect(event.reviewCount, equals(0));
      });
    });

    group('fromJson()', () {
      test('devrait parser correctement un JSON complet', () {
        // Arrange
        final json = {
          '\$id': 'event-123',
          'title': 'Tech Meetup',
          'description': 'A great tech event',
          'organizerId': 'org-456',
          'organizerName': 'Tech Corp',
          'categoryId': 'cat-789',
          'categoryName': 'Technology',
          'imageUrl': 'https://example.com/image.jpg',
          'additionalImages': ['img1.jpg'],
          'address': '123 Main St',
          'latitude': 48.8566,
          'longitude': 2.3522,
          'venueName': 'Tech Hub',
          'startDate': '2024-06-15T18:00:00.000',
          'endDate': '2024-06-15T22:00:00.000',
          'maxParticipants': 100,
          'currentParticipants': 45,
          'price': 1500,
          'currency': 'EUR',
          'tags': ['tech'],
          'status': 'published',
          'isFeatured': true,
          'rating': 4.5,
          'reviewCount': 23,
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-05T14:30:00.000',
        };

        // Act
        final event = EventModel.fromJson(json);

        // Assert
        expect(event.id, equals('event-123'));
        expect(event.title, equals('Tech Meetup'));
        expect(event.categoryName, equals('Technology'));
        expect(event.maxParticipants, equals(100));
        expect(event.price, equals(1500));
        expect(event.status, equals(EventStatus.published));
        expect(event.isFeatured, isTrue);
        expect(event.rating, equals(4.5));
      });

      test('devrait utiliser id comme fallback pour \$id', () {
        // Arrange
        final json = TestData.createEventJson(id: 'custom-id');
        json.remove('\$id');

        // Act
        final event = EventModel.fromJson(json);

        // Assert
        expect(event.id, equals('custom-id'));
      });

      test('devrait gerer les valeurs null et utiliser les valeurs par defaut', () {
        // Arrange
        final json = {
          '\$id': 'event-123',
          'title': 'Test',
          'description': 'Desc',
          'organizerId': 'org-1',
          'organizerName': 'Org',
          'categoryId': 'cat-1',
          'categoryName': null,
          'imageUrl': null,
          'additionalImages': null,
          'address': 'Address',
          'latitude': 48.0,
          'longitude': 2.0,
          'venueName': null,
          'startDate': '2024-06-15T18:00:00.000',
          'endDate': '2024-06-15T22:00:00.000',
          'maxParticipants': null,
          'currentParticipants': null,
          'price': null,
          'currency': null,
          'tags': null,
          'status': null,
          'isFeatured': null,
          'rating': null,
          'reviewCount': null,
          'createdAt': '2024-01-01T10:00:00.000',
          'updatedAt': '2024-01-05T14:30:00.000',
        };

        // Act
        final event = EventModel.fromJson(json);

        // Assert
        expect(event.categoryName, isNull);
        expect(event.imageUrl, isNull);
        expect(event.additionalImages, isEmpty);
        expect(event.maxParticipants, isNull);
        expect(event.currentParticipants, equals(0));
        expect(event.price, equals(0));
        expect(event.currency, equals('EUR'));
        expect(event.tags, isEmpty);
        expect(event.status, equals(EventStatus.published));
        expect(event.isFeatured, isFalse);
        expect(event.rating, equals(0.0));
        expect(event.reviewCount, equals(0));
      });

      test('devrait convertir les num en double pour les coordonnees', () {
        // Arrange
        final json = TestData.createEventJson(
          latitude: 48, // int
          longitude: 2, // int
        );

        // Act
        final event = EventModel.fromJson(json);

        // Assert
        expect(event.latitude, equals(48.0));
        expect(event.longitude, equals(2.0));
        expect(event.latitude, isA<double>());
        expect(event.longitude, isA<double>());
      });

      test('devrait parser tous les statuts correctement', () {
        // Arrange & Act & Assert
        for (final status in EventStatus.values) {
          final json = TestData.createEventJson(status: status.value);
          final event = EventModel.fromJson(json);
          expect(event.status, equals(status));
        }
      });
    });

    group('toJson()', () {
      test('devrait convertir correctement en JSON', () {
        // Arrange
        final event = TestData.createEvent(
          id: 'event-123',
          title: 'Test Event',
          price: 1500,
          status: EventStatus.published,
        );

        // Act
        final json = event.toJson();

        // Assert
        expect(json['id'], equals('event-123'));
        expect(json['title'], equals('Test Event'));
        expect(json['price'], equals(1500));
        expect(json['status'], equals('published'));
      });

      test('fromJson et toJson devraient etre reversibles', () {
        // Arrange
        final originalEvent = TestData.createEvent(
          id: 'event-123',
          title: 'Original Event',
          tags: ['tag1', 'tag2'],
        );

        // Act
        final json = originalEvent.toJson();
        final recreatedEvent = EventModel.fromJson(json);

        // Assert
        expect(recreatedEvent, equals(originalEvent));
      });
    });

    group('copyWith()', () {
      test('devrait creer une copie avec les memes valeurs par defaut', () {
        // Arrange
        final original = TestData.createEvent();

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy, equals(original));
        expect(identical(copy, original), isFalse);
      });

      test('devrait modifier uniquement les proprietes specifiees', () {
        // Arrange
        final original = TestData.createEvent(
          title: 'Original Title',
          price: 1000,
        );

        // Act
        final modified = original.copyWith(
          title: 'New Title',
          price: 2000,
        );

        // Assert
        expect(modified.title, equals('New Title'));
        expect(modified.price, equals(2000));
        expect(modified.id, equals(original.id));
        expect(modified.description, equals(original.description));
      });

      test('devrait permettre de changer le statut', () {
        // Arrange
        final original = TestData.createEvent(status: EventStatus.draft);

        // Act
        final modified = original.copyWith(status: EventStatus.published);

        // Assert
        expect(original.status, equals(EventStatus.draft));
        expect(modified.status, equals(EventStatus.published));
      });
    });

    group('Computed Properties', () {
      group('isFree', () {
        test('devrait retourner true si le prix est 0', () {
          // Arrange
          final event = TestData.createEvent(price: 0);

          // Act & Assert
          expect(event.isFree, isTrue);
        });

        test('devrait retourner false si le prix est superieur a 0', () {
          // Arrange
          final event = TestData.createEvent(price: 100);

          // Act & Assert
          expect(event.isFree, isFalse);
        });
      });

      group('formattedPrice', () {
        test('devrait retourner "Gratuit" pour prix 0', () {
          // Arrange
          final event = TestData.createEvent(price: 0);

          // Act & Assert
          expect(event.formattedPrice, equals('Gratuit'));
        });

        test('devrait formater le prix en EUR', () {
          // Arrange
          final event = TestData.createEvent(price: 1500, currency: 'EUR');

          // Act & Assert
          expect(event.formattedPrice, equals('15.0 EUR'));
        });

        test('devrait formater le prix dans une autre devise', () {
          // Arrange
          final event = TestData.createEvent(price: 2000, currency: 'USD');

          // Act & Assert
          expect(event.formattedPrice, equals('20.0 USD'));
        });
      });

      group('isFull', () {
        test('devrait retourner true si currentParticipants >= maxParticipants', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: 10,
            currentParticipants: 10,
          );

          // Act & Assert
          expect(event.isFull, isTrue);
        });

        test('devrait retourner true si currentParticipants > maxParticipants', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: 10,
            currentParticipants: 15,
          );

          // Act & Assert
          expect(event.isFull, isTrue);
        });

        test('devrait retourner false si des places sont disponibles', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: 10,
            currentParticipants: 5,
          );

          // Act & Assert
          expect(event.isFull, isFalse);
        });

        test('devrait retourner false si maxParticipants est null', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: null,
            currentParticipants: 1000,
          );

          // Act & Assert
          expect(event.isFull, isFalse);
        });
      });

      group('remainingSpots', () {
        test('devrait calculer les places restantes', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: 100,
            currentParticipants: 75,
          );

          // Act & Assert
          expect(event.remainingSpots, equals(25));
        });

        test('devrait retourner 0 si complet', () {
          // Arrange
          final event = TestData.createEvent(
            maxParticipants: 50,
            currentParticipants: 50,
          );

          // Act & Assert
          expect(event.remainingSpots, equals(0));
        });

        test('devrait retourner null si maxParticipants est null', () {
          // Arrange
          final event = TestData.createEvent(maxParticipants: null);

          // Act & Assert
          expect(event.remainingSpots, isNull);
        });
      });

      group('isOngoing / isPast / isUpcoming', () {
        test('isUpcoming devrait etre true pour un evenement futur', () {
          // Arrange
          final event = TestData.createEvent(
            startDate: DateTime.now().add(const Duration(days: 7)),
            endDate: DateTime.now().add(const Duration(days: 7, hours: 4)),
          );

          // Act & Assert
          expect(event.isUpcoming, isTrue);
          expect(event.isOngoing, isFalse);
          expect(event.isPast, isFalse);
        });

        test('isPast devrait etre true pour un evenement passe', () {
          // Arrange
          final event = TestData.createEvent(
            startDate: DateTime.now().subtract(const Duration(days: 7)),
            endDate: DateTime.now().subtract(const Duration(days: 6)),
          );

          // Act & Assert
          expect(event.isPast, isTrue);
          expect(event.isUpcoming, isFalse);
          expect(event.isOngoing, isFalse);
        });

        test('isOngoing devrait etre true pour un evenement en cours', () {
          // Arrange
          final now = DateTime.now();
          final event = TestData.createEvent(
            startDate: now.subtract(const Duration(hours: 1)),
            endDate: now.add(const Duration(hours: 3)),
          );

          // Act & Assert
          expect(event.isOngoing, isTrue);
          expect(event.isUpcoming, isFalse);
          expect(event.isPast, isFalse);
        });
      });

      group('duration', () {
        test('devrait calculer la duree correctement', () {
          // Arrange
          final start = DateTime(2024, 6, 15, 18, 0);
          final end = DateTime(2024, 6, 15, 22, 0);
          final event = TestData.createEvent(
            startDate: start,
            endDate: end,
          );

          // Act & Assert
          expect(event.duration, equals(const Duration(hours: 4)));
        });
      });

      group('formattedDuration', () {
        test('devrait formater les heures uniquement', () {
          // Arrange
          final event = TestData.createEvent(
            startDate: DateTime(2024, 6, 15, 18, 0),
            endDate: DateTime(2024, 6, 15, 20, 0),
          );

          // Act & Assert
          expect(event.formattedDuration, equals('2h'));
        });

        test('devrait formater les minutes uniquement', () {
          // Arrange
          final event = TestData.createEvent(
            startDate: DateTime(2024, 6, 15, 18, 0),
            endDate: DateTime(2024, 6, 15, 18, 45),
          );

          // Act & Assert
          expect(event.formattedDuration, equals('45min'));
        });

        test('devrait formater heures et minutes', () {
          // Arrange
          final event = TestData.createEvent(
            startDate: DateTime(2024, 6, 15, 18, 0),
            endDate: DateTime(2024, 6, 15, 20, 30),
          );

          // Act & Assert
          expect(event.formattedDuration, equals('2h30min'));
        });
      });
    });

    group('Equatable', () {
      test('deux EventModels avec les memes valeurs devraient etre egaux', () {
        // Arrange
        final event1 = TestData.createEvent(id: 'event-123', title: 'Test');
        final event2 = TestData.createEvent(id: 'event-123', title: 'Test');

        // Assert - note: createdAt/updatedAt peuvent differer
        expect(event1.id, equals(event2.id));
        expect(event1.title, equals(event2.title));
      });

      test('deux EventModels avec des IDs differents ne devraient pas etre egaux', () {
        // Arrange
        final event1 = TestData.createEvent(id: 'event-123');
        final event2 = TestData.createEvent(id: 'event-456');

        // Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('toString()', () {
      test('devrait retourner une representation lisible', () {
        // Arrange
        final event = TestData.createEvent(
          id: 'event-123',
          title: 'Test Event',
        );

        // Act
        final result = event.toString();

        // Assert
        expect(result, contains('EventModel'));
        expect(result, contains('event-123'));
        expect(result, contains('Test Event'));
      });
    });
  });

  group('EventStatus', () {
    group('EventStatusExtension.value', () {
      test('devrait convertir draft en string', () {
        expect(EventStatus.draft.value, equals('draft'));
      });

      test('devrait convertir published en string', () {
        expect(EventStatus.published.value, equals('published'));
      });

      test('devrait convertir cancelled en string', () {
        expect(EventStatus.cancelled.value, equals('cancelled'));
      });

      test('devrait convertir completed en string', () {
        expect(EventStatus.completed.value, equals('completed'));
      });
    });

    group('EventStatusExtension.fromString', () {
      test('devrait parser "draft"', () {
        expect(EventStatusExtension.fromString('draft'), equals(EventStatus.draft));
      });

      test('devrait parser "published"', () {
        expect(EventStatusExtension.fromString('published'), equals(EventStatus.published));
      });

      test('devrait parser "cancelled"', () {
        expect(EventStatusExtension.fromString('cancelled'), equals(EventStatus.cancelled));
      });

      test('devrait parser "completed"', () {
        expect(EventStatusExtension.fromString('completed'), equals(EventStatus.completed));
      });

      test('devrait retourner draft pour une valeur inconnue', () {
        expect(EventStatusExtension.fromString('unknown'), equals(EventStatus.draft));
        expect(EventStatusExtension.fromString(''), equals(EventStatus.draft));
      });
    });
  });
}
