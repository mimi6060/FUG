import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fug_app/features/auth/presentation/login_screen.dart';
import 'package:fug_app/features/auth/data/auth_repository.dart';

import 'helpers/test_helpers.dart';

// Mock pour AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    setUpTestHelpers();
  });

  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
    });

    /// Helper pour construire le widget avec les providers necessaires
    Widget buildLoginScreen({AuthRepository? authRepository}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            authRepository ?? mockAuthRepository,
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('devrait afficher le logo et le titre FUG', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.text('FUG'), findsOneWidget);
        expect(find.text('Find Urban Gatherings'), findsOneWidget);
        expect(find.byIcon(Icons.event), findsOneWidget);
      });

      testWidgets('devrait afficher les champs email et mot de passe', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      });

      testWidgets('devrait afficher le bouton de connexion', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
      });

      testWidgets('devrait afficher les boutons OAuth', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.text('Continuer avec Google'), findsOneWidget);
        expect(find.text('Continuer avec Apple'), findsOneWidget);
      });

      testWidgets('devrait afficher le lien mot de passe oublie', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.text('Mot de passe oublié?'), findsOneWidget);
      });

      testWidgets('devrait afficher le lien pour s\'inscrire', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        expect(find.text('Pas encore de compte?'), findsOneWidget);
        expect(find.text("S'inscrire"), findsOneWidget);
      });
    });

    group('Toggle Login/Signup', () {
      testWidgets('devrait afficher le champ nom en mode inscription', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Verifier qu'on est en mode connexion (pas de champ nom)
        expect(find.widgetWithText(TextFormField, 'Nom complet'), findsNothing);

        // Act - Cliquer sur "S'inscrire"
        await tester.tap(find.text("S'inscrire"));
        await tester.pumpAndSettle();

        // Assert
        expect(find.widgetWithText(TextFormField, 'Nom complet'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Créer un compte'), findsOneWidget);
      });

      testWidgets('devrait revenir en mode connexion', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Passer en mode inscription
        await tester.tap(find.text("S'inscrire"));
        await tester.pumpAndSettle();

        // Verifier qu'on est en mode inscription
        expect(find.text('Déjà un compte?'), findsOneWidget);

        // Act - Cliquer sur "Se connecter"
        await tester.tap(find.text('Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.widgetWithText(TextFormField, 'Nom complet'), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('devrait afficher une erreur pour email vide', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Act - Soumettre sans remplir
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Veuillez entrer votre email.'), findsOneWidget);
      });

      testWidgets('devrait afficher une erreur pour email invalide', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Act - Entrer un email invalide
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalid-email',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Adresse email invalide.'), findsOneWidget);
      });

      testWidgets('devrait afficher une erreur pour mot de passe vide', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Act - Entrer un email valide mais pas de mot de passe
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Veuillez entrer votre mot de passe.'), findsOneWidget);
      });

      testWidgets('devrait afficher une erreur pour mot de passe court en inscription', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Passer en mode inscription
        await tester.tap(find.text("S'inscrire"));
        await tester.pumpAndSettle();

        // Act - Remplir avec un mot de passe trop court
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nom complet'),
          'Test User',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'short',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Créer un compte'));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Le mot de passe doit contenir au moins 8 caractères.'),
          findsOneWidget,
        );
      });

      testWidgets('devrait afficher une erreur pour nom vide en inscription', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Passer en mode inscription
        await tester.tap(find.text("S'inscrire"));
        await tester.pumpAndSettle();

        // Act - Remplir sans le nom
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Créer un compte'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Veuillez entrer votre nom.'), findsOneWidget);
      });

      testWidgets('devrait valider un email correct', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Setup mock pour eviter l'appel reel
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => FakeSession());

        // Act - Entrer des donnees valides
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pump();

        // Assert - Pas d'erreur de validation
        expect(find.text('Veuillez entrer votre email.'), findsNothing);
        expect(find.text('Adresse email invalide.'), findsNothing);
        expect(find.text('Veuillez entrer votre mot de passe.'), findsNothing);
      });
    });

    group('Password Visibility Toggle', () {
      testWidgets('devrait masquer le mot de passe par defaut', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Assert
        final passwordField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Mot de passe'),
        );
        expect(passwordField.obscureText, isTrue);
      });

      testWidgets('devrait afficher/masquer le mot de passe au clic', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Act - Cliquer sur l'icone de visibilite
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pumpAndSettle();

        // Assert - Le mot de passe devrait etre visible
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Act - Cliquer a nouveau
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pumpAndSettle();

        // Assert - Le mot de passe devrait etre masque
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('devrait afficher un spinner pendant le chargement', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Setup mock pour simuler un delai
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 2));
          return FakeSession();
        });

        // Act - Entrer des donnees valides et soumettre
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pump();

        // Assert - Le spinner devrait etre visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('devrait desactiver le bouton pendant le chargement', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Setup mock
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 2));
          return FakeSession();
        });

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pump();

        // Assert - Le bouton devrait etre desactive
        final button = tester.widget<FilledButton>(
          find.byType(FilledButton).first,
        );
        expect(button.onPressed, isNull);
      });
    });

    group('Error Display', () {
      testWidgets('devrait afficher une erreur d\'authentification', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Setup mock pour retourner une erreur
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          AuthException('Email ou mot de passe incorrect.'),
        );

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'wrong@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'wrongpassword',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('devrait effacer l\'erreur lors du changement de mode', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Setup mock
        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          AuthException('Test error'),
        );

        // Provoquer une erreur
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Verifier que l'erreur est affichee
        expect(find.text('Test error'), findsOneWidget);

        // Act - Changer de mode
        await tester.tap(find.text("S'inscrire"));
        await tester.pumpAndSettle();

        // Assert - L'erreur devrait etre effacee
        expect(find.text('Test error'), findsNothing);
      });
    });

    group('Forgot Password', () {
      testWidgets('devrait afficher un message si email vide', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Act - Cliquer sur "Mot de passe oublie" sans email
        await tester.tap(find.text('Mot de passe oublié?'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Veuillez entrer votre adresse email.'), findsOneWidget);
      });

      testWidgets('devrait appeler sendPasswordRecovery avec un email', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        when(() => mockAuthRepository.sendPasswordRecovery(
              email: any(named: 'email'),
            )).thenAnswer((_) async {});

        // Act - Entrer un email et cliquer sur "Mot de passe oublie"
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.tap(find.text('Mot de passe oublié?'));
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockAuthRepository.sendPasswordRecovery(
              email: 'test@example.com',
            )).called(1);
        expect(find.text('Email de récupération envoyé!'), findsOneWidget);
      });
    });

    group('Successful Authentication', () {
      testWidgets('devrait afficher un message de succes apres connexion', (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        when(() => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => FakeSession());

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Mot de passe'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Connexion réussie!'), findsOneWidget);
      });
    });
  });

  group('Email Validation Regex', () {
    // Tests unitaires pour la validation d'email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    test('devrait valider des emails corrects', () {
      expect(emailRegex.hasMatch('test@example.com'), isTrue);
      expect(emailRegex.hasMatch('user.name@domain.org'), isTrue);
      expect(emailRegex.hasMatch('user-name@sub.domain.fr'), isTrue);
      expect(emailRegex.hasMatch('test123@example.co.uk'), isTrue);
    });

    test('devrait rejeter des emails invalides', () {
      expect(emailRegex.hasMatch('invalid'), isFalse);
      expect(emailRegex.hasMatch('invalid@'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('test@.com'), isFalse);
      expect(emailRegex.hasMatch('test@domain'), isFalse);
    });
  });
}
