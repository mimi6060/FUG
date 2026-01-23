# PRD: Systeme de Gamification (Murgilarity)

> Product Requirements Document - Feature Gamification

## Informations

| Champ | Valeur |
|-------|--------|
| **ID Feature** | GAM-001 |
| **Nom** | Systeme de Gamification Murgilarity |
| **Statut** | Partiellement implemente |
| **Version** | 1.0 |
| **Date** | Janvier 2026 |
| **Equipe** | The Develobeers |

---

## 1. Resume Executif

Le systeme de gamification "Murgilarity" (mot-valise de "murge" et "hilarite/popularite") recompense les utilisateurs pour leur activite sur FUG. Il comprend un systeme de points, de niveaux et de badges qui encourage l'engagement et la participation.

### Objectifs

- Encourager la creation d'evenements
- Motiver la participation aux FUG
- Favoriser les interactions sociales (follow)
- Creer un sentiment de progression et d'accomplissement

---

## 2. Contexte et Motivation

### Probleme

Sans mecanisme de recompense:
- Les utilisateurs manquent de motivation a long terme
- Pas de differenciation entre utilisateurs actifs et passifs
- Faible retention apres les premieres utilisations

### Solution

Un systeme de gamification complet avec:
- **Points (Murgilarity)**: Score accumule pour les actions
- **Niveaux**: Progression basee sur les points
- **Badges (Achievements)**: Recompenses pour accomplissements specifiques

---

## 3. User Stories

### US-GAM-01: Voir mon score Murgilarity
**En tant qu'** utilisateur
**Je veux** voir mon score de points
**Afin de** connaitre ma progression

**Criteres d'acceptation:**
- [ ] Score affiche dans le profil
- [ ] Score mis a jour en temps reel
- [ ] Animation lors de gain de points

### US-GAM-02: Voir mon niveau
**En tant qu'** utilisateur
**Je veux** voir mon niveau actuel
**Afin de** connaitre mon statut dans la communaute

**Criteres d'acceptation:**
- [ ] Niveau affiche avec le score
- [ ] Barre de progression vers le niveau suivant
- [ ] Celebration au passage de niveau

### US-GAM-03: Consulter mes badges
**En tant qu'** utilisateur
**Je veux** voir les badges que j'ai debloques
**Afin de** celebrer mes accomplissements

**Criteres d'acceptation:**
- [ ] Liste des badges debloques avec date
- [ ] Liste des badges a debloquer (grise)
- [ ] Description et criteres de chaque badge
- [ ] Notification au deblocage

### US-GAM-04: Voir le classement
**En tant qu'** utilisateur
**Je veux** voir le classement des utilisateurs
**Afin de** me comparer aux autres

**Criteres d'acceptation:**
- [ ] Top 10 global
- [ ] Top 10 parmi mes follows
- [ ] Ma position dans le classement
- [ ] Classement par periode (semaine, mois, all-time)

### US-GAM-05: Gagner des points
**En tant qu'** utilisateur actif
**Je veux** gagner des points pour mes actions
**Afin d'** augmenter mon score

**Criteres d'acceptation:**
- [ ] Points attribues automatiquement
- [ ] Notification avec points gagnes
- [ ] Historique des gains de points

---

## 4. Systeme de Points

### 4.1 Actions et Points

| Action | Points | Description |
|--------|--------|-------------|
| Creer une FUG | +10 | Creer un evenement publie |
| Rejoindre une FUG | +5 | Participer a un evenement |
| Recevoir un follower | +2 | Quelqu'un commence a vous suivre |
| Debloquer un badge | +X | Points variables selon le badge |

**Notes:**
- Les points ne peuvent jamais etre negatifs
- Les points ne sont pas retires (meme si action annulee)
- Pas de points pour suivre quelqu'un (evite les abus)

### 4.2 Calcul du Niveau

Le niveau est calcule a partir du score total de Murgilarity:

```dart
int calculateLevel(int murgilarityScore) {
  return (sqrt(murgilarityScore / 10)).floor() + 1;
}
```

| Niveau | Points requis | Points pour prochain |
|--------|---------------|----------------------|
| 1 | 0 | 10 |
| 2 | 10 | 30 |
| 3 | 40 | 50 |
| 4 | 90 | 70 |
| 5 | 160 | 90 |
| 6 | 250 | 110 |
| ... | ... | ... |

**Progression non-lineaire**: Plus le niveau est eleve, plus il faut de points pour progresser.

---

## 5. Systeme de Badges

### 5.1 Liste des Badges

| Badge | Code | Critere | Points | Rarete |
|-------|------|---------|--------|--------|
| **Preum's** | `first_fug` | Creer sa premiere FUG | 10 | Commun |
| **Habitue** | `regular` | Creer 10 FUG | 25 | Peu commun |
| **Organisateur Pro** | `event_master` | Creer 50 FUG | 100 | Rare |
| **Papillon Social** | `social_butterfly` | Rejoindre 10 FUG | 50 | Peu commun |
| **Fete Ambulante** | `party_animal` | Rejoindre 50 FUG | 150 | Rare |
| **Populaire** | `popular` | Avoir 10 followers | 25 | Peu commun |
| **Influenceur** | `influencer` | Avoir 100 followers | 100 | Rare |
| **Star** | `star` | Avoir 1000 followers | 500 | Epique |
| **Early Adopter** | `early_adopter` | Inscrit dans les 1000 premiers | 50 | Legendaire |
| **Murge Master** | `murge_master` | Atteindre 1000 points | 200 | Epique |

### 5.2 Rarete

| Rarete | Couleur | Frequence estimee |
|--------|---------|-------------------|
| Commun | Gris | > 50% utilisateurs |
| Peu commun | Vert | 20-50% |
| Rare | Bleu | 5-20% |
| Epique | Violet | 1-5% |
| Legendaire | Or | < 1% |

### 5.3 Deblocage

Les badges sont debloques automatiquement quand les criteres sont atteints:
- Verification declenchee par Appwrite Function `gamification`
- Triggers: creation evenement, participation, nouveau follower
- Unicite garantie (un badge ne peut etre debloque qu'une fois)

---

## 6. Specifications Techniques

### 6.1 Collections Appwrite

#### achievements (Badges disponibles)

| Attribut | Type | Description |
|----------|------|-------------|
| `code` | String | Code unique du badge |
| `name` | String | Nom affiche |
| `description` | String | Description |
| `iconUrl` | String | URL de l'icone |
| `points` | Integer | Points attribues au deblocage |
| `rarity` | Enum | Rarete |
| `criteria` | JSON | Criteres de deblocage |
| `isActive` | Boolean | Badge actif |

#### user_achievements (Badges debloques)

| Attribut | Type | Description |
|----------|------|-------------|
| `userId` | String | ID utilisateur |
| `achievementId` | String | ID du badge |
| `unlockedAt` | DateTime | Date de deblocage |

#### users (champs gamification)

| Attribut | Type | Description |
|----------|------|-------------|
| `murgilarityScore` | Integer | Score total |
| `level` | Integer | Niveau calcule |

### 6.2 Appwrite Function: gamification

```javascript
// Trigger: Event sur collections events, event_participants, followers
export default async ({ req, res, log, error }) => {
  const { event, userId, action } = JSON.parse(req.body);

  // 1. Calculer les points a attribuer
  const points = calculatePoints(action);

  // 2. Mettre a jour le score utilisateur
  await updateMurgilarityScore(userId, points);

  // 3. Recalculer le niveau
  await updateLevel(userId);

  // 4. Verifier les badges a debloquer
  await checkAndUnlockAchievements(userId);

  // 5. Creer notification si nouveau badge/niveau
  await createNotificationIfNeeded(userId, result);

  return res.json({ success: true, points });
};
```

### 6.3 Architecture Flutter

```
lib/features/gamification/
├── data/
│   └── gamification_repository.dart
├── domain/
│   ├── achievement_model.dart
│   └── user_stats_model.dart
└── presentation/
    ├── providers/
    │   └── gamification_provider.dart
    ├── screens/
    │   ├── achievements_screen.dart
    │   └── leaderboard_screen.dart
    └── widgets/
        ├── level_badge_widget.dart
        └── achievement_card_widget.dart
```

---

## 7. Ecrans UI

### 7.1 Profil (Section Gamification)

**Elements:**
- Badge niveau avec numero
- Score Murgilarity
- Barre de progression niveau
- Apercu des 3 derniers badges debloques
- Lien "Voir tous les badges"

### 7.2 Ecran Badges

**Elements:**
- Section "Debloques" avec badges obtenus
- Section "A debloquer" avec badges grises
- Pour chaque badge:
  - Icone
  - Nom
  - Description
  - Date deblocage ou progression
- Filtres par rarete

### 7.3 Ecran Classement

**Elements:**
- Tabs: Semaine / Mois / Tout
- Liste top utilisateurs avec:
  - Position
  - Avatar
  - Nom
  - Score
  - Niveau
- Ma position mise en evidence
- Toggle: Global / Mes follows

### 7.4 Animation Deblocage

**Elements:**
- Overlay plein ecran
- Badge agrandi avec effet brillant
- Nom et description du badge
- Points gagnes
- Bouton "Genial!"

---

## 8. Regles Metier

### R-GAM-01: Points non-negatifs
Le score Murgilarity ne peut jamais descendre en dessous de 0.

### R-GAM-02: Unicite des badges
Un utilisateur ne peut debloquer chaque badge qu'une seule fois.

### R-GAM-03: Attribution atomique
L'attribution des points et le deblocage des badges doivent etre atomiques (transaction).

### R-GAM-04: Verification asynchrone
La verification des badges se fait de maniere asynchrone via Appwrite Functions pour ne pas bloquer l'UI.

### R-GAM-05: Niveau minimum
Le niveau minimum est 1 (meme avec 0 points).

---

## 9. Notifications

| Evenement | Notification | Type |
|-----------|--------------|------|
| Nouveau badge debloque | "Bravo! Badge X debloque!" | Push + In-app |
| Passage de niveau | "Niveau X atteint!" | Push + In-app |
| Entre dans le top 10 | "Vous etes dans le top 10!" | In-app |

---

## 10. Metriques de Succes

| Metrique | Cible |
|----------|-------|
| % utilisateurs avec > 0 points | > 90% |
| Badges debloques / utilisateur | > 3 |
| Consultation page badges / semaine | > 1 |
| Retention J7 utilisateurs niveau 3+ | > 40% |

---

## 11. Etat d'Implementation

| Composant | Statut |
|-----------|--------|
| Champs murgilarityScore/level dans users | Implemente |
| Attribution points creation FUG | Implemente |
| Attribution points participation | A faire |
| Attribution points followers | A faire |
| Collection achievements | A creer |
| Collection user_achievements | A creer |
| Function gamification | A developper |
| Ecran badges | A developper |
| Ecran classement | A developper |
| Notifications badges | A developper |

---

## 12. Dependances

- **Appwrite Functions**: Logique de calcul
- **Appwrite Realtime**: Mise a jour temps reel du score
- **flutter_local_notifications**: Notifications de deblocage

---

## 13. Risques et Mitigations

| Risque | Probabilite | Impact | Mitigation |
|--------|-------------|--------|------------|
| Farming de points | Moyen | Eleve | Rate limiting, verification anti-fraude |
| Desequilibre points | Moyen | Moyen | Ajustement regulier des valeurs |
| Lassitude utilisateurs | Faible | Moyen | Nouveaux badges saisonniers |

---

## 14. Historique

| Date | Version | Changement |
|------|---------|------------|
| Janvier 2026 | 1.0 | Version initiale, implementation partielle |

---

*Document genere pour le projet FUG - The Develobeers*
