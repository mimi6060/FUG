import 'package:flutter_test/flutter_test.dart';
import 'package:fug_app/features/auth/domain/user_model.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('UserModel', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testCreatedAt = DateTime(2024, 1, 15, 10, 30);
      testUpdatedAt = DateTime(2024, 1, 20, 14, 45);
    });

    group('Constructor', () {
      test('devrait creer un UserModel avec toutes les proprietes', () {
        // Arrange & Act
        final user = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Software Developer',
          location: 'Paris, France',
          latitude: 48.8566,
          longitude: 2.3522,
          interests: ['tech', 'music'],
          eventsCreated: 5,
          eventsAttended: 12,
          rating: 4.5,
          isVerified: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(user.id, equals('user-123'));
        expect(user.email, equals('john@example.com'));
        expect(user.name, equals('John Doe'));
        expect(user.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(user.bio, equals('Software Developer'));
        expect(user.location, equals('Paris, France'));
        expect(user.latitude, equals(48.8566));
        expect(user.longitude, equals(2.3522));
        expect(user.interests, equals(['tech', 'music']));
        expect(user.eventsCreated, equals(5));
        expect(user.eventsAttended, equals(12));
        expect(user.rating, equals(4.5));
        expect(user.isVerified, isTrue);
        expect(user.createdAt, equals(testCreatedAt));
        expect(user.updatedAt, equals(testUpdatedAt));
      });

      test('devrait utiliser les valeurs par defaut pour les parametres optionnels', () {
        // Arrange & Act
        final user = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(user.avatarUrl, isNull);
        expect(user.bio, isNull);
        expect(user.location, isNull);
        expect(user.latitude, isNull);
        expect(user.longitude, isNull);
        expect(user.interests, isEmpty);
        expect(user.eventsCreated, equals(0));
        expect(user.eventsAttended, equals(0));
        expect(user.rating, equals(0.0));
        expect(user.isVerified, isFalse);
      });
    });

    group('fromJson()', () {
      test('devrait parser correctement un JSON complet', () {
        // Arrange
        final json = {
          'userId': 'user-123',
          'email': 'john@example.com',
          'name': 'John Doe',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'bio': 'Software Developer',
          'location': 'Paris, France',
          'latitude': 48.8566,
          'longitude': 2.3522,
          'interests': ['tech', 'music'],
          'eventsCreated': 5,
          'eventsAttended': 12,
          'rating': 4.5,
          'isVerified': true,
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-01-20T14:45:00.000',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, equals('user-123'));
        expect(user.email, equals('john@example.com'));
        expect(user.name, equals('John Doe'));
        expect(user.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(user.bio, equals('Software Developer'));
        expect(user.interests, equals(['tech', 'music']));
        expect(user.eventsCreated, equals(5));
        expect(user.rating, equals(4.5));
        expect(user.isVerified, isTrue);
      });

      test('devrait utiliser \$id comme fallback pour userId', () {
        // Arrange
        final json = {
          '\$id': 'user-from-appwrite',
          'email': 'john@example.com',
          'name': 'John Doe',
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-01-20T14:45:00.000',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, equals('user-from-appwrite'));
      });

      test('devrait gerer les valeurs null et utiliser les valeurs par defaut', () {
        // Arrange
        final json = {
          'userId': 'user-123',
          'email': 'john@example.com',
          'name': 'John Doe',
          'avatarUrl': null,
          'bio': null,
          'location': null,
          'latitude': null,
          'longitude': null,
          'interests': null,
          'eventsCreated': null,
          'eventsAttended': null,
          'rating': null,
          'isVerified': null,
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-01-20T14:45:00.000',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.avatarUrl, isNull);
        expect(user.bio, isNull);
        expect(user.interests, isEmpty);
        expect(user.eventsCreated, equals(0));
        expect(user.eventsAttended, equals(0));
        expect(user.rating, equals(0.0));
        expect(user.isVerified, isFalse);
      });

      test('devrait convertir les num en double pour latitude et longitude', () {
        // Arrange
        final json = {
          'userId': 'user-123',
          'email': 'john@example.com',
          'name': 'John Doe',
          'latitude': 48, // int au lieu de double
          'longitude': 2, // int au lieu de double
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-01-20T14:45:00.000',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.latitude, equals(48.0));
        expect(user.longitude, equals(2.0));
        expect(user.latitude, isA<double>());
        expect(user.longitude, isA<double>());
      });

      test('devrait utiliser TestData.createUserJson correctement', () {
        // Arrange
        final json = TestData.createUserJson(
          userId: 'test-user',
          email: 'test@example.com',
          name: 'Test User',
        );

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.id, equals('test-user'));
        expect(user.email, equals('test@example.com'));
        expect(user.name, equals('Test User'));
      });
    });

    group('toJson()', () {
      test('devrait convertir correctement en JSON', () {
        // Arrange
        final user = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'Software Developer',
          location: 'Paris, France',
          latitude: 48.8566,
          longitude: 2.3522,
          interests: ['tech', 'music'],
          eventsCreated: 5,
          eventsAttended: 12,
          rating: 4.5,
          isVerified: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['userId'], equals('user-123'));
        expect(json['email'], equals('john@example.com'));
        expect(json['name'], equals('John Doe'));
        expect(json['avatarUrl'], equals('https://example.com/avatar.jpg'));
        expect(json['bio'], equals('Software Developer'));
        expect(json['location'], equals('Paris, France'));
        expect(json['latitude'], equals(48.8566));
        expect(json['longitude'], equals(2.3522));
        expect(json['interests'], equals(['tech', 'music']));
        expect(json['eventsCreated'], equals(5));
        expect(json['eventsAttended'], equals(12));
        expect(json['rating'], equals(4.5));
        expect(json['isVerified'], isTrue);
        expect(json['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(json['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('devrait preserver les valeurs null', () {
        // Arrange
        final user = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['avatarUrl'], isNull);
        expect(json['bio'], isNull);
        expect(json['location'], isNull);
        expect(json['latitude'], isNull);
        expect(json['longitude'], isNull);
      });

      test('fromJson et toJson devraient etre reversibles', () {
        // Arrange
        final originalUser = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          bio: 'Test bio',
          interests: ['sport', 'music'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final json = originalUser.toJson();
        final recreatedUser = UserModel.fromJson(json);

        // Assert
        expect(recreatedUser, equals(originalUser));
      });
    });

    group('copyWith()', () {
      test('devrait creer une copie avec les memes valeurs par defaut', () {
        // Arrange
        final original = TestData.createUser(
          id: 'user-123',
          name: 'John Doe',
          email: 'john@example.com',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy, equals(original));
        expect(identical(copy, original), isFalse);
      });

      test('devrait modifier uniquement les proprietes specifiees', () {
        // Arrange
        final original = TestData.createUser(
          id: 'user-123',
          name: 'John Doe',
          email: 'john@example.com',
          bio: 'Original bio',
        );

        // Act
        final modified = original.copyWith(
          name: 'Jane Doe',
          bio: 'New bio',
        );

        // Assert
        expect(modified.id, equals(original.id));
        expect(modified.email, equals(original.email));
        expect(modified.name, equals('Jane Doe'));
        expect(modified.bio, equals('New bio'));
      });

      test('devrait permettre de modifier toutes les proprietes', () {
        // Arrange
        final original = TestData.createUser();
        final newCreatedAt = DateTime(2025, 1, 1);
        final newUpdatedAt = DateTime(2025, 1, 2);

        // Act
        final modified = original.copyWith(
          id: 'new-id',
          email: 'new@example.com',
          name: 'New Name',
          avatarUrl: 'https://new-avatar.com',
          bio: 'New bio',
          location: 'New York',
          latitude: 40.7128,
          longitude: -74.0060,
          interests: ['new', 'interests'],
          eventsCreated: 10,
          eventsAttended: 20,
          rating: 5.0,
          isVerified: true,
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        // Assert
        expect(modified.id, equals('new-id'));
        expect(modified.email, equals('new@example.com'));
        expect(modified.name, equals('New Name'));
        expect(modified.avatarUrl, equals('https://new-avatar.com'));
        expect(modified.bio, equals('New bio'));
        expect(modified.location, equals('New York'));
        expect(modified.latitude, equals(40.7128));
        expect(modified.longitude, equals(-74.0060));
        expect(modified.interests, equals(['new', 'interests']));
        expect(modified.eventsCreated, equals(10));
        expect(modified.eventsAttended, equals(20));
        expect(modified.rating, equals(5.0));
        expect(modified.isVerified, isTrue);
        expect(modified.createdAt, equals(newCreatedAt));
        expect(modified.updatedAt, equals(newUpdatedAt));
      });
    });

    group('Computed Properties', () {
      group('isProfileComplete', () {
        test('devrait retourner true si le profil est complet', () {
          // Arrange
          final user = TestData.createUser(
            name: 'John Doe',
            bio: 'A complete bio',
            interests: ['tech'],
          );

          // Act & Assert
          expect(user.isProfileComplete, isTrue);
        });

        test('devrait retourner false si le nom est vide', () {
          // Arrange
          final user = TestData.createUser(
            name: '',
            bio: 'A bio',
            interests: ['tech'],
          );

          // Act & Assert
          expect(user.isProfileComplete, isFalse);
        });

        test('devrait retourner false si la bio est null', () {
          // Arrange
          final user = TestData.createUser(
            name: 'John',
            bio: null,
            interests: ['tech'],
          );

          // Act & Assert
          expect(user.isProfileComplete, isFalse);
        });

        test('devrait retourner false si la bio est vide', () {
          // Arrange
          final user = TestData.createUser(
            name: 'John',
            bio: '',
            interests: ['tech'],
          );

          // Act & Assert
          expect(user.isProfileComplete, isFalse);
        });

        test('devrait retourner false si les interests sont vides', () {
          // Arrange
          final user = TestData.createUser(
            name: 'John',
            bio: 'A bio',
            interests: [],
          );

          // Act & Assert
          expect(user.isProfileComplete, isFalse);
        });
      });

      group('hasLocation', () {
        test('devrait retourner true si latitude et longitude sont definies', () {
          // Arrange
          final user = TestData.createUser(
            latitude: 48.8566,
            longitude: 2.3522,
          );

          // Act & Assert
          expect(user.hasLocation, isTrue);
        });

        test('devrait retourner false si latitude est null', () {
          // Arrange
          final user = TestData.createUser(
            latitude: null,
            longitude: 2.3522,
          );

          // Act & Assert
          expect(user.hasLocation, isFalse);
        });

        test('devrait retourner false si longitude est null', () {
          // Arrange
          final user = TestData.createUser(
            latitude: 48.8566,
            longitude: null,
          );

          // Act & Assert
          expect(user.hasLocation, isFalse);
        });

        test('devrait retourner false si les deux sont null', () {
          // Arrange
          final user = TestData.createUser(
            latitude: null,
            longitude: null,
          );

          // Act & Assert
          expect(user.hasLocation, isFalse);
        });
      });

      group('initials', () {
        test('devrait retourner les initiales pour un nom complet', () {
          // Arrange
          final user = TestData.createUser(name: 'John Doe');

          // Act & Assert
          expect(user.initials, equals('JD'));
        });

        test('devrait retourner une seule lettre pour un seul mot', () {
          // Arrange
          final user = TestData.createUser(name: 'John');

          // Act & Assert
          expect(user.initials, equals('J'));
        });

        test('devrait gerer plusieurs mots et prendre premier et dernier', () {
          // Arrange
          final user = TestData.createUser(name: 'John Michael Doe');

          // Act & Assert
          expect(user.initials, equals('JD'));
        });

        test('devrait retourner les initiales en majuscules', () {
          // Arrange
          final user = TestData.createUser(name: 'john doe');

          // Act & Assert
          expect(user.initials, equals('JD'));
        });

        test('devrait gerer les espaces en trop', () {
          // Arrange
          final user = TestData.createUser(name: '  John Doe  ');

          // Act & Assert
          expect(user.initials, equals('JD'));
        });
      });
    });

    group('Equatable', () {
      test('deux UserModels avec les memes valeurs devraient etre egaux', () {
        // Arrange
        final user1 = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );
        final user2 = UserModel(
          id: 'user-123',
          email: 'john@example.com',
          name: 'John Doe',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('deux UserModels avec des valeurs differentes ne devraient pas etre egaux', () {
        // Arrange
        final user1 = TestData.createUser(id: 'user-123');
        final user2 = TestData.createUser(id: 'user-456');

        // Assert
        expect(user1, isNot(equals(user2)));
      });
    });

    group('toString()', () {
      test('devrait retourner une representation lisible', () {
        // Arrange
        final user = TestData.createUser(
          id: 'user-123',
          name: 'John Doe',
          email: 'john@example.com',
        );

        // Act
        final result = user.toString();

        // Assert
        expect(result, contains('UserModel'));
        expect(result, contains('user-123'));
        expect(result, contains('John Doe'));
        expect(result, contains('john@example.com'));
      });
    });
  });
}
