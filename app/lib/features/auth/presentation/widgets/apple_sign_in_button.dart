import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Widget bouton "Sign in with Apple" conforme aux guidelines Apple
///
/// Ce widget:
/// - Utilise le composant officiel SignInWithAppleButton
/// - S'affiche uniquement sur iOS (via defaultTargetPlatform)
/// - Respecte les guidelines Apple (style noir par defaut)
/// - Gere l'etat de chargement
///
/// Usage:
/// ```dart
/// AppleSignInButton(
///   onPressed: () async {
///     await authProvider.signInWithApple();
///   },
///   isLoading: isAppleSignInLoading,
/// )
/// ```
class AppleSignInButton extends StatelessWidget {
  /// Callback execute lors du tap sur le bouton
  final VoidCallback? onPressed;

  /// Indique si une operation est en cours
  final bool isLoading;

  /// Style du bouton (noir ou blanc)
  /// Par defaut: noir (conforme aux guidelines Apple)
  final SignInWithAppleButtonStyle style;

  /// Texte personnalise du bouton
  /// Par defaut: "Continuer avec Apple"
  final String? text;

  const AppleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.style = SignInWithAppleButtonStyle.black,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher sur les plateformes non-iOS (sauf debug web)
    if (!_shouldShow()) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return _buildLoadingState(context);
    }

    return SignInWithAppleButton(
      onPressed: onPressed ?? () {},
      style: style,
      text: text ?? 'Continuer avec Apple',
    );
  }

  /// Verifie si le bouton doit etre affiche
  ///
  /// Affiche sur:
  /// - iOS (production)
  /// - Web en debug mode (pour tests)
  bool _shouldShow() {
    // En mode debug web, toujours afficher pour les tests
    if (kDebugMode && kIsWeb) {
      return true;
    }

    // En production, seulement sur iOS
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }

    return false;
  }

  /// Construit l'etat de chargement du bouton
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 44, // Hauteur standard du bouton Apple
      decoration: BoxDecoration(
        color: style == SignInWithAppleButtonStyle.black
            ? Colors.black
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: style == SignInWithAppleButtonStyle.white
            ? Border.all(color: Colors.black)
            : null,
      ),
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: style == SignInWithAppleButtonStyle.black
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

/// Widget conditionnel qui n'affiche son enfant que sur iOS
///
/// Utile pour envelopper des sections entieres liees a Apple Sign-In.
class IOSOnly extends StatelessWidget {
  final Widget child;

  /// Widget a afficher si pas sur iOS (optionnel)
  final Widget? fallback;

  const IOSOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // En mode debug web, afficher pour tests
    if (kDebugMode && kIsWeb) {
      return child;
    }

    // Verifier si iOS
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
