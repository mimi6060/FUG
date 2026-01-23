# Workflow: Correction de Bug FUG

> Workflow BMAD pour la correction rapide de bugs dans le projet FUG

## Vue d'Ensemble

Ce workflow guide la correction efficace d'un bug, de sa reproduction jusqu'a sa documentation.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW: BUGFIX-FUG                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. REPRODUIRE      2. DIAGNOSTIQUER    3. CORRIGER                    │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐                    │
│  │ Confirmer│  ───►  │ Trouver │  ───►   │ Appliquer│                   │
│  │ le bug  │        │ la cause│         │ le fix  │                    │
│  └─────────┘        └─────────┘         └─────────┘                    │
│                                                │                        │
│                                                ▼                        │
│  5. DOCUMENTER                          4. TESTER                      │
│  ┌─────────┐                            ┌─────────┐                    │
│  │ Mettre a│  ◄──────────────────────   │ Verifier│                    │
│  │  jour   │                            │ le fix  │                    │
│  └─────────┘                            └─────────┘                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Etape 1: Reproduire le Bug

### Objectif
Confirmer l'existence du bug et comprendre les conditions de reproduction.

### Checklist

- [ ] Lire le rapport de bug / ticket
- [ ] Identifier l'environnement concerne (dev/test/prod)
- [ ] Reproduire le bug localement
- [ ] Noter les etapes exactes de reproduction
- [ ] Capturer les logs d'erreur
- [ ] Identifier la severite (Critique/Majeur/Mineur)

### Questions a se poser

```markdown
1. Le bug est-il reproductible?
   - [ ] Toujours reproductible
   - [ ] Intermittent
   - [ ] Specifique a un environnement

2. Quel est l'impact?
   - [ ] Bloque l'application
   - [ ] Fonctionnalite inutilisable
   - [ ] Experience degradee
   - [ ] Cosmetique

3. Depuis quand le bug existe?
   - [ ] Regression recente
   - [ ] Bug existant depuis longtemps
   - [ ] Inconnu
```

### Output
- Etapes de reproduction claires
- Logs d'erreur captures
- Severite evaluee

---

## Etape 2: Diagnostiquer la Cause

### Objectif
Identifier la cause racine du bug.

### Checklist

- [ ] Analyser les logs et stack traces
- [ ] Identifier le(s) fichier(s) concerne(s)
- [ ] Verifier l'historique Git (git blame, git log)
- [ ] Tester des hypotheses avec des logs supplementaires
- [ ] Confirmer la cause racine

### Techniques de diagnostic

```bash
# Voir l'historique d'un fichier
git log --oneline -10 app/lib/features/[feature]/[file].dart

# Trouver qui a modifie une ligne
git blame app/lib/features/[feature]/[file].dart

# Rechercher dans le code
grep -r "motif_recherche" app/lib/

# Voir les modifications recentes
git diff HEAD~5 app/lib/features/
```

### Zones a verifier selon le type de bug

| Type de bug | Zones a verifier |
|-------------|-----------------|
| Crash | Stack trace, null checks, async/await |
| UI | Widgets, providers, state management |
| Data | Repository, JSON parsing, Appwrite queries |
| Performance | Queries N+1, rebuilds excessifs, memory leaks |
| Auth | Tokens, permissions, sessions |

### Output
- Cause racine identifiee
- Fichier(s) a modifier
- Complexite de la correction estimee

---

## Etape 3: Corriger le Bug

### Objectif
Appliquer une correction propre et minimale.

### Checklist

- [ ] Creer une branche de fix (`fix/[description-courte]`)
- [ ] Appliquer la correction minimale necessaire
- [ ] Eviter les refactorings non lies au bug
- [ ] Ajouter des commentaires si logique complexe
- [ ] Verifier qu'aucune regression n'est introduite

### Principes de correction

```markdown
1. Correction minimale
   - Ne corriger que ce qui est necessaire
   - Eviter les "tant qu'on y est..."
   - Un commit = un bug corrige

2. Qualite du fix
   - Traiter la cause, pas le symptome
   - Ajouter des guards si necessaire
   - Gerer les cas limites decouverts

3. Retrocompatibilite
   - Ne pas casser l'API existante
   - Verifier les impacts sur d'autres features
```

### Template: Commit de bugfix

```bash
git checkout -b fix/[description-courte]

# Apres correction
git add [fichiers]
git commit -m "fix([scope]): [description courte]

- Cause: [explication de la cause]
- Solution: [explication de la correction]

Fixes #[numero-ticket]"
```

---

## Etape 4: Tester la Correction

### Objectif
Verifier que le bug est corrige et qu'aucune regression n'est introduite.

### Checklist

- [ ] Verifier que le bug original est corrige
- [ ] Tester les cas limites associes
- [ ] Executer les tests unitaires existants
- [ ] Ajouter un test de non-regression si possible
- [ ] Tester manuellement les features associees

### Template: Test de non-regression

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bug #[numero] - [description courte]', () {
    test('should not [description du bug]', () {
      // Arrange
      // Recreer les conditions du bug

      // Act
      // Executer l'action qui causait le bug

      // Assert
      // Verifier que le bug ne se produit plus
    });
  });
}
```

### Commandes de test

```bash
# Tous les tests
flutter test

# Tests d'une feature specifique
flutter test test/unit/[feature]_test.dart

# Avec verbose
flutter test --reporter=expanded
```

---

## Etape 5: Documenter

### Objectif
Documenter la correction pour reference future.

### Checklist

- [ ] Mettre a jour le ticket/issue avec la solution
- [ ] Ajouter au CHANGELOG si correction importante
- [ ] Documenter si comportement change
- [ ] Creer la Pull Request avec description detaillee

### Template: Description de Pull Request

```markdown
## Bug corrige
[Description du bug]

## Cause racine
[Explication de ce qui causait le bug]

## Solution
[Description de la correction appliquee]

## Tests
- [x] Test de non-regression ajoute
- [x] Tests existants passent
- [x] Test manuel effectue

## Checklist
- [ ] Code review demande
- [ ] CI passe
- [ ] Documentation mise a jour si necessaire

Fixes #[numero-ticket]
```

---

## Checklist Finale

Avant de merger la correction:

### Technique
- [ ] Bug reproduit et compris
- [ ] Correction minimale appliquee
- [ ] Pas de regression introduite
- [ ] Tests passent

### Process
- [ ] Branche nommee correctement (`fix/...`)
- [ ] Commit message descriptif
- [ ] PR avec description complete
- [ ] Code review effectue

### Verification
- [ ] Bug corrige en environnement de dev
- [ ] Cas limites testes
- [ ] Features associees fonctionnelles

---

## Severite des Bugs

### Critique (P0)
- Application crash
- Perte de donnees
- Faille de securite
- **Action**: Correction immediate, hotfix si necessaire

### Majeur (P1)
- Fonctionnalite principale inutilisable
- Experience utilisateur tres degradee
- **Action**: Correction dans les 24-48h

### Mineur (P2)
- Fonctionnalite secondaire impactee
- Contournement possible
- **Action**: Correction dans le sprint courant

### Cosmetique (P3)
- Probleme visuel mineur
- Typo, alignement
- **Action**: Correction quand possible

---

*Workflow BMAD-METHOD pour FUG - v1.0*
