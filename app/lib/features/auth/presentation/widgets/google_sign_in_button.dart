import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bouton de connexion Google avec le logo officiel
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            SvgPicture.asset(
              'assets/icons/google_logo.svg',
              width: 20,
              height: 20,
            ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
