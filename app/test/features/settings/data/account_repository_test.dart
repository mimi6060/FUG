import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';

import 'package:fug_app/features/settings/data/account_repository.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late AccountRepository accountRepository;
  late MockAppwriteService mockAppwriteService;
  late MockAccount mockAccount;
  late MockDatabases mockDatabases;

  setUpAll(() {
    setUpTestHelpers();
  });

  setUp(() {
    mockAppwriteService = MockAppwriteService();
    mockAccount = MockAccount();
    mockDatabases = MockDatabases();

    when(() => mockAppwriteService.account).thenReturn(mockAccount);
    when(() => mockAppwriteService.databases).thenReturn(mockDatabases);

    accountRepository = AccountRepository(appwrite: mockAppwriteService);
  });

  group('AccountRepository', () {
    group('requestAccountDeletion()', () {
      test('devrait echouer si le mot de passe est incorrect', () async {
        // Arrange
        const userId = 'user-123';
        const password = 'wrongPassword';

        when(() => mockAccount.get()).thenAnswer((_) async => FakeUser());
        when(() => mockAccount.createEmailPasswordSession(
              email: any(named: 'email'),
              password: password,
            )).thenThrow(AppwriteException('Invalid credentials', 401));

        // Act & Assert
        expect(
          () => accountRepository.requestAccountDeletion(
            userId: userId,
            password: password,
          ),
          throwsA(
            isA<AccountException>().having(
              (e) => e.message,
              'message',
              contains('Mot de passe incorrect'),
            ),
          ),
        );
      });

      test('devrait creer une demande de suppression avec succes', () async {
        // Arrange
        const userId = 'user-123';
        const password = 'validPassword';
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 30));

        // Verification du mot de passe
        when(() => mockAccount.get()).thenAnswer((_) async => FakeUser());
        when(() => mockAccount.createEmailPasswordSession(
              email: any(named: 'email'),
              password: password,
            )).thenAnswer((_) async => FakeSession());

        // Pas de demande existante
        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer((_) async => createMockDocumentList([]));

        // Creation de la demande
        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((_) async => createMockDocument({
              '\$id': 'request-123',
              'userId': userId,
              'requestedAt': now.toIso8601String(),
              'scheduledDeletionAt': scheduledAt.toIso8601String(),
              'status': 'pending',
              'cancellationReason': null,
            }));

        // Act
        final result = await accountRepository.requestAccountDeletion(
          userId: userId,
          password: password,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.userId, equals(userId));
        expect(result.status, equals('pending'));
        expect(result.canBeCancelled, isTrue);
      });

      test('devrait echouer si une demande est deja en cours', () async {
        // Arrange
        const userId = 'user-123';
        const password = 'validPassword';
        final now = DateTime.now();

        // Verification du mot de passe
        when(() => mockAccount.get()).thenAnswer((_) async => FakeUser());
        when(() => mockAccount.createEmailPasswordSession(
              email: any(named: 'email'),
              password: password,
            )).thenAnswer((_) async => FakeSession());

        // Demande existante
        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer((_) async => createMockDocumentList([
              {
                '\$id': 'existing-request',
                'userId': userId,
                'requestedAt': now.toIso8601String(),
                'scheduledDeletionAt': now.add(const Duration(days: 30)).toIso8601String(),
                'status': 'pending',
              },
            ]));

        // Act & Assert
        expect(
          () => accountRepository.requestAccountDeletion(
            userId: userId,
            password: password,
          ),
          throwsA(
            isA<AccountException>().having(
              (e) => e.message,
              'message',
              contains('deja en cours'),
            ),
          ),
        );
      });
    });

    group('cancelAccountDeletion()', () {
      test('devrait annuler une demande avec succes', () async {
        // Arrange
        const requestId = 'request-123';

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: requestId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((_) async => createMockDocument({
              '\$id': requestId,
              'status': 'cancelled',
            }));

        // Act
        await accountRepository.cancelAccountDeletion(requestId: requestId);

        // Assert
        verify(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: requestId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).called(1);
      });

      test('devrait inclure la raison d\'annulation si fournie', () async {
        // Arrange
        const requestId = 'request-123';
        const reason = 'Je change d\'avis';

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: requestId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((_) async => createMockDocument({
              '\$id': requestId,
              'status': 'cancelled',
              'cancellationReason': reason,
            }));

        // Act
        await accountRepository.cancelAccountDeletion(
          requestId: requestId,
          reason: reason,
        );

        // Assert - verifie que les donnees contiennent la raison
        verify(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: requestId,
              data: argThat(
                containsPair('cancellationReason', reason),
                named: 'data',
              ),
              permissions: any(named: 'permissions'),
            )).called(1);
      });
    });

    group('getPendingDeletionRequest()', () {
      test('devrait retourner null si pas de demande', () async {
        // Arrange
        const userId = 'user-123';

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer((_) async => createMockDocumentList([]));

        // Act
        final result = await accountRepository.getPendingDeletionRequest(userId);

        // Assert
        expect(result, isNull);
      });

      test('devrait retourner la demande si elle existe', () async {
        // Arrange
        const userId = 'user-123';
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 25));

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenAnswer((_) async => createMockDocumentList([
              {
                '\$id': 'request-123',
                'userId': userId,
                'requestedAt': now.subtract(const Duration(days: 5)).toIso8601String(),
                'scheduledDeletionAt': scheduledAt.toIso8601String(),
                'status': 'pending',
              },
            ]));

        // Act
        final result = await accountRepository.getPendingDeletionRequest(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.userId, equals(userId));
        expect(result.status, equals('pending'));
        expect(result.canBeCancelled, isTrue);
      });

      test('devrait retourner null en cas d\'erreur', () async {
        // Arrange
        const userId = 'user-123';

        when(() => mockDatabases.listDocuments(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              queries: any(named: 'queries'),
            )).thenThrow(AppwriteException('Error', 500));

        // Act
        final result = await accountRepository.getPendingDeletionRequest(userId);

        // Assert
        expect(result, isNull);
      });
    });

    group('getDataToBeDeleted()', () {
      test('devrait retourner la liste des donnees a supprimer', () {
        // Act
        final result = accountRepository.getDataToBeDeleted();

        // Assert
        expect(result, isNotEmpty);
        expect(result, isA<List<String>>());
        expect(result.length, greaterThan(5));
      });
    });

    group('getDataToBeAnonymized()', () {
      test('devrait retourner la liste des donnees a anonymiser', () {
        // Act
        final result = accountRepository.getDataToBeAnonymized();

        // Assert
        expect(result, isNotEmpty);
        expect(result, isA<List<String>>());
      });
    });
  });

  group('AccountDeletionRequest', () {
    group('fromJson()', () {
      test('devrait parser correctement un JSON valide', () {
        // Arrange
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 30));
        final json = {
          '\$id': 'request-123',
          'userId': 'user-456',
          'requestedAt': now.toIso8601String(),
          'scheduledDeletionAt': scheduledAt.toIso8601String(),
          'status': 'pending',
          'cancellationReason': null,
        };

        // Act
        final request = AccountDeletionRequest.fromJson(json);

        // Assert
        expect(request.id, equals('request-123'));
        expect(request.userId, equals('user-456'));
        expect(request.status, equals('pending'));
        expect(request.cancellationReason, isNull);
      });

      test('devrait parser la raison d\'annulation si presente', () {
        // Arrange
        final now = DateTime.now();
        final json = {
          '\$id': 'request-123',
          'userId': 'user-456',
          'requestedAt': now.toIso8601String(),
          'scheduledDeletionAt': now.add(const Duration(days: 30)).toIso8601String(),
          'status': 'cancelled',
          'cancellationReason': 'Je change d\'avis',
        };

        // Act
        final request = AccountDeletionRequest.fromJson(json);

        // Assert
        expect(request.status, equals('cancelled'));
        expect(request.cancellationReason, equals('Je change d\'avis'));
      });
    });

    group('toJson()', () {
      test('devrait serialiser correctement en JSON', () {
        // Arrange
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 30));
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: scheduledAt,
          status: 'pending',
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['userId'], equals('user-456'));
        expect(json['status'], equals('pending'));
        expect(json.containsKey('\$id'), isFalse);
      });
    });

    group('canBeCancelled', () {
      test('devrait retourner true pour une demande en attente non expiree', () {
        // Arrange
        final now = DateTime.now();
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: now.add(const Duration(days: 30)),
          status: 'pending',
        );

        // Assert
        expect(request.canBeCancelled, isTrue);
      });

      test('devrait retourner false si le statut n\'est pas pending', () {
        // Arrange
        final now = DateTime.now();
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: now.add(const Duration(days: 30)),
          status: 'cancelled',
        );

        // Assert
        expect(request.canBeCancelled, isFalse);
      });

      test('devrait retourner false si la date de suppression est passee', () {
        // Arrange
        final now = DateTime.now();
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now.subtract(const Duration(days: 35)),
          scheduledDeletionAt: now.subtract(const Duration(days: 5)),
          status: 'pending',
        );

        // Assert
        expect(request.canBeCancelled, isFalse);
      });
    });

    group('daysUntilDeletion', () {
      test('devrait retourner le nombre de jours restants', () {
        // Arrange
        final now = DateTime.now();
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: now.add(const Duration(days: 15)),
          status: 'pending',
        );

        // Assert
        expect(request.daysUntilDeletion, equals(15));
      });

      test('devrait retourner 0 si la demande ne peut pas etre annulee', () {
        // Arrange
        final now = DateTime.now();
        final request = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: now.add(const Duration(days: 15)),
          status: 'cancelled',
        );

        // Assert
        expect(request.daysUntilDeletion, equals(0));
      });
    });

    group('Equatable', () {
      test('deux demandes identiques devraient etre egales', () {
        // Arrange
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 30));

        final request1 = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: scheduledAt,
          status: 'pending',
        );

        final request2 = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: scheduledAt,
          status: 'pending',
        );

        // Assert
        expect(request1, equals(request2));
      });

      test('deux demandes avec des IDs differents ne devraient pas etre egales', () {
        // Arrange
        final now = DateTime.now();
        final scheduledAt = now.add(const Duration(days: 30));

        final request1 = AccountDeletionRequest(
          id: 'request-123',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: scheduledAt,
          status: 'pending',
        );

        final request2 = AccountDeletionRequest(
          id: 'request-789',
          userId: 'user-456',
          requestedAt: now,
          scheduledDeletionAt: scheduledAt,
          status: 'pending',
        );

        // Assert
        expect(request1, isNot(equals(request2)));
      });
    });
  });

  group('AccountException', () {
    test('devrait contenir le message et le code', () {
      // Arrange & Act
      final exception = AccountException('Test error', code: 400);

      // Assert
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals(400));
    });

    test('toString devrait retourner une representation lisible', () {
      // Arrange
      final exception = AccountException('Test error');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('AccountException: Test error'));
    });

    test('code devrait etre optionnel', () {
      // Arrange & Act
      final exception = AccountException('Test error');

      // Assert
      expect(exception.code, isNull);
    });
  });
}
