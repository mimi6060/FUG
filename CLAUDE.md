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
3. **Synchroniser Plane** - Créer/mettre à jour les stories (voir section ci-dessous)
4. **Migration** - Si besoin, créer dans `infrastructure/migrations/migrations/`
5. **Implémenter** - Code Flutter dans `app/lib/features/`
6. **Tester** - Tests dans `app/test/`
7. **Documenter** - Mettre à jour `docs/`
8. **Clôturer** - Marquer stories comme Done dans Plane

---

## Gestion des Stories (Plane)

**IMPORTANT:** Toute modification ou ajout de stories BMAD doit être répercutée dans Plane.

### Accès Plane

- **URL**: http://localhost:8088
- **Workspace**: fug
- **Project**: MVP v1.0
- **API Key**: Utiliser la variable dans `import-stories.sh`

### Synchronisation BMAD <-> Plane

| Action BMAD | Action Plane |
|-------------|--------------|
| Nouvelle feature dans `_bmad-output/planning-artifacts/features/` | Créer stories correspondantes dans Plane |
| Modification d'une feature | Mettre à jour description story Plane |
| Feature complétée | Marquer stories comme Done |
| Nouvelle epic | Créer nouveau module dans Plane |

### Structure des Features BMAD

```
_bmad-output/planning-artifacts/features/
├── auth-feature-prd.md
├── events-feature-prd.md
├── gamification-feature-prd.md
└── modernisation-2026/           # Epic E0
    ├── 00-index.md               # Index et priorités
    ├── MOD-001-rgpd-compliance.md
    ├── MOD-002-apple-signin.md
    └── ...
```

### Versioning des Specs

Le changelog des specs est maintenu dans:
`_bmad-output/planning-artifacts/versions/CHANGELOG.md`

### Commandes Plane API

```bash
# Lister les stories
curl -s "http://localhost:8088/api/v1/workspaces/fug/projects/PROJECT_ID/issues/" \
  -H "x-api-key: API_KEY"

# Mettre à jour statut
curl -X PATCH "http://localhost:8088/api/v1/workspaces/fug/projects/PROJECT_ID/issues/ISSUE_ID/" \
  -H "x-api-key: API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"state": "STATE_ID"}'
```

### IDs Plane Importants

| Element | ID |
|---------|---|
| Project MVP v1.0 | `f110c685-ede4-4756-8e41-8cb39bb316f3` |
| State: Backlog | `cd62817e-581b-47bd-b8eb-0486aff77ca3` |
| State: Todo | `ea7339fb-b9ec-4a10-a49c-53fc3e8bc795` |
| State: In Progress | `c7be50de-1d35-4292-b95d-d0c82003c655` |
| State: Done | `f1b62e61-f55a-4b14-a80b-03c3adee9d77` |

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
| Créer une FUG | +10 |
| Rejoindre une FUG | +5 |
| Recevoir un follower | +2 |
| Débloquer un badge | +points du badge |

### Statuts d'événement

- `draft` - Brouillon (non publié)
- `active` - Publié, en attente de début
- `ongoing` - FUG en cours
- `completed` - FUG terminée
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

## Règles Git

- **Ne JAMAIS ajouter** `Co-Authored-By: Claude` dans les commits
- Utiliser des messages de commit en anglais avec le format conventional commits
- Suivre le Git Flow: `main`, `develop`, `feature/*`, `bugfix/*`, `release/*`

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
- Michel Lammens (LAM)
- Christophe Paquet (PAC)

*Projet original (2014): Bruno Boi, Christophe Paquet, Michel Lammens*
