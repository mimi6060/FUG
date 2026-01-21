# PRD: Systeme d'Authentification FUG

> Product Requirements Document - Feature Authentification

## Informations

| Champ | Valeur |
|-------|--------|
| **ID Feature** | AUTH-001 |
| **Nom** | Systeme d'Authentification |
| **Statut** | Implemente |
| **Version** | 1.0 |
| **Date** | Janvier 2026 |
| **Equipe** | The Develobeers |

---

## 1. Resume Executif

Le systeme d'authentification FUG permet aux utilisateurs de creer un compte, de se connecter et de gerer leur session de maniere securisee. Il supporte l'authentification par email/mot de passe ainsi que les connexions OAuth2 (Google, Facebook, Apple).

### Objectifs

- Permettre l'inscription et la connexion securisee des utilisateurs
- Supporter plusieurs methodes d'authentification (email, OAuth)
- Gerer les sessions utilisateur de maniere transparente
- Assurer la conformite avec les reglementations (RGPD, age minimum)

---

## 2. Contexte et Motivation

### Probleme

FUG necessite un systeme d'authentification robuste pour:
- Identifier les utilisateurs de maniere unique
- Securiser les donnees personnelles
- Permettre la verification de l'age (exigence legale pour une application liee a l'alcool)
- Activer les fonctionnalites sociales (follow, participation aux evenements)

### Solution

Integration d'Appwrite Auth comme service d'authentification backend, avec une couche Flutter gerant:
- L'UI d'inscription/connexion
- La gestion des sessions
- La creation automatique du profil utilisateur

---

## 3. User Stories

### US-AUTH-01: Inscription par email
**En tant que** nouvel utilisateur
**Je veux** creer un compte avec mon email
**Afin de** pouvoir utiliser l'application FUG

**Criteres d'acceptation:**
- [ ] Formulaire avec email, mot de passe, confirmation, nom
- [ ] Validation du format email
- [ ] Mot de passe minimum 8 caracteres
- [ ] Message d'erreur si email deja utilise
- [ ] Email de verification envoye apres inscription

### US-AUTH-02: Connexion par email
**En tant qu'** utilisateur enregistre
**Je veux** me connecter avec mon email et mot de passe
**Afin d'** acceder a mon compte

**Criteres d'acceptation:**
- [ ] Formulaire avec email et mot de passe
- [ ] Message d'erreur si identifiants incorrects
- [ ] Redirection vers l'ecran principal apres connexion
- [ ] Session persistante (ne pas redemander le mot de passe)

### US-AUTH-03: Connexion OAuth
**En tant qu'** utilisateur
**Je veux** me connecter avec mon compte Google/Apple/Facebook
**Afin de** simplifier le processus de connexion

**Criteres d'acceptation:**
- [ ] Boutons OAuth sur l'ecran de connexion
- [ ] Redirection vers le provider OAuth
- [ ] Creation automatique du profil si premiere connexion
- [ ] Liaison avec compte existant si meme email

### US-AUTH-04: Deconnexion
**En tant qu'** utilisateur connecte
**Je veux** pouvoir me deconnecter
**Afin de** securiser mon compte

**Criteres d'acceptation:**
- [ ] Bouton de deconnexion accessible dans le profil
- [ ] Suppression de la session locale
- [ ] Redirection vers l'ecran de connexion

### US-AUTH-05: Recuperation mot de passe
**En tant qu'** utilisateur ayant oublie son mot de passe
**Je veux** pouvoir le reinitialiser
**Afin de** recuperer l'acces a mon compte

**Criteres d'acceptation:**
- [ ] Lien "Mot de passe oublie" sur l'ecran de connexion
- [ ] Formulaire de saisie d'email
- [ ] Email avec lien de reinitialisation
- [ ] Formulaire de nouveau mot de passe

---

## 4. Specifications Techniques

### 4.1 Architecture

```
lib/features/auth/
├── data/
│   └── auth_repository.dart      # Implementation repository
├── domain/
│   └── user_model.dart           # Modele utilisateur
└── presentation/
    ├── login_screen.dart         # Ecran de connexion
    └── register_screen.dart      # Ecran d'inscription
```

### 4.2 AuthRepository

Le repository gere toutes les operations d'authentification via Appwrite:

```dart
class AuthRepository {
  // Gestion de session
  Future<bool> isLoggedIn();
  Future<models.User?> getCurrentUser();
  Future<models.Session?> getCurrentSession();

  // Inscription
  Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  });

  // Connexion
  Future<models.Session> signInWithEmail({...});
  Future<void> signInWithOAuth({...});
  Future<models.Session> signInAnonymously();

  // Deconnexion
  Future<void> signOut();
  Future<void> signOutAll();

  // Mot de passe
  Future<void> sendPasswordRecovery({...});
  Future<void> confirmPasswordRecovery({...});
  Future<void> changePassword({...});

  // Verification email
  Future<void> sendEmailVerification();
  Future<void> confirmEmailVerification({...});

  // Profil
  Future<UserModel?> getUserProfile(String userId);
  Future<void> updateUserProfile({...});
}
```

### 4.3 UserModel

```dart
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String? bio;
  final int points;           // Murgilarity score
  final int level;
  final int followersCount;
  final int followingCount;
  final double? locationLat;
  final double? locationLng;
  final double notificationRadius;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 4.4 Integration Appwrite

| Service Appwrite | Usage |
|------------------|-------|
| Account | Gestion comptes et sessions |
| Database | Collection `users` pour profils |
| OAuth2 | Google, Facebook, Apple |

### 4.5 Securite

- Mots de passe haches cote serveur (Appwrite)
- Sessions JWT avec expiration configurable
- Permissions Appwrite strictes sur collection `users`
- Verification email obligatoire pour actions sensibles

---

## 5. Ecrans UI

### 5.1 Login Screen

**Elements:**
- Logo FUG
- Champ email
- Champ mot de passe
- Bouton "Se connecter"
- Lien "Mot de passe oublie"
- Separateur "ou"
- Boutons OAuth (Google, Apple, Facebook)
- Lien "Creer un compte"

### 5.2 Register Screen

**Elements:**
- Logo FUG
- Champ nom complet
- Champ email
- Champ mot de passe
- Champ confirmation mot de passe
- Checkbox acceptation CGU
- Bouton "S'inscrire"
- Lien "Deja un compte ? Se connecter"

---

## 6. Regles Metier

### R-AUTH-01: Age Minimum
L'utilisateur doit confirmer avoir l'age legal pour consommer de l'alcool (18 ans en France).

### R-AUTH-02: Unicite Email
Un seul compte par adresse email.

### R-AUTH-03: Format Mot de Passe
Minimum 8 caracteres.

### R-AUTH-04: Session Persistante
Session mobile: 365 jours
Session web: 7 jours

### R-AUTH-05: Creation Profil Automatique
A l'inscription, un document est cree dans la collection `users` avec les valeurs par defaut:
- `points`: 0
- `level`: 1
- `notificationRadius`: 10.0 km

---

## 7. Metriques de Succes

| Metrique | Cible |
|----------|-------|
| Taux de completion inscription | > 80% |
| Temps moyen d'inscription | < 60s |
| Taux d'erreur connexion | < 2% |
| Adoption OAuth | > 40% |

---

## 8. Dependances

- **Appwrite SDK Flutter**: `appwrite: ^12.0.0`
- **Riverpod**: Gestion d'etat
- **GoRouter**: Navigation post-authentification

---

## 9. Risques et Mitigations

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Provider OAuth indisponible | Faible | Moyen | Fallback sur email |
| Spam inscriptions | Moyen | Moyen | Rate limiting Appwrite |
| Vol de session | Faible | Eleve | HTTPS, sessions courtes web |

---

## 10. Historique

| Date | Version | Changement |
|------|---------|------------|
| Janvier 2026 | 1.0 | Version initiale implementee |

---

*Document genere pour le projet FUG - The Develobeers*
