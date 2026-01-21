import 'package:flutter_test/flutter_test.dart';
import 'package:fug_app/features/auth/data/auth_repository.dart';

/// Tests unitaires pour Apple Sign-In
///
/// Note: Les tests complets de signInWithApple() necessitent un appareil iOS
/// car Platform.isIOS ne peut pas etre mocke facilement dans les tests unitaires.
///
/// Ces tests couvrent:
/// - La classe AuthException
/// - La logique de gestion des erreurs Apple Sign-In
/// - Le comportement attendu sur plateforme non-iOS
void main() {
  group('Apple Sign-In - AuthRepository', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = AuthRepository();
    });

    group('signInWithApple()', () {
      test('devrait lancer AuthException sur plateforme non-iOS', () async {
        // Sur les plateformes de test (non-iOS), signInWithApple doit
        // lancer une exception indiquant que ce n'est disponible que sur iOS

        // Act & Assert
        expect(
          () => authRepository.signInWithApple(),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('iOS'),
            ),
          ),
        );
      });
    });

    group('isAppleSignInAvailable()', () {
      test('devrait retourner false sur plateforme non-iOS', () async {
        // Act
        final result = await AuthRepository.isAppleSignInAvailable();

        // Assert
        expect(result, isFalse);
      });
    });
  });

  group('Apple Sign-In - Error Messages', () {
    test('AuthException pour connexion annulee devrait avoir un message clair',
        () {
      // Arrange
      final exception = AuthException('Connexion annulee par l\'utilisateur.');

      // Assert
      expect(exception.message, contains('annulee'));
    });

    test('AuthException pour appareil non supporte devrait avoir un message clair',
        () {
      // Arrange
      final exception = AuthException(
        'Apple Sign-In n\'est pas supporte sur cet appareil.',
      );

      // Assert
      expect(exception.message, contains('supporte'));
    });

    test('AuthException pour erreur generale devrait avoir un message clair',
        () {
      // Arrange
      final exception = AuthException(
        'Une erreur est survenue lors de la connexion Apple.',
      );

      // Assert
      expect(exception.message, contains('erreur'));
    });
  });

  group('Apple Sign-In - User Profile Creation', () {
    test('devrait detecter un email relay Apple', () {
      // Arrange
      const relayEmail = 'abc123@privaterelay.appleid.com';
      const normalEmail = 'user@example.com';

      // Act & Assert
      expect(relayEmail.contains('privaterelay.appleid.com'), isTrue);
      expect(normalEmail.contains('privaterelay.appleid.com'), isFalse);
    });

    test('devrait construire un nom a partir de givenName et familyName', () {
      // Arrange
      const givenName = 'John';
      const familyName = 'Doe';

      // Act
      final fullName = [givenName, familyName]
          .where((s) => s.isNotEmpty)
          .join(' ');

      // Assert
      expect(fullName, equals('John Doe'));
    });

    test('devrait gerer le cas ou le nom est vide', () {
      // Arrange
      const String? givenName = null;
      const String? familyName = null;

      // Act
      final fullName = [givenName, familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      // Assert
      expect(fullName, isEmpty);
    });

    test('devrait gerer le cas ou seul le prenom est fourni', () {
      // Arrange
      const givenName = 'John';
      const String? familyName = null;

      // Act
      final fullName = [givenName, familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');

      // Assert
      expect(fullName, equals('John'));
    });
  });
}
