import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:fug_app/features/auth/presentation/widgets/apple_sign_in_button.dart';

/// Tests widget pour AppleSignInButton
///
/// Note: Ces tests s'executent en environnement de test Flutter
/// ou Platform.isIOS retourne false et kIsWeb est false.
/// Le widget retourne donc SizedBox.shrink() par defaut.
///
/// Pour tester l'affichage reel du bouton, il faut:
/// 1. Executer sur un simulateur iOS
/// 2. Ou tester en mode web debug
void main() {
  group('AppleSignInButton', () {
    testWidgets('devrait retourner SizedBox.shrink sur plateforme non-iOS',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(
              onPressed: null,
            ),
          ),
        ),
      );

      // Assert - Le widget devrait etre un SizedBox.shrink
      // car nous ne sommes pas sur iOS dans les tests
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(SignInWithAppleButton), findsNothing);
    });

    testWidgets('devrait accepter des parametres personnalises',
        (WidgetTester tester) async {
      // Arrange
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(
              onPressed: () => wasPressed = true,
              isLoading: false,
              style: SignInWithAppleButtonStyle.white,
              text: 'Custom Text',
            ),
          ),
        ),
      );

      // Assert - Le widget est construit sans erreur
      expect(find.byType(AppleSignInButton), findsOneWidget);
    });

    testWidgets('devrait avoir des valeurs par defaut correctes',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(),
          ),
        ),
      );

      // Assert
      final button = tester.widget<AppleSignInButton>(
        find.byType(AppleSignInButton),
      );

      expect(button.isLoading, isFalse);
      expect(button.style, equals(SignInWithAppleButtonStyle.black));
      expect(button.onPressed, isNull);
    });
  });

  group('AppleSignInButton - Loading State', () {
    testWidgets('devrait construire un etat de chargement valide',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleSignInButton(
              isLoading: true,
            ),
          ),
        ),
      );

      // Assert - Sur plateforme non-iOS, meme en loading,
      // le widget retourne SizedBox.shrink
      expect(find.byType(AppleSignInButton), findsOneWidget);
    });
  });

  group('IOSOnly Widget', () {
    testWidgets('devrait retourner fallback sur plateforme non-iOS',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IOSOnly(
              fallback: Text('Fallback'),
              child: Text('iOS Content'),
            ),
          ),
        ),
      );

      // Assert - Sur plateforme non-iOS, le fallback devrait s'afficher
      // ou SizedBox.shrink si pas de fallback
      expect(find.byType(IOSOnly), findsOneWidget);
    });

    testWidgets('devrait retourner SizedBox.shrink sans fallback sur non-iOS',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IOSOnly(
              child: Text('iOS Content'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('iOS Content'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('AppleSignInButton - Style Variations', () {
    test('devrait supporter le style noir', () {
      // Arrange & Act
      const button = AppleSignInButton(
        style: SignInWithAppleButtonStyle.black,
      );

      // Assert
      expect(button.style, equals(SignInWithAppleButtonStyle.black));
    });

    test('devrait supporter le style blanc', () {
      // Arrange & Act
      const button = AppleSignInButton(
        style: SignInWithAppleButtonStyle.white,
      );

      // Assert
      expect(button.style, equals(SignInWithAppleButtonStyle.white));
    });

    test('devrait supporter le style blanc avec bordure', () {
      // Arrange & Act
      const button = AppleSignInButton(
        style: SignInWithAppleButtonStyle.whiteOutlined,
      );

      // Assert
      expect(button.style, equals(SignInWithAppleButtonStyle.whiteOutlined));
    });
  });
}
