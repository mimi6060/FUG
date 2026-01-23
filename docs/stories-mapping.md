# Mapping des User Stories FUG

> Analyse croisée du backlog produit et du code Flutter existant
> Date: Janvier 2026

---

## Légende

| Statut | Description |
|--------|-------------|
| ✅ DONE | Implémenté et fonctionnel |
| 🔶 PARTIAL | Partiellement implémenté |
| ❌ TODO | À faire |
| 🧪 QA | Nécessite validation/tests |

---

## Epic 1 - Gestion des comptes (25 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-001 | Inscription par email | 5 | ✅ DONE | `auth_repository.dart` signUp() | 🧪 À tester |
| US-002 | Inscription OAuth | 8 | 🔶 PARTIAL | UI présente, backend TODO | 🧪 Bloqué |
| US-003 | Connexion utilisateur | 3 | ✅ DONE | `auth_repository.dart` signIn() | 🧪 À tester |
| US-004 | Réinitialisation mot de passe | 3 | ✅ DONE | `auth_repository.dart` recoverPassword() | 🧪 À tester |
| US-005 | Déconnexion | 1 | ✅ DONE | `auth_repository.dart` signOut() | 🧪 À tester |
| US-006 | Suppression de compte | 5 | ❌ TODO | Non implémenté | ❌ |

**Progression Epic 1**: 20/25 points (80%) - QA: 0%

---

## Epic 2 - Gestion des profils (18 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-007 | Création profil initial | 5 | ✅ DONE | `profile_repository.dart` | 🧪 À tester |
| US-008 | Modification du profil | 3 | ✅ DONE | `edit_profile_screen.dart` | 🧪 À tester |
| US-009 | Gestion photo de profil | 5 | ✅ DONE | `profile_repository.dart` uploadAvatar() | 🧪 À tester |
| US-010 | Préférences boissons | 3 | 🔶 PARTIAL | interests[] existe, UI basique | 🧪 À tester |
| US-011 | Profil public | 2 | ✅ DONE | `profile_screen.dart` vue autre user | 🧪 À tester |

**Progression Epic 2**: 18/18 points (100%) - QA: 0%

---

## Epic 3 - Réseau social (17 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-012 | Recherche utilisateurs | 5 | ✅ DONE | `social_repository.dart` searchUsers() | 🧪 À tester |
| US-013 | Suivre un utilisateur | 3 | ✅ DONE | `social_repository.dart` follow() | 🧪 À tester |
| US-014 | Ne plus suivre | 1 | ✅ DONE | `social_repository.dart` unfollow() | 🧪 À tester |
| US-015 | Liste followers/abonnements | 3 | ✅ DONE | `followers_list_screen.dart` | 🧪 À tester |
| US-016 | Bloquer utilisateur | 5 | ✅ DONE | `social_repository.dart` blockUser() | 🧪 À tester |

**Progression Epic 3**: 17/17 points (100%) - QA: 0%

---

## Epic 4 - Gestion des FUG (41 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-017 | Créer un FUG | 8 | ✅ DONE | `create_event_screen.dart` (Stepper 4 étapes) | 🧪 À tester |
| US-018 | Carte des FUG | 8 | ✅ DONE | `events_map_screen.dart` flutter_map | 🧪 À tester |
| US-019 | Détails d'un FUG | 3 | ✅ DONE | `event_detail_screen.dart` | 🧪 À tester |
| US-020 | Rejoindre FUG public | 3 | 🔶 PARTIAL | UI présente, backend TODO | 🧪 Bloqué |
| US-021 | Demander rejoindre FUG privé | 3 | ❌ TODO | Non implémenté | ❌ |
| US-022 | Gérer demandes participation | 3 | ❌ TODO | Non implémenté | ❌ |
| US-023 | Inviter utilisateurs | 5 | ❌ TODO | Non implémenté | ❌ |
| US-024 | Annuler participation | 2 | ❌ TODO | Non implémenté | ❌ |
| US-025 | Annuler FUG | 3 | 🔶 PARTIAL | UI présente, backend TODO | 🧪 Bloqué |
| US-026 | Historique FUG | 3 | 🔶 PARTIAL | `events_list_screen.dart` (liste seule) | 🧪 À tester |

**Progression Epic 4**: 22/41 points (54%) - QA: 0%

---

## Epic 5 - Notifications (19 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-027 | Notifications push | 8 | ❌ TODO | Modèle OK, FCM/APNs non configuré | ❌ |
| US-028 | Centre notifications in-app | 5 | ✅ DONE | `notifications_screen.dart` | 🧪 À tester |
| US-029 | Paramètres notifications | 3 | ❌ TODO | Non implémenté | ❌ |
| US-030 | Rappel avant FUG | 3 | ❌ TODO | Non implémenté | ❌ |

**Progression Epic 5**: 5/19 points (26%) - QA: 0%

---

## Epic 6 - Gamification (23 points)

| US | Titre | Points | Statut | Implémentation | QA |
|----|-------|--------|--------|----------------|-----|
| US-031 | Système de badges | 5 | 🔶 PARTIAL | Champs dans UserModel, pas de logique | 🧪 Bloqué |
| US-032 | Statistiques personnelles | 5 | 🔶 PARTIAL | Affichage basique dans ProfileScreen | 🧪 À tester |
| US-033 | Niveaux et progression | 8 | 🔶 PARTIAL | level, points dans modèle, pas de calcul | 🧪 Bloqué |
| US-034 | Classement (Post-MVP) | 5 | ❌ TODO | Non implémenté | ❌ |

**Progression Epic 6**: 5/23 points (22%) - QA: 0%

---

## Résumé Global

| Epic | Points Total | Points Faits | % Avancement | Stories QA |
|------|--------------|--------------|--------------|------------|
| E1 - Comptes | 25 | 20 | 80% | 5 à tester |
| E2 - Profils | 18 | 18 | 100% | 5 à tester |
| E3 - Social | 17 | 17 | 100% | 5 à tester |
| E4 - FUG | 41 | 22 | 54% | 4 à tester |
| E5 - Notifications | 19 | 5 | 26% | 1 à tester |
| E6 - Gamification | 23 | 5 | 22% | 1 à tester |
| **TOTAL** | **143** | **87** | **61%** | **21 à tester** |

---

## Stories QA Prioritaires

Ces stories nécessitent une passe QA car BMAD n'était pas configuré:

### QA-001: Validation Auth Flow
- Tests unitaires AuthRepository
- Tests widgets LoginScreen, RegisterScreen
- Tests intégration sign up/sign in

### QA-002: Validation Profile
- Tests unitaires ProfileRepository
- Tests widgets ProfileScreen, EditProfileScreen
- Tests upload avatar

### QA-003: Validation Social
- Tests unitaires SocialRepository
- Tests follow/unfollow/block
- Tests recherche utilisateurs

### QA-004: Validation Events
- Tests unitaires EventRepository
- Tests création événement (4 étapes)
- Tests carte et géolocalisation
- Tests recherche nearby (Haversine)

### QA-005: Validation Notifications
- Tests NotificationRepository
- Tests NotificationsScreen
- Tests mark as read

### QA-006: Tests E2E
- Parcours inscription → création profil
- Parcours création FUG → participation
- Parcours follow → voir FUG followers

---

## Stories à Créer dans Plane

### Sprint Actuel (Finir MVP Core)

1. **US-006**: Suppression de compte (5 pts) - RGPD obligatoire
2. **US-020**: Rejoindre FUG public - finaliser (3 pts)
3. **US-021**: Demander rejoindre FUG privé (3 pts)
4. **US-022**: Gérer demandes participation (3 pts)
5. **US-024**: Annuler participation (2 pts)
6. **US-025**: Annuler FUG - finaliser (3 pts)

### Sprint Suivant (Notifications)

7. **US-027**: Notifications push FCM/APNs (8 pts)
8. **US-029**: Paramètres notifications (3 pts)
9. **US-030**: Rappel avant FUG (3 pts)

### Sprint Gamification

10. **US-031**: Système badges - logique (5 pts)
11. **US-033**: Niveaux progression - calcul (8 pts)

### Stories QA (Transversal)

12. **QA-001** à **QA-006** (voir ci-dessus)

---

## Notes Techniques

### Code existant de qualité
- Clean Architecture bien respectée
- Riverpod correctement utilisé
- Modèles complets avec sérialisation
- Repository pattern cohérent
- Géolocalisation Haversine implémentée

### Points d'attention
- OAuth non fonctionnel (Google/Apple)
- Pas de tests automatisés
- Collection `event_participants` à finaliser
- Functions Appwrite non déployées
- Pas de CI/CD actif

---

*Document généré par analyse du code Flutter et du backlog produit*
