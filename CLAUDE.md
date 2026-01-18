# CLAUDE.md - Instructions pour Claude Code

## Projet FUG (Fous-toi Une Guinze)

Application mobile de réseau social géolocalisé pour trouver des compagnons de boisson.

---

## Stack Technique

- **Frontend**: Flutter 3.24+ (Dart)
- **Backend**: Appwrite Self-Hosted
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Infrastructure**: Docker Compose
- **CI/CD**: GitHub Actions

---

## Structure du Projet

```
FUG/
├── _bmad/                  # Configuration BMAD-METHOD
├── app/                    # Application Flutter
├── functions/              # Appwrite Functions (Node.js)
├── infrastructure/         # Docker + Migrations
├── docs/                   # Documentation pour agents BMAD
└── .github/workflows/      # CI/CD
```

---

## BMAD-METHOD Integration

Ce projet utilise le framework **BMAD-METHOD v6** pour le développement assisté par IA.

### Fichiers BMAD importants

- `_bmad/bmm/config.yaml` - Configuration du projet
- `_bmad/project-brief.md` - Brief pour les agents
- `_bmad/workflows/add-feature.md` - Workflow personnalisé
- `docs/index.md` - Vue d'ensemble projet
- `docs/architecture.md` - Architecture technique
- `docs/business-rules.md` - Règles métier

### Workflow pour ajouter une feature

1. **Analyser** - Lire `docs/` et `_bmad/project-brief.md`
2. **Planifier** - Créer une spec dans `_bmad-output/`
3. **Migration** - Si besoin, créer dans `infrastructure/migrations/migrations/`
4. **Implémenter** - Code Flutter dans `app/lib/features/`
5. **Tester** - Tests dans `app/test/`
6. **Documenter** - Mettre à jour `docs/`

### Agents BMAD recommandés

| Agent | Usage |
|-------|-------|
| `quick-flow-solo-dev` | Bugs et petites features |
| `architect` | Décisions techniques Appwrite/Flutter |
| `dev` | Implémentation avec TDD |
| `tech-writer` | Documentation |

---

## Conventions de Code

### Dart/Flutter

```dart
// Nommage
class MyClassName {}           // PascalCase
void myFunctionName() {}       // camelCase
final myVariableName = '';     // camelCase
const MY_CONSTANT = '';        // SCREAMING_SNAKE_CASE

// Structure feature
lib/features/<feature>/
├── data/
│   └── <feature>_repository.dart
├── domain/
│   └── <feature>_model.dart
└── presentation/
    └── <feature>_screen.dart
```

### JavaScript (Functions)

```javascript
// ES Modules uniquement
import { Client } from 'node-appwrite';

// Async/await
export default async ({ req, res, log, error }) => {
  // ...
};
```

---

## Commandes Utiles

### Infrastructure Docker

```bash
cd infrastructure

# Démarrer tout
make all

# Appwrite seul
make up

# Flutter dev (hot reload)
make app-dev

# Voir les logs
make logs

# Migrations
cd migrations && node migrate.js up --env=development
```

### Flutter

```bash
cd app

# Dépendances
flutter pub get

# Tests
flutter test

# Build web
flutter build web
```

### Functions

```bash
cd functions/<function-name>

# Tests
npm test

# Déployer (via Appwrite CLI)
appwrite functions createDeployment
```

---

## Collections Appwrite

| Collection | Description |
|------------|-------------|
| `users` | Profils utilisateurs avec location |
| `events` | Événements FUG géolocalisés |
| `followers` | Relations de suivi |
| `event_participants` | Participations aux événements |
| `achievements` | Badges disponibles |
| `user_achievements` | Badges débloqués |
| `notifications` | Notifications utilisateur |

---

## Règles Métier Clés

### Murgilarité (Gamification)

| Action | Points |
|--------|--------|
| Créer une FUG | +25 |
| Rejoindre une FUG | +15 |
| Gagner un follower | +10 |
| Suivre quelqu'un | +5 |

### Statuts d'événement

- `active` - FUG en cours
- `ended` - FUG terminée
- `cancelled` - FUG annulée

### Catégories

`bar`, `cafe`, `restaurant`, `park`, `home`, `other`

---

## Environnements

| Env | Endpoint | Usage |
|-----|----------|-------|
| development | http://localhost/v1 | Local Docker |
| test | http://test.fug.app/v1 | Tests CI |
| production | https://api.fug.app/v1 | Production |

---

## Avant de Coder

1. **Lire** `_bmad/project-brief.md` pour le contexte
2. **Vérifier** `docs/architecture.md` pour les patterns
3. **Consulter** `docs/business-rules.md` pour les règles
4. **Créer une migration** si modification de schéma
5. **Écrire les tests** avant l'implémentation (TDD)

---

## Liens Utiles

- [Appwrite Docs](https://appwrite.io/docs)
- [Flutter Docs](https://docs.flutter.dev)
- [Riverpod Docs](https://riverpod.dev)
- [BMAD-METHOD Docs](http://docs.bmad-method.org)

---

## Contact Équipe

**The Develobeers**
- Bruno Boi (BOB)
- Christophe Paquet (PAC)
- Michel Lammens (LAM)
