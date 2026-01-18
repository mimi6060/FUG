import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:fug_app/features/auth/data/auth_repository.dart';
import 'package:fug_app/features/auth/domain/user_model.dart';
import 'package:fug_app/core/services/appwrite_service.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late AuthRepository authRepository;
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

    // Setup default mock behavior
    when(() => mockAppwriteService.account).thenReturn(mockAccount);
    when(() => mockAppwriteService.databases).thenReturn(mockDatabases);

    authRepository = AuthRepository(appwrite: mockAppwriteService);
  });

  group('AuthRepository', () {
    group('isLoggedIn()', () {
      test('devrait retourner true si un utilisateur est connecte', () async {
        // Arrange
        when(() => mockAccount.get()).thenAnswer(
          (_) async => FakeUser(),
        );

        // Act
        final result = await authRepository.isLoggedIn();

        // Assert
        expect(result, isTrue);
        verify(() => mockAccount.get()).called(1);
      });

      test('devrait retourner false si aucun utilisateur n\'est connecte', () async {
        // Arrange
        when(() => mockAccount.get()).thenThrow(
          AppwriteException('User not logged in', 401),
        );

        // Act
        final result = await authRepository.isLoggedIn();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getCurrentUser()', () {
      test('devrait retourner l\'utilisateur courant si connecte', () async {
        // Arrange
        final fakeUser = FakeUser();
        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!.$id, equals('fake-user-id'));
        verify(() => mockAccount.get()).called(1);
      });

      test('devrait retourner null si non connecte', () async {
        // Arrange
        when(() => mockAccount.get()).thenThrow(
          AppwriteException('Unauthorized', 401),
        );

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('getCurrentSession()', () {
      test('devrait retourner la session courante', () async {
        // Arrange
        final fakeSession = FakeSession();
        when(() => mockAccount.getSession(sessionId: 'current'))
            .thenAnswer((_) async => fakeSession);

        // Act
        final result = await authRepository.getCurrentSession();

        // Assert
        expect(result, isNotNull);
        expect(result!.$id, equals('fake-session-id'));
      });

      test('devrait retourner null si pas de session', () async {
        // Arrange
        when(() => mockAccount.getSession(sessionId: 'current')).thenThrow(
          AppwriteException('No session', 401),
        );

        // Act
        final result = await authRepository.getCurrentSession();

        // Assert
        expect(result, isNull);
      });
    });

    group('signUp()', () {
      test('devrait creer un compte avec succes', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        const name = 'Test User';
        final fakeUser = FakeUser();
        final fakeSession = FakeSession();

        when(() => mockAccount.create(
              userId: any(named: 'userId'),
              email: email,
              password: password,
              name: name,
            )).thenAnswer((_) async => fakeUser);

        when(() => mockAccount.createEmailPasswordSession(
              email: email,
              password: password,
            )).thenAnswer((_) async => fakeSession);

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(TestData.createUserJson()),
        );

        // Act
        final result = await authRepository.signUp(
          email: email,
          password: password,
          name: name,
        );

        // Assert
        expect(result.$id, equals('fake-user-id'));
        verify(() => mockAccount.create(
              userId: any(named: 'userId'),
              email: email,
              password: password,
              name: name,
            )).called(1);
      });

      test('devrait lancer AuthException si l\'email existe deja', () async {
        // Arrange
        when(() => mockAccount.create(
              userId: any(named: 'userId'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
            )).thenThrow(AppwriteException('Email already exists', 409));

        // Act & Assert
        expect(
          () => authRepository.signUp(
            email: 'existing@example.com',
            password: 'password123',
            name: 'Test',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('devrait lancer AuthException pour mot de passe invalide', () async {
        // Arrange
        when(() => mockAccount.create(
              userId: any(named: 'userId'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
            )).thenThrow(
          AppwriteException('password must be at least 8 characters', 400),
        );

        // Act & Assert
        expect(
          () => authRepository.signUp(
            email: 'test@example.com',
            password: 'short',
            name: 'Test',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('8 caractères'),
            ),
          ),
        );
      });
    });

    group('signInWithEmail()', () {
      test('devrait connecter l\'utilisateur avec succes', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final fakeSession = FakeSession();

        when(() => mockAccount.createEmailPasswordSession(
              email: email,
              password: password,
            )).thenAnswer((_) async => fakeSession);

        // Act
        final result = await authRepository.signInWithEmail(
          email: email,
          password: password,
        );

        // Assert
        expect(result.$id, equals('fake-session-id'));
        verify(() => mockAccount.createEmailPasswordSession(
              email: email,
              password: password,
            )).called(1);
      });

      test('devrait lancer AuthException pour identifiants invalides', () async {
        // Arrange
        when(() => mockAccount.createEmailPasswordSession(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          AppwriteException('Invalid credentials', 401),
        );

        // Act & Assert
        expect(
          () => authRepository.signInWithEmail(
            email: 'wrong@example.com',
            password: 'wrongpassword',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('incorrect'),
            ),
          ),
        );
      });

      test('devrait lancer AuthException pour trop de tentatives', () async {
        // Arrange
        when(() => mockAccount.createEmailPasswordSession(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          AppwriteException('Too many requests', 429),
        );

        // Act & Assert
        expect(
          () => authRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'password',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('Trop de tentatives'),
            ),
          ),
        );
      });
    });

    group('signInAnonymously()', () {
      test('devrait creer une session anonyme', () async {
        // Arrange
        final fakeSession = FakeSession();
        when(() => mockAccount.createAnonymousSession())
            .thenAnswer((_) async => fakeSession);

        // Act
        final result = await authRepository.signInAnonymously();

        // Assert
        expect(result, isNotNull);
        verify(() => mockAccount.createAnonymousSession()).called(1);
      });

      test('devrait lancer AuthException en cas d\'erreur', () async {
        // Arrange
        when(() => mockAccount.createAnonymousSession()).thenThrow(
          AppwriteException('Error', 500),
        );

        // Act & Assert
        expect(
          () => authRepository.signInAnonymously(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut()', () {
      test('devrait deconnecter l\'utilisateur', () async {
        // Arrange
        when(() => mockAccount.deleteSession(sessionId: 'current'))
            .thenAnswer((_) async => {});

        // Act
        await authRepository.signOut();

        // Assert
        verify(() => mockAccount.deleteSession(sessionId: 'current')).called(1);
      });

      test('devrait lancer AuthException en cas d\'erreur', () async {
        // Arrange
        when(() => mockAccount.deleteSession(sessionId: 'current')).thenThrow(
          AppwriteException('Error', 500),
        );

        // Act & Assert
        expect(
          () => authRepository.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOutAll()', () {
      test('devrait deconnecter toutes les sessions', () async {
        // Arrange
        when(() => mockAccount.deleteSessions()).thenAnswer((_) async => {});

        // Act
        await authRepository.signOutAll();

        // Assert
        verify(() => mockAccount.deleteSessions()).called(1);
      });
    });

    group('getUserProfile()', () {
      test('devrait retourner le profil utilisateur', () async {
        // Arrange
        const userId = 'user-123';
        final userJson = TestData.createUserJson(
          userId: userId,
          name: 'John Doe',
          email: 'john@example.com',
        );

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: userId,
            )).thenAnswer(
          (_) async => createMockDocument(userJson),
        );

        // Act
        final result = await authRepository.getUserProfile(userId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(userId));
        expect(result.name, equals('John Doe'));
        expect(result.email, equals('john@example.com'));
      });

      test('devrait retourner null si le profil n\'existe pas', () async {
        // Arrange
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(
          AppwriteException('Document not found', 404),
        );

        // Act
        final result = await authRepository.getUserProfile('non-existent');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateUserProfile()', () {
      test('devrait mettre a jour le profil avec succes', () async {
        // Arrange
        const userId = 'user-123';
        const newName = 'Jane Doe';
        const newBio = 'Updated bio';

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: userId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(TestData.createUserJson(
            userId: userId,
            name: newName,
            bio: newBio,
          )),
        );

        when(() => mockAccount.updateName(name: newName))
            .thenAnswer((_) async => FakeUser());

        // Act
        await authRepository.updateUserProfile(
          userId: userId,
          name: newName,
          bio: newBio,
        );

        // Assert
        verify(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: userId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).called(1);
      });

      test('devrait aussi mettre a jour le nom dans Account', () async {
        // Arrange
        const userId = 'user-123';
        const newName = 'New Name';

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: userId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(TestData.createUserJson()),
        );

        when(() => mockAccount.updateName(name: newName))
            .thenAnswer((_) async => FakeUser());

        // Act
        await authRepository.updateUserProfile(
          userId: userId,
          name: newName,
        );

        // Assert
        verify(() => mockAccount.updateName(name: newName)).called(1);
      });

      test('devrait ne pas appeler updateName si name est null', () async {
        // Arrange
        const userId = 'user-123';

        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: userId,
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer(
          (_) async => createMockDocument(TestData.createUserJson()),
        );

        // Act
        await authRepository.updateUserProfile(
          userId: userId,
          bio: 'New bio only',
        );

        // Assert
        verifyNever(() => mockAccount.updateName(name: any(named: 'name')));
      });

      test('devrait lancer AuthException en cas d\'erreur', () async {
        // Arrange
        when(() => mockDatabases.updateDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenThrow(
          AppwriteException('Error', 500),
        );

        // Act & Assert
        expect(
          () => authRepository.updateUserProfile(
            userId: 'user-123',
            name: 'Test',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendPasswordRecovery()', () {
      test('devrait envoyer un email de recuperation', () async {
        // Arrange
        const email = 'test@example.com';
        when(() => mockAccount.createRecovery(
              email: email,
              url: any(named: 'url'),
            )).thenAnswer((_) async => models.Token(
              $id: 'token-123',
              $createdAt: DateTime.now().toIso8601String(),
              userId: 'user-123',
              secret: 'secret',
              expire: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
              phrase: '',
            ));

        // Act
        await authRepository.sendPasswordRecovery(email: email);

        // Assert
        verify(() => mockAccount.createRecovery(
              email: email,
              url: any(named: 'url'),
            )).called(1);
      });

      test('devrait lancer AuthException en cas d\'erreur', () async {
        // Arrange
        when(() => mockAccount.createRecovery(
              email: any(named: 'email'),
              url: any(named: 'url'),
            )).thenThrow(
          AppwriteException('Error', 400),
        );

        // Act & Assert
        expect(
          () => authRepository.sendPasswordRecovery(email: 'test@example.com'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('changePassword()', () {
      test('devrait changer le mot de passe avec succes', () async {
        // Arrange
        const oldPassword = 'oldPassword123';
        const newPassword = 'newPassword456';

        when(() => mockAccount.updatePassword(
              password: newPassword,
              oldPassword: oldPassword,
            )).thenAnswer((_) async => FakeUser());

        // Act
        await authRepository.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );

        // Assert
        verify(() => mockAccount.updatePassword(
              password: newPassword,
              oldPassword: oldPassword,
            )).called(1);
      });

      test('devrait lancer AuthException pour ancien mot de passe invalide', () async {
        // Arrange
        when(() => mockAccount.updatePassword(
              password: any(named: 'password'),
              oldPassword: any(named: 'oldPassword'),
            )).thenThrow(
          AppwriteException('Invalid password', 401),
        );

        // Act & Assert
        expect(
          () => authRepository.changePassword(
            oldPassword: 'wrong',
            newPassword: 'newpass123',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('sendEmailVerification()', () {
      test('devrait envoyer un email de verification', () async {
        // Arrange
        when(() => mockAccount.createVerification(
              url: any(named: 'url'),
            )).thenAnswer((_) async => models.Token(
              $id: 'token-123',
              $createdAt: DateTime.now().toIso8601String(),
              userId: 'user-123',
              secret: 'secret',
              expire: DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
              phrase: '',
            ));

        // Act
        await authRepository.sendEmailVerification();

        // Assert
        verify(() => mockAccount.createVerification(
              url: any(named: 'url'),
            )).called(1);
      });
    });
  });

  group('AuthException', () {
    test('devrait contenir le message et le code', () {
      // Arrange & Act
      final exception = AuthException('Test error', code: 400);

      // Assert
      expect(exception.message, equals('Test error'));
      expect(exception.code, equals(400));
    });

    test('toString devrait retourner une representation lisible', () {
      // Arrange
      final exception = AuthException('Test error');

      // Act
      final result = exception.toString();

      // Assert
      expect(result, equals('AuthException: Test error'));
    });

    test('code devrait etre optionnel', () {
      // Arrange & Act
      final exception = AuthException('Test error');

      // Assert
      expect(exception.code, isNull);
    });
  });
}
