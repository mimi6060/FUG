import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:fug_app/core/providers/auth_provider.dart';
import 'package:fug_app/features/auth/data/auth_repository.dart';

import '../../helpers/test_helpers.dart';

/// Mock du AuthRepository pour les tests de provider
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUpAll(() {
    setUpTestHelpers();
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();

    // Default stub for ensureUserProfileExists (called in build() when user exists)
    when(() => mockAuthRepository.ensureUserProfileExists())
        .thenAnswer((_) async {});

    // Creer un container avec le mock injecte
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthStateNotifier', () {
    group('build()', () {
      test('devrait verifier l\'utilisateur courant au demarrage', () async {
        // Arrange
        final fakeUser = FakeUser();
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        // Act
        final authState = container.read(authStateProvider);

        // Attendre que le provider soit initialise
        await container.read(authStateProvider.future);

        // Assert
        verify(() => mockAuthRepository.getCurrentUser()).called(1);
      });

      test('devrait retourner null si aucun utilisateur connecte', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(authStateProvider.future);

        // Assert
        expect(result, isNull);
      });
    });

    group('signInWithEmail()', () {
      test('devrait mettre a jour l\'etat avec l\'utilisateur connecte', () async {
        // Arrange
        final fakeUser = FakeUser();
        final fakeSession = FakeSession();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => fakeSession);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        // Attendre l'initialisation
        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            );

        // Assert
        verify(() => mockAuthRepository.signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            )).called(1);
      });

      test('devrait gerer les erreurs d\'authentification', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(AuthException('Email ou mot de passe incorrect.'));

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithEmail(
              email: 'wrong@example.com',
              password: 'wrongpassword',
            );

        // Assert
        final state = container.read(authStateProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('signUp()', () {
      test('devrait creer un compte et mettre a jour l\'etat', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
            )).thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signUp(
              email: 'new@example.com',
              password: 'password123',
              name: 'New User',
            );

        // Assert
        verify(() => mockAuthRepository.signUp(
              email: 'new@example.com',
              password: 'password123',
              name: 'New User',
            )).called(1);
      });
    });

    group('signInWithGoogle()', () {
      test('devrait appeler signInWithGoogle sur le repository', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithGoogle();

        // Assert
        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
        verify(() => mockAuthRepository.getCurrentUser()).called(greaterThan(0));
      });

      test('devrait mettre l\'etat en loading pendant la connexion', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act - Lancer sans await pour capturer l'etat loading
        final future = container.read(authStateProvider.notifier).signInWithGoogle();

        // L'etat devrait etre loading
        final stateWhileLoading = container.read(authStateProvider);
        expect(stateWhileLoading.isLoading, isTrue);

        // Attendre la fin
        await future;
      });

      test('devrait mettre a jour l\'etat avec l\'utilisateur apres connexion', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithGoogle();

        // Assert
        final state = container.read(authStateProvider);
        expect(state.hasError, isFalse);
        expect(state.valueOrNull, isNotNull);
      });

      test('devrait gerer les erreurs de connexion Google', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithGoogle())
            .thenThrow(AuthException('Une erreur est survenue lors de la connexion Google.'));

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithGoogle();

        // Assert
        final state = container.read(authStateProvider);
        expect(state.hasError, isTrue);
        expect(state.error.toString(), contains('Google'));
      });

      test('devrait gerer l\'annulation de l\'utilisateur', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithGoogle())
            .thenThrow(AuthException('Connexion annulee par l\'utilisateur.'));

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithGoogle();

        // Assert
        final state = container.read(authStateProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('signInWithApple()', () {
      test('devrait appeler signInWithApple sur le repository', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);
        when(() => mockAuthRepository.signInWithApple())
            .thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signInWithApple();

        // Assert
        verify(() => mockAuthRepository.signInWithApple()).called(1);
      });
    });

    group('signOut()', () {
      test('devrait deconnecter et mettre l\'utilisateur a null', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async => {});

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).signOut();

        // Assert
        verify(() => mockAuthRepository.signOut()).called(1);
        final state = await container.read(authStateProvider.future);
        expect(state, isNull);
      });
    });

    group('refresh()', () {
      test('devrait rafraichir l\'etat d\'authentification', () async {
        // Arrange
        final fakeUser = FakeUser();

        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        await container.read(authStateProvider.future);

        // Act
        await container.read(authStateProvider.notifier).refresh();

        // Assert
        verify(() => mockAuthRepository.getCurrentUser()).called(greaterThan(1));
      });
    });
  });

  group('Derived Providers', () {
    group('currentUserProvider', () {
      test('devrait retourner l\'utilisateur du authStateProvider', () async {
        // Arrange
        final fakeUser = FakeUser();
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        // Wait for authStateProvider to complete first
        await container.read(authStateProvider.future);

        // Act
        final result = await container.read(currentUserProvider.future);

        // Assert
        expect(result, isNotNull);
        expect(result!.$id, equals('fake-user-id'));
      });

      test('devrait retourner null si pas d\'utilisateur connecte', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Wait for authStateProvider to complete first
        await container.read(authStateProvider.future);

        // Act
        final result = await container.read(currentUserProvider.future);

        // Assert
        expect(result, isNull);
      });
    });

    group('isLoggedInProvider', () {
      test('devrait retourner true si utilisateur connecte', () async {
        // Arrange
        final fakeUser = FakeUser();
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => fakeUser);

        // Attendre que le provider soit initialise
        await container.read(authStateProvider.future);

        // Act
        final result = container.read(isLoggedInProvider);

        // Assert
        expect(result, isTrue);
      });

      test('devrait retourner false si pas d\'utilisateur connecte', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        await container.read(authStateProvider.future);

        // Act
        final result = container.read(isLoggedInProvider);

        // Assert
        expect(result, isFalse);
      });
    });

    group('authLoadingProvider', () {
      test('devrait retourner true pendant le chargement', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return null;
        });

        // Act - Ne pas attendre pour capturer l'etat loading
        container.read(authStateProvider);

        // Assert
        final isLoading = container.read(authLoadingProvider);
        expect(isLoading, isTrue);
      });

      test('devrait retourner false apres le chargement', () async {
        // Arrange
        when(() => mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => null);

        // Attendre la fin du chargement
        await container.read(authStateProvider.future);

        // Act
        final isLoading = container.read(authLoadingProvider);

        // Assert
        expect(isLoading, isFalse);
      });
    });

    group('authErrorProvider', () {
      test('devrait etre null par defaut', () {
        // Act
        final error = container.read(authErrorProvider);

        // Assert
        expect(error, isNull);
      });

      test('devrait pouvoir etre mis a jour', () {
        // Act
        container.read(authErrorProvider.notifier).state = 'Test error';

        // Assert
        expect(container.read(authErrorProvider), equals('Test error'));
      });

      test('devrait pouvoir etre reinitialise a null', () {
        // Arrange
        container.read(authErrorProvider.notifier).state = 'Test error';

        // Act
        container.read(authErrorProvider.notifier).state = null;

        // Assert
        expect(container.read(authErrorProvider), isNull);
      });
    });
  });
}
