# Guide de Contribution - FUG

Merci de votre interet pour contribuer au projet FUG (Find Urban Gatherings)! Ce guide vous aidera a configurer votre environnement de developpement et a comprendre notre processus de contribution.

## Table des matieres

- [Prerequis](#prerequis)
- [Setup de l'environnement de developpement](#setup-de-lenvironnement-de-developpement)
- [Structure du projet](#structure-du-projet)
- [Processus de Pull Request](#processus-de-pull-request)
- [Conventions de commit](#conventions-de-commit)
- [Tests requis](#tests-requis)
- [Style de code](#style-de-code)

## Prerequis

Avant de commencer, assurez-vous d'avoir installe les outils suivants:

### Outils obligatoires

| Outil | Version minimale | Verification |
|-------|------------------|--------------|
| Node.js | 18.0.0+ | `node --version` |
| npm | 9.0.0+ | `npm --version` |
| Docker | 24.0.0+ | `docker --version` |
| Docker Compose | 2.20.0+ | `docker compose version` |
| Flutter | 3.16.0+ | `flutter --version` |
| Dart | 3.2.0+ | `dart --version` |
| Git | 2.40.0+ | `git --version` |

### Outils recommandes

- **IDE**: VS Code avec les extensions Flutter, Dart, et ESLint
- **Appwrite CLI**: Pour le deploiement des fonctions
- **Postman/Insomnia**: Pour tester les APIs

## Setup de l'environnement de developpement

### 1. Cloner le repository

```bash
git clone https://github.com/TheDevelobeers/FUG.git
cd FUG
```

### 2. Utiliser le script de setup automatique

```bash
# Setup complet pour le developpement
./setup.sh dev

# Ou pour les tests
./setup.sh test
```

### 3. Setup manuel (si necessaire)

#### Infrastructure (Backend)

```bash
# Aller dans le dossier infrastructure
cd infrastructure

# Copier le fichier d'environnement
cp .env.example .env
# Editer .env avec vos valeurs

# Lancer les services Docker
docker compose up -d

# Attendre qu'Appwrite soit pret
./scripts/wait-for-appwrite.sh

# Executer les migrations
cd migrations
npm install
npm run migrate:dev
```

#### Application Flutter

```bash
# Aller dans le dossier app
cd app

# Installer les dependances
flutter pub get

# Generer les fichiers de code (Riverpod, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run
```

#### Fonctions Appwrite

```bash
# Installer les dependances de chaque fonction
cd functions/follow-user && npm install
cd ../join-event && npm install
cd ../create-event && npm install
cd ../gamification && npm install
```

## Structure du projet

```
FUG/
├── app/                    # Application Flutter
│   ├── lib/
│   │   ├── core/          # Services, config, utils partages
│   │   └── features/      # Fonctionnalites par domaine
│   └── test/
├── functions/              # Fonctions Appwrite
│   ├── follow-user/
│   ├── join-event/
│   ├── create-event/
│   └── gamification/
├── infrastructure/         # Configuration Docker et scripts
│   ├── migrations/        # Systeme de migrations
│   └── scripts/           # Scripts de setup et maintenance
└── docs/                   # Documentation additionnelle
```

## Processus de Pull Request

### 1. Creer une branche

Utilisez le format suivant pour nommer vos branches:

```bash
# Nouvelle fonctionnalite
git checkout -b feature/nom-de-la-fonctionnalite

# Correction de bug
git checkout -b fix/description-du-bug

# Refactoring
git checkout -b refactor/description

# Documentation
git checkout -b docs/description

# Tests
git checkout -b test/description
```

### 2. Developper votre fonctionnalite

- Ecrivez du code propre et documente
- Ajoutez des tests pour les nouvelles fonctionnalites
- Assurez-vous que tous les tests passent
- Verifiez le linting

### 3. Creer la Pull Request

1. Poussez votre branche sur le remote
2. Creez une PR via GitHub
3. Remplissez le template de PR:
   - Description claire des changements
   - Captures d'ecran si UI modifiee
   - Liste des tests effectues
   - Lien vers l'issue associee

### 4. Review et merge

- Au moins 1 approbation requise
- Tous les checks CI doivent passer
- Pas de conflits avec la branche principale
- Squash and merge prefere

## Conventions de commit

Nous utilisons [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <description>

[body optionnel]

[footer optionnel]
```

### Types autorises

| Type | Description |
|------|-------------|
| `feat` | Nouvelle fonctionnalite |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `style` | Formatage (pas de changement de code) |
| `refactor` | Refactoring (pas de nouvelle fonctionnalite ni fix) |
| `perf` | Amelioration des performances |
| `test` | Ajout ou modification de tests |
| `chore` | Maintenance, config, dependances |
| `ci` | Configuration CI/CD |

### Scopes possibles

- `app` - Application Flutter
- `api` - Backend/Appwrite
- `func` - Fonctions Appwrite
- `infra` - Infrastructure/Docker
- `docs` - Documentation

### Exemples

```bash
# Nouvelle fonctionnalite
git commit -m "feat(app): add event creation screen"

# Bug fix
git commit -m "fix(func): handle null userId in follow-user"

# Documentation
git commit -m "docs: update README with setup instructions"

# Refactoring
git commit -m "refactor(app): extract auth logic to repository"

# Breaking change
git commit -m "feat(api)!: change event date format to ISO 8601

BREAKING CHANGE: All dates are now in ISO 8601 format"
```

## Tests requis

### Application Flutter

```bash
cd app

# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage

# Verification du coverage (minimum 70%)
lcov --summary coverage/lcov.info
```

### Fonctions Appwrite

```bash
cd functions/<function-name>

# Tests unitaires
npm test

# Tests avec coverage
npm run test:coverage
```

### Tests d'integration

```bash
# Depuis la racine du projet
./scripts/run-integration-tests.sh
```

### Criteres de qualite

| Metrique | Minimum requis |
|----------|----------------|
| Coverage unitaire | 70% |
| Coverage integration | 50% |
| Linting errors | 0 |
| Build warnings | 0 (Flutter) |

## Style de code

### Dart/Flutter

- Suivre le [Effective Dart](https://dart.dev/effective-dart)
- Utiliser `flutter analyze` avant chaque commit
- Formatter avec `dart format`

```bash
# Verification
flutter analyze

# Formatage automatique
dart format .
```

### JavaScript (Fonctions)

- ESLint avec la configuration du projet
- Prettier pour le formatage

```bash
# Verification
npm run lint

# Formatage automatique
npm run format
```

### Configuration VS Code recommandee

Ajoutez dans `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

## Besoin d'aide?

- Ouvrez une [issue](https://github.com/TheDevelobeers/FUG/issues) pour les questions
- Rejoignez notre Discord pour discuter
- Consultez la documentation dans `/docs`

---

Merci de contribuer a FUG! Ensemble, rendons la decouverte d'evenements plus facile.
