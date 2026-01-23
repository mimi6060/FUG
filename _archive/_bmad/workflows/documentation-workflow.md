# Workflow: Documentation FUG

> Workflow BMAD pour la mise a jour et la creation de documentation

## Vue d'Ensemble

Ce workflow guide la creation et la mise a jour de la documentation du projet FUG.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW: DOCUMENTATION-FUG                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. IDENTIFIER        2. ECRIRE          3. REVIEWER                   │
│  ┌─────────┐          ┌─────────┐        ┌─────────┐                   │
│  │ Analyser│   ───►   │ Rediger │  ───►  │ Relire  │                   │
│  │ lacunes │          │ contenu │        │ valider │                   │
│  └─────────┘          └─────────┘        └─────────┘                   │
│                                                │                        │
│                                                ▼                        │
│                                          4. REFERENCER                 │
│                                          ┌─────────┐                   │
│                                          │ Liens & │                   │
│                                          │ index   │                   │
│                                          └─────────┘                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Etape 1: Identifier les Lacunes

### Objectif
Analyser la documentation existante et identifier ce qui manque ou doit etre mis a jour.

### Checklist

- [ ] Passer en revue les fichiers `docs/`
- [ ] Verifier la coherence avec le code actuel
- [ ] Identifier les features non documentees
- [ ] Lister les sections obsoletes
- [ ] Collecter le feedback de l'equipe

### Structure documentaire FUG

```
docs/
├── index.md              # Vue d'ensemble projet
├── architecture.md       # Architecture technique
├── business-rules.md     # Regles metier
├── api-reference.md      # Reference API Appwrite
└── deployment.md         # Guide de deploiement

_bmad/
├── project-brief.md      # Brief BMAD
├── bmm/config.yaml       # Configuration BMAD
└── workflows/            # Workflows (ce dossier)
```

### Questions a se poser

```markdown
1. Documentation manquante:
   - [ ] Nouvelle feature non documentee?
   - [ ] Nouveau endpoint API?
   - [ ] Nouvelle collection Appwrite?
   - [ ] Nouveau workflow de developpement?

2. Documentation obsolete:
   - [ ] API changee mais doc non mise a jour?
   - [ ] Screenshots/exemples depasses?
   - [ ] Liens casses?

3. Documentation incomplete:
   - [ ] Exemples de code manquants?
   - [ ] Cas d'usage non couverts?
   - [ ] Erreurs courantes non documentees?
```

### Matrice de priorite

| Type de doc | Audience | Priorite |
|-------------|----------|----------|
| Architecture | Developpeurs | Haute |
| Business rules | Developpeurs/PO | Haute |
| API reference | Developpeurs | Moyenne |
| Deployment | DevOps | Moyenne |
| Workflows | Developpeurs | Basse |

### Output
- Liste des lacunes identifiees
- Priorites definies
- Estimation du travail

---

## Etape 2: Ecrire la Documentation

### Objectif
Rediger ou mettre a jour le contenu documentaire.

### Checklist

- [ ] Choisir le fichier cible
- [ ] Utiliser le bon template
- [ ] Ecrire en francais clair et concis
- [ ] Inclure des exemples de code
- [ ] Ajouter des diagrammes si utile

### Conventions de style

```markdown
## Style d'ecriture

1. Langue: Francais sans accents (compatibilite ASCII)
2. Ton: Professionnel mais accessible
3. Structure: Hierarchique avec titres clairs
4. Exemples: Toujours inclure du code fonctionnel
5. Longueur: Concis mais complet

## Format Markdown

- Titres: # pour titre principal, ## pour sections
- Code inline: `code`
- Blocs de code: ```language
- Listes: - pour non ordonnees, 1. pour ordonnees
- Tableaux: | Col1 | Col2 |
- Citations: > texte
- Checkboxes: - [ ] item
```

### Template: Documentation de Feature

```markdown
# [Nom de la Feature]

## Vue d'ensemble
[Description en 2-3 phrases]

## Cas d'usage
- [Cas 1]
- [Cas 2]

## Architecture

### Collections Appwrite
| Collection | Usage |
|------------|-------|
| [nom] | [description] |

### Models Dart
- `[Name]Model` - [description]

## Utilisation

### Exemple basique
\`\`\`dart
// Code exemple
\`\`\`

### Exemple avance
\`\`\`dart
// Code exemple
\`\`\`

## Configuration
[Parametres configurables]

## Limitations connues
- [Limitation 1]
- [Limitation 2]

## Voir aussi
- [Lien vers doc associee]
```

### Template: Documentation d'API

```markdown
# [Endpoint/Collection]

## Description
[Description de l'endpoint ou collection]

## Schema

### Attributs
| Attribut | Type | Requis | Description |
|----------|------|--------|-------------|
| id | String | Oui | Identifiant unique |
| [attr] | [type] | [oui/non] | [description] |

### Permissions
| Action | Permission |
|--------|------------|
| Create | [users/role:all/...] |
| Read | [users/any/...] |
| Update | [user:{userId}/...] |
| Delete | [user:{userId}/...] |

## Exemples

### Creer
\`\`\`dart
final doc = await databases.createDocument(
  databaseId: 'fug_database',
  collectionId: '[collection]',
  documentId: ID.unique(),
  data: {...},
);
\`\`\`

### Lire
\`\`\`dart
final doc = await databases.getDocument(
  databaseId: 'fug_database',
  collectionId: '[collection]',
  documentId: id,
);
\`\`\`

## Erreurs courantes
| Code | Message | Solution |
|------|---------|----------|
| 404 | Document not found | Verifier l'ID |
```

### Template: Documentation Technique

```markdown
# [Sujet Technique]

## Contexte
[Pourquoi cette approche/technologie]

## Architecture

\`\`\`
[Diagramme ASCII]
\`\`\`

## Implementation

### Prerequis
- [Prerequis 1]
- [Prerequis 2]

### Etapes
1. [Etape 1]
2. [Etape 2]

### Code
\`\`\`dart
// Implementation
\`\`\`

## Configuration
| Variable | Description | Defaut |
|----------|-------------|--------|
| [var] | [desc] | [val] |

## Troubleshooting
### Probleme: [description]
**Solution**: [solution]

## References
- [Lien externe 1]
- [Lien externe 2]
```

---

## Etape 3: Reviewer la Documentation

### Objectif
Valider la qualite et l'exactitude de la documentation.

### Checklist de review

- [ ] Contenu techniquement exact
- [ ] Exemples de code fonctionnels
- [ ] Pas de fautes d'orthographe
- [ ] Structure claire et logique
- [ ] Liens fonctionnels
- [ ] Format Markdown correct

### Questions de validation

```markdown
1. Clarte
   - [ ] Un nouveau developpeur comprendrait-il?
   - [ ] Les termes techniques sont-ils expliques?
   - [ ] La structure est-elle logique?

2. Exactitude
   - [ ] Le code fonctionne-t-il?
   - [ ] Les informations sont-elles a jour?
   - [ ] Les exemples sont-ils corrects?

3. Completude
   - [ ] Tous les cas d'usage sont-ils couverts?
   - [ ] Les erreurs courantes sont-elles mentionnees?
   - [ ] Les limitations sont-elles documentees?
```

### Process de review

1. **Auto-review**
   - Relire apres une pause
   - Tester les exemples de code
   - Verifier les liens

2. **Peer review**
   - Demander a un collegue de relire
   - Integrer le feedback
   - Valider les corrections

3. **Validation technique**
   - Faire tester par quelqu'un qui ne connait pas le sujet
   - Corriger les points de confusion

---

## Etape 4: Mettre a Jour les References

### Objectif
Assurer la coherence des liens et references croisees.

### Checklist

- [ ] Mettre a jour `docs/index.md` avec les nouveaux liens
- [ ] Verifier les liens internes dans tous les docs
- [ ] Ajouter des "Voir aussi" pertinents
- [ ] Mettre a jour la table des matieres si existe
- [ ] Verifier les liens externes

### Structure des liens

```markdown
## Liens internes
[Architecture](./architecture.md)
[Regles metier](./business-rules.md)

## Liens vers code
Voir [`UserModel`](../app/lib/features/user/domain/user_model.dart)

## Liens externes
[Documentation Appwrite](https://appwrite.io/docs)
[Flutter Docs](https://docs.flutter.dev)
```

### Verification des liens

```bash
# Trouver les liens casses (manuel)
grep -r "\[.*\](.*)" docs/ | grep -v "http"

# Verifier les fichiers references
ls -la docs/
```

### Template: Index de documentation

```markdown
# Documentation FUG

## Pour commencer
- [Vue d'ensemble](./index.md)
- [Architecture](./architecture.md)

## Developpement
- [Regles metier](./business-rules.md)
- [API Reference](./api-reference.md)

## Operations
- [Deploiement](./deployment.md)

## BMAD
- [Project Brief](./_bmad/project-brief.md)
- [Workflows](./_bmad/workflows/)
```

---

## Checklist Finale

### Qualite du contenu
- [ ] Information exacte et a jour
- [ ] Exemples fonctionnels testes
- [ ] Structure claire et logique
- [ ] Pas de fautes

### Integration
- [ ] Liens internes fonctionnels
- [ ] References croisees ajoutees
- [ ] Index mis a jour
- [ ] Navigation coherente

### Process
- [ ] Review effectue
- [ ] Feedback integre
- [ ] PR cree si necessaire

---

## Types de Documentation FUG

### Documentation technique
- Architecture systeme
- Schemas de base de donnees
- API reference
- **Audience**: Developpeurs

### Documentation fonctionnelle
- Regles metier
- User flows
- Specifications
- **Audience**: Developpeurs, PO

### Documentation operationnelle
- Guide de deploiement
- Configuration environnements
- Troubleshooting
- **Audience**: DevOps, Developpeurs

### Documentation BMAD
- Project brief
- Workflows
- Context files
- **Audience**: Agents IA, Developpeurs

---

## Bonnes Pratiques

### Do's
- Documenter au fur et a mesure
- Inclure des exemples concrets
- Maintenir la documentation avec le code
- Utiliser des diagrammes quand utile
- Privilegier la clarte a l'exhaustivite

### Don'ts
- Ne pas dupliquer l'information
- Ne pas documenter le "comment" evident
- Ne pas laisser de TODOs permanents
- Ne pas utiliser de jargon non explique
- Ne pas negliger la mise a jour

---

*Workflow BMAD-METHOD pour FUG - v1.0*
