# CLAUDE.md - Instructions pour Claude Code

## Projet FUG (Fous-toi Une Guinze)

Application mobile de réseau social géolocalisé pour trouver des compagnons de boisson.

---

## Stack Technique

- **Frontend**: Flutter 3.24+ (Dart)
- **Backend**: Appwrite Self-Hosted (via fug-backend)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **CI/CD**: GitHub Actions

---

## Backend Dependency (fug-backend)

FUG utilise le repository partagé **fug-backend** pour l'infrastructure Appwrite.

### Prérequis

Avant de développer sur FUG, le backend doit être démarré:

```bash
# 1. Cloner fug-backend (si pas déjà fait)
git clone git@github.com:knabo6/fug-backend.git /home/knabo/dev/fug-backend

# 2. Démarrer le backend
cd /home/knabo/dev/fug-backend
make dev

# 3. Vérifier que c'est prêt
curl http://localhost/v1/health/version
# Doit retourner {"version":"1.5.7"}
```

### Premier démarrage (bootstrap)

Si c'est une installation fraîche d'Appwrite:

```bash
cd /home/knabo/dev/fug-backend
./setup/bootstrap.sh --env development
```

Le bootstrap crée automatiquement le projet, la base de données, et applique toutes les migrations.

### Version minimale requise

- **fug-backend**: >= v1.0.0

### Workflow de développement

```bash
# Terminal 1: Démarrer le backend (faire en premier)
cd /home/knabo/dev/fug-backend
make dev

# Terminal 2: Démarrer FUG Flutter
cd /home/knabo/dev/FUG/app
flutter run -d chrome
```

### Migrations

Les migrations sont gérées dans fug-backend. Pour modifier le schéma:

```bash
cd /home/knabo/dev/fug-backend/migrations
node migrate.js create "ma-migration"
node migrate.js up --env=development
```

### Accès console Appwrite

- **URL**: http://localhost
- **Email**: fous.toi.une.guinze@gmail.com
- **Password**: (généré par bootstrap, voir setup/.admin-credentials)

---

## Structure du Projet

```
FUG/
├── _bmad/                  # Configuration BMAD-METHOD
├── app/                    # Application Flutter
├── functions/              # Appwrite Functions (Node.js)
├── docs/                   # Documentation pour agents BMAD
└── .github/workflows/      # CI/CD

# Backend (repository séparé)
fug-backend/
├── docker-compose.yml      # Stack Appwrite
├── migrations/             # Migrations Appwrite
├── setup/                  # Bootstrap scripts
└── traefik/                # Reverse proxy
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
4. **Migration** - Si besoin, créer dans `fug-backend/migrations/` (voir section Backend Dependency)
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

## Orchestration BMAD Multi-Agents (OBLIGATOIRE)

**RÈGLE CRITIQUE:** Quand plusieurs agents sont lancés pour implémenter des features, ils DOIVENT suivre l'orchestration BMAD avec le tool `Task` et des agents PO.

### Comment Lancer des Agents BMAD

**IMPORTANT:** Utiliser le tool `Task` avec `subagent_type="general-purpose"` pour créer des agents PO qui orchestrent le workflow BMAD.

```
Pour chaque feature à implémenter:
1. Créer un git worktree dédié AVANT de lancer l'agent
2. Lancer un agent PO via Task tool qui travaille dans ce worktree
3. L'agent PO exécute les 4 phases BMAD (Analyst → Dev → QA → Commit)
```

### Création des Worktrees (AVANT lancement agents)

```bash
# Créer le répertoire parent si nécessaire
mkdir -p /home/knabo/dev/FUG-worktrees

# Créer un worktree par feature
git worktree add /home/knabo/dev/FUG-worktrees/feature-name -b feature/feature-name develop
```

**IMPORTANT:** Les worktrees DOIVENT être créés AVANT de lancer les agents Task.

### Permissions des Sub-Agents (CRITIQUE)

**RÈGLE:** Les agents Task (PO) doivent avoir les permissions d'écriture sur leur worktree.

Dans le prompt du Task agent, inclure explicitement:
```
PERMISSIONS REQUISES:
- Write: autorisé sur /home/knabo/dev/FUG-worktrees/<feature>/
- Edit: autorisé sur /home/knabo/dev/FUG-worktrees/<feature>/
- Bash: autorisé pour git, npm, flutter dans le worktree
```

Si les permissions sont refusées, l'agent DOIT:
1. Signaler le problème dans son output
2. Fournir le code complet à créer manuellement
3. NE PAS abandonner - continuer avec les autres phases

### Workflow Obligatoire par Feature

Chaque feature doit être gérée par un **Agent PO (Product Owner)** qui exécute les phases:

```
┌─────────────────────────────────────────┐
│           AGENT PO (via Task tool)      │
│  - Travaille dans son worktree dédié    │
│  - Exécute les 4 phases séquentiellement│
│  - A les permissions d'écriture         │
├─────────────────────────────────────────┤
│                                         │
│  PHASE 1: ANALYST                       │
│  └─► Lire specs, analyser code existant │
│      Produire rapport d'analyse         │
│                                         │
│  PHASE 2: DEV                           │
│  └─► Implémenter selon specs            │
│      Écrire dans le worktree            │
│                                         │
│  PHASE 3: QA                            │
│  └─► Écrire tests, vérifier conformité  │
│      Produire rapport QA                │
│                                         │
│  PHASE 4: COMMIT                        │
│  └─► git add, git commit dans worktree  │
│                                         │
└─────────────────────────────────────────┘
```

### Règles pour les Agents PO

1. **Lire CLAUDE.md** - Chaque agent DOIT lire `/home/knabo/dev/FUG/CLAUDE.md`
2. **Travailler dans le bon worktree** - Utiliser UNIQUEMENT le worktree assigné
3. **Suivre Clean Architecture** - data/domain/presentation
4. **Utiliser Riverpod** - Pour le state management
5. **Écrire des tests** - Phase QA obligatoire
6. **Ne pas merger** - Seul le CTO/Orchestrateur merge après review
7. **Commit dans le worktree** - Pas de push, juste commit local

### Lancement d'Agents en Parallèle

Quand on lance plusieurs features en parallèle:

```bash
# 1. Créer TOUS les worktrees d'abord
git worktree add /home/knabo/dev/FUG-worktrees/mod-001 -b feature/mod-001 develop
git worktree add /home/knabo/dev/FUG-worktrees/mod-002 -b feature/mod-002 develop
git worktree add /home/knabo/dev/FUG-worktrees/us-020 -b feature/us-020 develop

# 2. Lancer les agents Task en parallèle (dans un seul message avec plusieurs tool calls)
# Chaque agent travaille dans son worktree isolé
# Pas de conflits entre agents
```

### Template Prompt pour Agent PO (Task tool)

```
Tu es un Agent PO BMAD qui implémente une feature complète.

WORKTREE: /home/knabo/dev/FUG-worktrees/<feature-name>
BRANCH: feature/<feature-name>
FEATURE: <Description de la feature>
SPEC: <Chemin vers la spec dans _bmad-output/>

IMPORTANT: Tu dois d'abord lire /home/knabo/dev/FUG/CLAUDE.md pour les conventions.

Tu travailles UNIQUEMENT dans ton worktree. Tu as les permissions d'écriture.

PHASE 1 - ANALYST:
- Lis la spec de la feature
- Analyse le code existant dans le repo principal
- Produis un rapport d'analyse

PHASE 2 - DEV:
- Implémente la feature dans ton worktree
- Suis Clean Architecture (data/domain/presentation)
- Crée les migrations si nécessaire

PHASE 3 - QA:
- Écris les tests unitaires
- Vérifie la conformité avec la spec
- Produis un rapport QA

PHASE 4 - COMMIT:
- git add des fichiers modifiés
- git commit avec message conventionnel
- NE PAS push (l'orchestrateur s'en charge)
```

### Après Complétion des Agents (Merge Workflow)

L'orchestrateur (session principale) doit suivre ce workflow pour un historique Git propre:

```
┌─────────────────────────────────────────────────────────┐
│  WORKFLOW MERGE AVEC REBASE (Historique Propre)         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. REVIEW DES OUTPUTS                                  │
│     - Vérifier les outputs de chaque agent              │
│     - S'assurer que les tests passent                   │
│                                                         │
│  2. REBASE SUR DEVELOP                                  │
│     cd /home/knabo/dev/FUG-worktrees/<feature>          │
│     git fetch origin develop                            │
│     git rebase origin/develop                           │
│                                                         │
│  3. COMMITS PAR STORY (si modifications partielles)     │
│     git add -p  # Stage par hunks/lignes                │
│     git commit -m "feat(scope): story description"      │
│                                                         │
│  4. MERGE REQUEST (Optionnel mais recommandé)           │
│     git push -u origin feature/<feature-name>           │
│     gh pr create --base develop --title "..."           │
│                                                         │
│  5. MERGE AVEC FAST-FORWARD (si pas de MR)              │
│     cd /home/knabo/dev/FUG                              │
│     git merge --ff-only feature/<feature-name>          │
│                                                         │
│  6. CLEANUP                                             │
│     git worktree remove ../FUG-worktrees/<feature>      │
│     git branch -d feature/<feature-name>                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Commandes Utiles pour Commits Propres

```bash
# Stage par lignes (hunks interactif)
git add -p <file>

# Stage lignes spécifiques avec VS Code/IDE
# Utiliser l'interface git pour sélectionner les lignes

# Rebase interactif pour réorganiser commits
git rebase -i HEAD~3  # Réorganiser les 3 derniers commits

# Squash de commits avant merge
git rebase -i develop  # Puis 'squash' ou 'fixup'
```

#### Convention de Commits par Story

```
feat(scope): <story-id> <description>

# Exemples:
feat(rgpd): MOD-001-B add data export functionality
feat(dsa): MOD-003 add content reporting system
feat(events): US-024 add cancel participation feature
fix(auth): US-012 fix password reset flow
```

### Merge Requests (Recommandé pour Review)

Pour les features importantes, utiliser des Merge Requests:

```bash
# Dans le worktree de la feature
git push -u origin feature/<feature-name>

# Créer la MR
gh pr create \
  --base develop \
  --title "feat(scope): <story-id> <description>" \
  --body "## Summary
- Implementation of <story>

## Test plan
- [ ] Tests pass
- [ ] QA review done"
```

L'orchestrateur (agent principal) peut alors:
1. Review la MR via `gh pr view <number>`
2. Approuver et merger via `gh pr merge <number> --rebase`
3. Supprimer la branche après merge

---

## Regles Infrastructure Appwrite (OBLIGATOIRE)

**REGLE CRITIQUE:** Aucune modification manuelle dans la console Appwrite. TOUT doit passer par migration dans **fug-backend**.

### Principe

L'infrastructure Appwrite est geree exclusivement via le systeme de migrations dans le repository `fug-backend`. Cela garantit:
- **Reproductibilite** sur nouveaux serveurs
- **Historique** des changements via git
- **Pas de clonage** de DB entre environnements
- **Partage** avec d'autres apps (Ketal)

### Comment creer une migration

```bash
cd /home/knabo/dev/fug-backend/migrations
node migrate.js create mon-nom-de-migration
node migrate.js up --env=development
```

### Ce qui est INTERDIT

- Creer une collection via la console Appwrite
- Ajouter un attribut manuellement
- Modifier les permissions directement dans Appwrite

**Les migrations sont dans fug-backend, pas dans FUG.**

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

### Backend (fug-backend)

```bash
cd /home/knabo/dev/fug-backend

# Démarrer Appwrite
make dev

# Voir les logs
make logs

# Migrations
make migrate ENV=development

# Status des migrations
make migrate-status
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
