# Workflow: Release FUG

> Workflow BMAD pour la publication de nouvelles versions de l'application FUG

## Vue d'Ensemble

Ce workflow guide le processus complet de release, du bump de version jusqu'au deploiement en production.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW: RELEASE-FUG                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. VERSION         2. CHANGELOG        3. TAG                         │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐                    │
│  │  Bump   │  ───►  │ Rediger │  ───►   │ Git tag │                    │
│  │ version │        │ changes │         │  push   │                    │
│  └─────────┘        └─────────┘         └─────────┘                    │
│                                                │                        │
│                                                ▼                        │
│  6. DEPLOY PROD     5. VALIDER          4. DEPLOY STAGING             │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐                    │
│  │ Deployer│  ◄──   │ Tester  │  ◄───   │ Deployer│                    │
│  │  prod   │        │ staging │         │ staging │                    │
│  └─────────┘        └─────────┘         └─────────┘                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Pre-requis

### Avant de commencer une release

- [ ] Tous les tickets du milestone sont fermes
- [ ] Branche `develop` est stable
- [ ] Tous les tests passent
- [ ] Code review complete sur les PRs
- [ ] Pas de bugs critiques ouverts

### Branches Git

```
main        ─────●─────●─────●───── (releases)
                 │     │     │
develop     ────●┴────●┴────●┴───── (integration)
                │     │     │
feature/*   ───●─────●─────●─────── (features)
```

---

## Etape 1: Version Bump

### Objectif
Mettre a jour le numero de version selon le Semantic Versioning.

### Semantic Versioning

```
MAJOR.MINOR.PATCH

MAJOR: Changements incompatibles (breaking changes)
MINOR: Nouvelles fonctionnalites retrocompatibles
PATCH: Corrections de bugs retrocompatibles
```

### Checklist

- [ ] Determiner le type de release (major/minor/patch)
- [ ] Mettre a jour `pubspec.yaml`
- [ ] Mettre a jour le build number
- [ ] Committer les changements de version

### Fichiers a modifier

#### pubspec.yaml
```yaml
# Avant
version: 1.2.3+45

# Apres (exemple patch)
version: 1.2.4+46
```

### Commandes

```bash
cd app

# Voir la version actuelle
grep "version:" pubspec.yaml

# Modifier la version (manuel ou script)
# Format: version: X.Y.Z+BUILD_NUMBER

# Committer
git checkout develop
git pull origin develop
git checkout -b release/1.2.4

# Modifier pubspec.yaml puis:
git add pubspec.yaml
git commit -m "chore: bump version to 1.2.4"
```

### Conventions de version FUG

| Type | Quand | Exemple |
|------|-------|---------|
| PATCH | Bugfixes uniquement | 1.2.3 -> 1.2.4 |
| MINOR | Nouvelles features | 1.2.3 -> 1.3.0 |
| MAJOR | Breaking changes | 1.2.3 -> 2.0.0 |

---

## Etape 2: Changelog

### Objectif
Documenter tous les changements de la version.

### Checklist

- [ ] Lister toutes les features ajoutees
- [ ] Lister tous les bugs corriges
- [ ] Mentionner les breaking changes
- [ ] Crediter les contributeurs

### Emplacement
```
app/CHANGELOG.md
```

### Template: Entree Changelog

```markdown
## [1.2.4] - 2026-01-21

### Ajoute
- Nouvelle fonctionnalite de chat entre participants (#123)
- Support des notifications push pour les invitations (#124)

### Modifie
- Amelioration des performances de la carte (#125)
- Mise a jour du design de l'ecran profil (#126)

### Corrige
- Correction du crash au demarrage sur Android 14 (#127)
- Fix de la synchronisation des evenements (#128)

### Securite
- Mise a jour des dependances de securite (#129)

### Breaking Changes
- L'API de geolocalisation requiert maintenant une permission explicite

### Contributeurs
- @bruno-boi
- @christophe-paquet
- @michel-lammens
```

### Commandes Git pour lister les changements

```bash
# Voir les commits depuis la derniere release
git log v1.2.3..HEAD --oneline

# Avec plus de details
git log v1.2.3..HEAD --pretty=format:"- %s (%h)"

# Filtrer par type
git log v1.2.3..HEAD --oneline | grep -i "feat:"
git log v1.2.3..HEAD --oneline | grep -i "fix:"
```

---

## Etape 3: Tag et Push

### Objectif
Creer le tag Git et merger vers main.

### Checklist

- [ ] Merger la branche release vers main
- [ ] Creer le tag annote
- [ ] Pusher le tag
- [ ] Merger main vers develop

### Commandes

```bash
# Finaliser la branche release
git checkout release/1.2.4
git add CHANGELOG.md
git commit -m "docs: update changelog for 1.2.4"

# Merger vers main
git checkout main
git pull origin main
git merge --no-ff release/1.2.4 -m "release: v1.2.4"

# Creer le tag
git tag -a v1.2.4 -m "Release version 1.2.4

Changes:
- Feature: Chat entre participants
- Feature: Notifications push
- Fix: Crash Android 14
- Fix: Synchronisation evenements"

# Pusher main et le tag
git push origin main
git push origin v1.2.4

# Merger vers develop
git checkout develop
git merge --no-ff main -m "chore: merge release 1.2.4 into develop"
git push origin develop

# Supprimer la branche release
git branch -d release/1.2.4
git push origin --delete release/1.2.4
```

### Convention de nommage des tags

```
v[MAJOR].[MINOR].[PATCH]

Exemples:
- v1.0.0
- v1.2.4
- v2.0.0-beta.1
```

---

## Etape 4: Deployer sur Staging

### Objectif
Deployer la nouvelle version sur l'environnement de staging.

### Checklist

- [ ] Build de l'application
- [ ] Deployer le backend (si modifie)
- [ ] Deployer les Functions (si modifiees)
- [ ] Deployer le frontend
- [ ] Verifier les logs de deploiement

### Commandes de build

```bash
cd app

# Build web
flutter build web --release

# Build Android
flutter build apk --release
# ou
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### Deploiement via GitHub Actions

Le workflow CI/CD devrait se declencher automatiquement sur le tag:

```yaml
# .github/workflows/release.yml
on:
  push:
    tags:
      - 'v*'
```

### Deploiement manuel (si necessaire)

```bash
# Backend Appwrite
cd infrastructure
make deploy-staging

# Functions
cd functions/[function]
appwrite functions createDeployment --functionId=[id]

# Frontend (exemple Firebase Hosting)
firebase deploy --only hosting:staging
```

---

## Etape 5: Valider sur Staging

### Objectif
Tester la release sur l'environnement de staging avant production.

### Checklist de validation

- [ ] Application demarre correctement
- [ ] Connexion/inscription fonctionne
- [ ] Features principales operationnelles
- [ ] Nouvelles features de la release testees
- [ ] Pas de regression sur features existantes
- [ ] Performance acceptable
- [ ] Pas d'erreurs dans les logs

### Tests a effectuer

```markdown
## Tests fonctionnels

### Authentification
- [ ] Inscription nouvel utilisateur
- [ ] Connexion utilisateur existant
- [ ] Deconnexion
- [ ] Mot de passe oublie

### FUG (Evenements)
- [ ] Creer une FUG
- [ ] Rejoindre une FUG
- [ ] Voir les FUGs a proximite
- [ ] Annuler une FUG

### Profil
- [ ] Voir son profil
- [ ] Modifier son profil
- [ ] Voir le profil d'un autre

### Social
- [ ] Suivre un utilisateur
- [ ] Voir ses followers
- [ ] Notifications

## Tests techniques

### Performance
- [ ] Temps de chargement < 3s
- [ ] Pas de freeze UI
- [ ] Memoire stable

### Erreurs
- [ ] Pas de crash
- [ ] Gestion des erreurs reseau
- [ ] Messages d'erreur clairs
```

### Rapporter les problemes

Si des problemes sont trouves:

1. **Bloquant**: Arreter la release, corriger, recommencer
2. **Majeur**: Decider si correction necessaire avant prod
3. **Mineur**: Documenter pour prochaine release

---

## Etape 6: Deployer en Production

### Objectif
Deployer la version validee en production.

### Pre-requis

- [ ] Staging valide par l'equipe
- [ ] Pas de bugs bloquants
- [ ] Fenetre de deploiement appropriee
- [ ] Equipe disponible pour monitoring

### Checklist de deploiement

- [ ] Communiquer le deploiement a l'equipe
- [ ] Verifier les backups
- [ ] Deployer le backend (si modifie)
- [ ] Deployer les Functions (si modifiees)
- [ ] Deployer le frontend
- [ ] Verifier les logs
- [ ] Tester en production
- [ ] Communiquer la fin du deploiement

### Commandes de deploiement production

```bash
# Via CI/CD (recommande)
# Approuver le deploiement prod dans GitHub Actions

# Manuel (si necessaire)
cd infrastructure
make deploy-production
```

### Monitoring post-deploiement

```markdown
## A surveiller pendant 1h apres deploiement

- [ ] Taux d'erreur dans les logs
- [ ] Temps de reponse API
- [ ] Nombre d'utilisateurs connectes
- [ ] Metriques de performance
- [ ] Feedbacks utilisateurs

## Alertes a configurer

- Taux d'erreur > 1%
- Temps de reponse > 2s
- Crash rate > 0.1%
```

### Rollback (si necessaire)

```bash
# Deployer la version precedente
git checkout v1.2.3
flutter build web --release
# Redeployer

# Ou via tag precedent dans CI/CD
```

---

## Etape 7: Communication

### Objectif
Informer les parties prenantes de la nouvelle version.

### Checklist

- [ ] Mettre a jour la page de release GitHub
- [ ] Notifier l'equipe (Slack/Discord)
- [ ] Mettre a jour les stores (si app mobile)
- [ ] Communiquer aux utilisateurs (si necessaire)

### Template: Release Notes GitHub

```markdown
# Release v1.2.4

## Nouveautes

### Chat entre participants
Vous pouvez maintenant discuter avec les autres participants d'une FUG!

### Notifications push
Recevez des notifications quand quelqu'un vous invite a une FUG.

## Corrections

- Correction du crash au demarrage sur Android 14
- Amelioration de la synchronisation des evenements

## Notes techniques

- Mise a jour Flutter 3.24
- Optimisation des performances

## Installation

### Web
Accedez a https://app.fug.app

### Android
Telechargez sur le Play Store

### iOS
Telechargez sur l'App Store

---

Merci a tous les contributeurs!
```

---

## Checklist Finale de Release

### Pre-release
- [ ] Code stable et teste
- [ ] Milestone complete
- [ ] Version bump effectue
- [ ] Changelog a jour
- [ ] Tag cree et pushe

### Staging
- [ ] Deploiement reussi
- [ ] Tests de validation passes
- [ ] Pas de regression

### Production
- [ ] Deploiement reussi
- [ ] Monitoring OK
- [ ] Communication faite

### Post-release
- [ ] Release notes publiees
- [ ] Stores mis a jour (si applicable)
- [ ] Equipe informee
- [ ] Retrospective planifiee

---

## Calendrier de Release

### Release reguliere
- **Frequence**: Toutes les 2 semaines
- **Jour**: Mardi (moins risque que vendredi)
- **Heure**: 10h (temps de reagir si probleme)

### Hotfix
- **Quand**: Bug critique en production
- **Process**: Simplifie (fix -> test -> deploy)
- **Branche**: `hotfix/[description]` depuis `main`

---

*Workflow BMAD-METHOD pour FUG - v1.0*
