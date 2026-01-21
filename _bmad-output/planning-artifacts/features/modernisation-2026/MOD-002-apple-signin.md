# MOD-002: Apple Sign-In

> **Priorite:** CRITIQUE
> **Phase:** 1 - Conformite & Obligations Legales
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Implementer Apple Sign-In comme methode d'authentification. Obligatoire depuis les guidelines App Store 2020 pour toute app proposant un login social.

## Probleme

L'application propose Google OAuth mais pas Apple Sign-In:
- **Violation des App Store Guidelines** section 4.8
- Risque de rejet lors des mises a jour
- Utilisateurs iOS sans option native

## Obligation Legale

> "Apps that use a third-party or social login service (such as Facebook Login, Google Sign-In, Sign in with Twitter, Sign In with LinkedIn, Login with Amazon, or WeChat Login) to set up or authenticate the user's primary account with the app must also offer Sign in with Apple as an equivalent option."
> — App Store Review Guidelines 4.8

---

## User Stories

### US-APPLE-01: Bouton Sign in with Apple
**En tant que** nouvel utilisateur iOS
**Je veux** m'inscrire avec mon Apple ID
**Afin de** creer un compte rapidement et securisement

**Criteres d'acceptation:**
- [ ] Bouton "Sign in with Apple" sur ecran login/register
- [ ] Design conforme aux guidelines Apple (noir ou blanc)
- [ ] Flux OAuth2 standard Apple
- [ ] Recuperation email (ou email relay Apple)
- [ ] Recuperation nom (optionnel, utilisateur peut masquer)
- [ ] Creation compte FUG lie a l'Apple ID

**Points:** 5

### US-APPLE-02: Connexion avec Apple ID existant
**En tant que** utilisateur avec compte Apple-linked
**Je veux** me reconnecter avec mon Apple ID
**Afin de** retrouver mon compte FUG

**Criteres d'acceptation:**
- [ ] Detection du compte existant via Apple ID
- [ ] Connexion directe sans re-creation
- [ ] Gestion du cas "email relay" Apple

**Points:** 3

### US-APPLE-03: Liaison compte existant
**En tant que** utilisateur avec compte email
**Je veux** lier mon Apple ID a mon compte existant
**Afin de** beneficier de la connexion rapide

**Criteres d'acceptation:**
- [ ] Option "Lier Apple ID" dans parametres
- [ ] Verification de l'email Apple vs email compte
- [ ] Gestion conflits (Apple ID deja lie a autre compte)

**Points:** 3

---

## Implementation Technique

### Configuration Appwrite

```
Auth Provider: Apple
- Services ID: com.develobeers.fug
- Team ID: [APPLE_TEAM_ID]
- Key ID: [APPLE_KEY_ID]
- Private Key: [Contenu .p8]
```

### Configuration Apple Developer

1. **Identifiers** > App IDs > Ajouter "Sign in with Apple"
2. **Keys** > Creer cle pour Sign in with Apple
3. **Services IDs** > Configurer redirect URI Appwrite

### Flutter Implementation

```dart
// pubspec.yaml
dependencies:
  sign_in_with_apple: ^5.0.0

// auth_repository.dart
Future<User> signInWithApple() async {
  try {
    // 1. Obtenir credentials Apple
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // 2. Creer session Appwrite avec le token
    final session = await account.createOAuth2Session(
      provider: 'apple',
      success: 'https://fug.app/auth/callback',
      failure: 'https://fug.app/auth/error',
    );

    // 3. Recuperer/creer le profil utilisateur
    return await _getOrCreateUserProfile(session);

  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw AuthException('Connexion annulee');
    }
    throw AuthException('Erreur Apple Sign-In: ${e.message}');
  }
}
```

### UI Component

```dart
// widgets/apple_sign_in_button.dart
class AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SignInWithAppleButton(
      onPressed: onPressed,
      style: SignInWithAppleButtonStyle.black,
      text: 'Continuer avec Apple',
    );
  }
}
```

---

## Gestion des Cas Particuliers

### Email Relay Apple

Apple permet aux utilisateurs de masquer leur email. L'app recoit un email relay type `xyz123@privaterelay.appleid.com`.

**Solution:**
- Stocker l'email relay comme email principal
- Permettre a l'utilisateur d'ajouter un "vrai" email plus tard
- Ne pas afficher l'email relay dans le profil public

### Nom Masque

L'utilisateur peut choisir de ne pas partager son nom.

**Solution:**
- Rediriger vers l'ecran de creation de profil
- Forcer la saisie d'un pseudo (username)

---

## Definition of Done

- [ ] Bouton Apple Sign-In visible sur iOS
- [ ] Flux complet inscription fonctionne
- [ ] Flux complet connexion fonctionne
- [ ] Liaison compte existant fonctionne
- [ ] Tests sur device physique iOS
- [ ] Soumission App Store acceptee

---

## Timeline

| Etape | Duree | Dependances |
|-------|-------|-------------|
| Config Apple Developer | 1j | Compte Apple Developer |
| Config Appwrite | 0.5j | Apple credentials |
| Implementation Flutter | 2j | - |
| Tests | 1j | Device iOS physique |
| **TOTAL** | **~5 jours** | |

---

*Feature BMAD - Epic E0 Modernisation 2026*
