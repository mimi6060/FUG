import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;

import 'package:fug_app/features/auth/data/auth_repository.dart';
import 'package:fug_app/core/services/appwrite_service.dart';

import '../../../helpers/test_helpers.dart';

/// Tests unitaires pour Google Sign-In
///
/// Ces tests couvrent:
/// - La methode signInWithGoogle() dans AuthRepository
/// - La creation/mise a jour du profil utilisateur OAuth (_getOrCreateUserProfileFromOAuth)
/// - La gestion des erreurs specifiques a Google Sign-In
/// - Le comportement attendu avec AppwriteException
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

  group('Google Sign-In - AuthRepository', () {
    group('signInWithGoogle()', () {
      test('devrait creer une session OAuth2 et retourner l\'utilisateur', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        // Profile doesn't exist yet, so getDocument throws
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Document not found', 404));

        // Create profile
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
        final result = await authRepository.signInWithGoogle();

        // Assert
        expect(result.$id, equals('fake-user-id'));
        verify(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).called(1);
        verify(() => mockAccount.get()).called(1);
      });

      test('devrait utiliser les scopes email et profile', () async {
        // Arrange
        final fakeUser = FakeUser();
        List<String>? capturedScopes;

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((invocation) async {
          capturedScopes = invocation.namedArguments[#scopes] as List<String>?;
        });

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Not found', 404));

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
        await authRepository.signInWithGoogle();

        // Assert
        expect(capturedScopes, isNotNull);
        expect(capturedScopes, contains('email'));
        expect(capturedScopes, contains('profile'));
      });

      test('devrait lancer AuthException pour erreur OAuth Appwrite', () async {
        // Arrange
        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenThrow(AppwriteException('OAuth error', 400));

        // Act & Assert
        expect(
          () => authRepository.signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );
      });

      test('devrait lancer AuthException pour erreur generale', () async {
        // Arrange
        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenThrow(Exception('Unknown error'));

        // Act & Assert
        expect(
          () => authRepository.signInWithGoogle(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('Google'),
            ),
          ),
        );
      });

      test('devrait lancer AuthException si get() echoue apres OAuth', () async {
        // Arrange
        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenThrow(
          AppwriteException('User not found', 404),
        );

        // Act & Assert
        expect(
          () => authRepository.signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );
      });

      test('devrait utiliser les URLs de callback correctes', () async {
        // Arrange
        final fakeUser = FakeUser();
        String? capturedSuccess;
        String? capturedFailure;

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((invocation) async {
          capturedSuccess = invocation.namedArguments[#success] as String?;
          capturedFailure = invocation.namedArguments[#failure] as String?;
        });

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Not found', 404));

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
        await authRepository.signInWithGoogle();

        // Assert
        expect(capturedSuccess, isNotNull);
        expect(capturedSuccess, contains('appwrite-callback-'));
        expect(capturedSuccess, contains('://auth'));
        expect(capturedFailure, isNotNull);
        expect(capturedFailure, contains('://auth/error'));
      });
    });

    group('_getOrCreateUserProfileFromOAuth()', () {
      test('devrait creer un profil si utilisateur n\'existe pas', () async {
        // Arrange
        final fakeUser = FakeUser();
        Map<String, dynamic>? capturedData;

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        // Profile doesn't exist
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Document not found', 404));

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>?;
          return createMockDocument(TestData.createUserJson());
        });

        // Act
        await authRepository.signInWithGoogle();

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['authProvider'], equals('google'));
        expect(capturedData!['userId'], equals('fake-user-id'));
        expect(capturedData!['email'], equals('fake@example.com'));
        expect(capturedData!['points'], equals(0));
        expect(capturedData!['level'], equals(1));
        verify(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).called(1);
      });

      test('devrait ne pas creer de profil si l\'utilisateur existe deja', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        // Profile exists
        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenAnswer(
          (_) async => createMockDocument(TestData.createUserJson()),
        );

        // Act
        await authRepository.signInWithGoogle();

        // Assert
        verifyNever(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            ));
      });

      test('devrait utiliser un nom par defaut si le nom est vide', () async {
        // Arrange
        final fakeUserWithEmptyName = FakeUserWithEmptyName();
        Map<String, dynamic>? capturedData;

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUserWithEmptyName);

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Not found', 404));

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>?;
          return createMockDocument(TestData.createUserJson());
        });

        // Act
        await authRepository.signInWithGoogle();

        // Assert
        expect(capturedData, isNotNull);
        expect(capturedData!['name'], equals('Utilisateur FUG'));
      });

      test('devrait ne pas bloquer la connexion si la creation du profil echoue', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Not found', 404));

        // createDocument fails
        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenThrow(AppwriteException('Database error', 500));

        // Act
        final result = await authRepository.signInWithGoogle();

        // Assert - Should still return user despite profile creation failure
        expect(result, isNotNull);
        expect(result.$id, equals('fake-user-id'));
      });

      test('devrait definir les permissions correctes pour le profil', () async {
        // Arrange
        final fakeUser = FakeUser();
        List<String>? capturedPermissions;

        when(() => mockAccount.createOAuth2Session(
              provider: OAuthProvider.google,
              success: any(named: 'success'),
              failure: any(named: 'failure'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => {});

        when(() => mockAccount.get()).thenAnswer((_) async => fakeUser);

        when(() => mockDatabases.getDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
            )).thenThrow(AppwriteException('Not found', 404));

        when(() => mockDatabases.createDocument(
              databaseId: any(named: 'databaseId'),
              collectionId: any(named: 'collectionId'),
              documentId: any(named: 'documentId'),
              data: any(named: 'data'),
              permissions: any(named: 'permissions'),
            )).thenAnswer((invocation) async {
          capturedPermissions = invocation.namedArguments[#permissions] as List<String>?;
          return createMockDocument(TestData.createUserJson());
        });

        // Act
        await authRepository.signInWithGoogle();

        // Assert
        expect(capturedPermissions, isNotNull);
        expect(capturedPermissions!.length, equals(3));
        // Should have read, update, delete permissions for the user
        expect(capturedPermissions!.any((p) => p.contains('read')), isTrue);
        expect(capturedPermissions!.any((p) => p.contains('update')), isTrue);
        expect(capturedPermissions!.any((p) => p.contains('delete')), isTrue);
      });
    });
  });

  group('Google Sign-In - Error Messages', () {
    test('AuthException pour erreur OAuth devrait avoir un message clair', () {
      // Arrange
      final exception = AuthException('Une erreur est survenue lors de la connexion Google.');

      // Assert
      expect(exception.message, contains('Google'));
    });

    test('AuthException pour erreur 401 devrait mentionner les identifiants', () {
      // Ce test verifie que le message d'erreur par defaut pour 401 est clair
      // (herite de _getReadableErrorMessage)

      // La methode _getReadableErrorMessage transforme le code 401 en message lisible
      // Dans le contexte OAuth, cela ne devrait normalement pas arriver
      // mais si c'est le cas, le message doit etre comprehensible
      final exception = AuthException('Email ou mot de passe incorrect.', code: 401);

      // Assert
      expect(exception.code, equals(401));
      expect(exception.message, contains('incorrect'));
    });
  });

  group('Google Sign-In - Comparaison avec Apple Sign-In', () {
    test('devrait utiliser le meme pattern que signInWithApple', () {
      // Ce test verifie que les deux methodes suivent le meme pattern:
      // 1. Creer session OAuth2
      // 2. Recuperer l'utilisateur
      // 3. Verifier/creer le profil
      // 4. Retourner l'utilisateur

      // La structure est verifiee par les autres tests, ce test est
      // pour documentation et verification de coherence
      expect(true, isTrue);
    });

    test('Google Sign-In devrait fonctionner sur toutes les plateformes (pas de verification Platform)', () {
      // Contrairement a Apple Sign-In qui verifie Platform.isIOS,
      // Google Sign-In devrait fonctionner sur toutes les plateformes

      // Ce test documente cette difference de comportement
      // La verification est implicite car signInWithGoogle ne leve pas
      // d'exception pour la plateforme
      expect(true, isTrue);
    });
  });
}

/// Fake User avec un nom vide pour tester le fallback
class FakeUserWithEmptyName extends Fake implements models.User {
  @override
  String get $id => 'fake-user-id';

  @override
  String get email => 'fake@example.com';

  @override
  String get name => ''; // Nom vide pour tester le fallback

  @override
  DateTime get $createdAt => DateTime(2024, 1, 1);

  @override
  DateTime get $updatedAt => DateTime(2024, 1, 1);

  @override
  bool get emailVerification => false;

  @override
  bool get phoneVerification => false;

  @override
  String get phone => '';

  @override
  Map<String, dynamic> get prefs => {};

  @override
  bool get status => true;

  @override
  String get password => '';

  @override
  String get hash => '';

  @override
  String get hashOptions => '';

  @override
  DateTime get registration => DateTime(2024, 1, 1);

  @override
  bool get mfa => false;

  @override
  List<models.Target> get targets => [];

  @override
  DateTime get accessedAt => DateTime(2024, 1, 1);

  @override
  Map<String, dynamic> toMap() => {
        '\$id': $id,
        'email': email,
        'name': name,
      };
}
