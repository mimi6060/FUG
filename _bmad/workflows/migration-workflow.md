# Workflow: Migration de Schema FUG

> Workflow BMAD pour les modifications de schema de base de donnees Appwrite

## Vue d'Ensemble

Ce workflow guide la creation et l'application de migrations pour modifier le schema de la base de donnees Appwrite.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW: MIGRATION-FUG                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. PLANIFIER       2. CREER             3. TESTER LOCAL               │
│  ┌─────────┐        ┌─────────┐          ┌─────────┐                   │
│  │ Analyser│  ───►  │ Fichier │  ───►    │ Docker  │                   │
│  │ impact  │        │migration│          │  local  │                   │
│  └─────────┘        └─────────┘          └─────────┘                   │
│                                                │                        │
│                                                ▼                        │
│  5. VERIFIER                            4. APPLIQUER                   │
│  ┌─────────┐                            ┌─────────┐                    │
│  │ Valider │  ◄──────────────────────   │ Migrer  │                    │
│  │ schema  │                            │ env cible│                   │
│  └─────────┘                            └─────────┘                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Etape 1: Planifier la Migration

### Objectif
Analyser l'impact de la modification de schema et planifier la migration.

### Checklist

- [ ] Identifier la modification necessaire
- [ ] Verifier la retrocompatibilite
- [ ] Evaluer l'impact sur les donnees existantes
- [ ] Lister les models Dart a mettre a jour
- [ ] Planifier une strategie de rollback

### Questions a se poser

```markdown
1. Type de modification:
   - [ ] Nouvelle collection
   - [ ] Nouvel attribut sur collection existante
   - [ ] Modification d'attribut existant
   - [ ] Nouvel index
   - [ ] Modification de permissions

2. Impact sur les donnees:
   - [ ] Aucune donnee existante
   - [ ] Donnees existantes compatibles
   - [ ] Migration de donnees necessaire
   - [ ] Risque de perte de donnees

3. Retrocompatibilite:
   - [ ] Changement additif (safe)
   - [ ] Changement destructif (attention)
   - [ ] Renommage (migration necessaire)
```

### Matrice de risque

| Modification | Risque | Action |
|--------------|--------|--------|
| Nouvel attribut optionnel | Faible | Migration simple |
| Nouvel attribut requis | Moyen | Valeur par defaut |
| Suppression attribut | Eleve | Migration donnees |
| Changement de type | Eleve | Migration donnees |
| Nouvelle collection | Faible | Migration simple |

### Output
- Plan de migration documente
- Risques identifies
- Strategie de rollback definie

---

## Etape 2: Creer le Fichier de Migration

### Objectif
Creer le fichier de migration dans le bon format.

### Emplacement
```
infrastructure/migrations/migrations/[timestamp]_[description].js
```

### Convention de nommage
```
[YYYYMMDDHHMMSS]_[action]_[objet].js

Exemples:
- 20260121120000_create_collection_messages.js
- 20260121130000_add_field_avatar_to_users.js
- 20260121140000_add_index_location_to_events.js
```

### Checklist

- [ ] Creer le fichier avec le bon timestamp
- [ ] Implementer la fonction `up` (migration)
- [ ] Implementer la fonction `down` (rollback)
- [ ] Ajouter des logs pour le suivi
- [ ] Documenter les changements

### Template: Nouvelle Collection

```javascript
/**
 * Migration: Creer la collection [nom]
 *
 * Description: [description de la collection]
 * Impact: Aucun (nouvelle collection)
 */

import { ID, Permission, Role } from 'node-appwrite';

const DATABASE_ID = 'fug_database';
const COLLECTION_ID = '[collection_name]';

export async function up(databases) {
  console.log('Creating collection:', COLLECTION_ID);

  // Creer la collection
  await databases.createCollection(
    DATABASE_ID,
    COLLECTION_ID,
    '[Collection Name]',
    [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ]
  );

  // Ajouter les attributs
  await databases.createStringAttribute(
    DATABASE_ID,
    COLLECTION_ID,
    'field_name',
    255,          // size
    true,         // required
    null,         // default
    false         // array
  );

  // Ajouter un attribut DateTime
  await databases.createDatetimeAttribute(
    DATABASE_ID,
    COLLECTION_ID,
    'expires_at',
    false,        // required
    null          // default
  );

  // Ajouter un index
  await databases.createIndex(
    DATABASE_ID,
    COLLECTION_ID,
    'idx_field_name',
    'key',
    ['field_name'],
    ['ASC']
  );

  console.log('Collection created successfully');
}

export async function down(databases) {
  console.log('Deleting collection:', COLLECTION_ID);

  await databases.deleteCollection(DATABASE_ID, COLLECTION_ID);

  console.log('Collection deleted successfully');
}
```

### Template: Ajouter un Attribut

```javascript
/**
 * Migration: Ajouter [attribut] a [collection]
 *
 * Description: [description]
 * Impact: Attribut optionnel, pas d'impact sur donnees existantes
 */

const DATABASE_ID = 'fug_database';
const COLLECTION_ID = '[collection_name]';

export async function up(databases) {
  console.log('Adding attribute to:', COLLECTION_ID);

  await databases.createStringAttribute(
    DATABASE_ID,
    COLLECTION_ID,
    'new_field',
    255,
    false,        // optionnel
    '',           // valeur par defaut
    false
  );

  // Attendre que l'attribut soit pret
  await new Promise(resolve => setTimeout(resolve, 2000));

  console.log('Attribute added successfully');
}

export async function down(databases) {
  console.log('Removing attribute from:', COLLECTION_ID);

  await databases.deleteAttribute(
    DATABASE_ID,
    COLLECTION_ID,
    'new_field'
  );

  console.log('Attribute removed successfully');
}
```

### Template: Ajouter un Index

```javascript
/**
 * Migration: Ajouter index [nom] sur [collection]
 *
 * Description: [description]
 * Impact: Performance, pas d'impact sur donnees
 */

const DATABASE_ID = 'fug_database';
const COLLECTION_ID = '[collection_name]';
const INDEX_NAME = 'idx_[name]';

export async function up(databases) {
  console.log('Creating index:', INDEX_NAME);

  await databases.createIndex(
    DATABASE_ID,
    COLLECTION_ID,
    INDEX_NAME,
    'key',              // type: key, unique, fulltext
    ['field1', 'field2'],
    ['ASC', 'ASC']
  );

  console.log('Index created successfully');
}

export async function down(databases) {
  console.log('Deleting index:', INDEX_NAME);

  await databases.deleteIndex(
    DATABASE_ID,
    COLLECTION_ID,
    INDEX_NAME
  );

  console.log('Index deleted successfully');
}
```

---

## Etape 3: Tester Localement

### Objectif
Valider la migration dans l'environnement de developpement local.

### Checklist

- [ ] Demarrer l'infrastructure locale
- [ ] Executer la migration
- [ ] Verifier le schema dans Appwrite Console
- [ ] Tester le rollback
- [ ] Verifier que l'application fonctionne

### Commandes

```bash
# Demarrer l'infrastructure
cd infrastructure
make up

# Executer les migrations
cd migrations
npm install
node migrate.js up --env=development

# Verifier le statut
node migrate.js status --env=development

# Tester le rollback
node migrate.js down --env=development

# Re-appliquer
node migrate.js up --env=development
```

### Verification dans Appwrite Console

1. Acceder a http://localhost/console
2. Naviguer vers Database > fug_database
3. Verifier:
   - [ ] Collection creee/modifiee
   - [ ] Attributs corrects
   - [ ] Index presents
   - [ ] Permissions configurees

---

## Etape 4: Appliquer sur Environnement Cible

### Objectif
Deployer la migration sur l'environnement de test ou production.

### Checklist Pre-Migration

- [ ] Backup de la base de donnees
- [ ] Fenetre de maintenance planifiee (si prod)
- [ ] Equipe informee
- [ ] Plan de rollback pret

### Commandes par Environnement

```bash
# Environnement de test
node migrate.js up --env=test

# Production (avec precautions)
node migrate.js up --env=production
```

### Procedure de Production

```markdown
1. Pre-migration
   - [ ] Creer un backup
   - [ ] Verifier l'espace disque
   - [ ] Communiquer la maintenance

2. Migration
   - [ ] Mettre l'app en maintenance (optionnel)
   - [ ] Executer la migration
   - [ ] Verifier les logs
   - [ ] Valider le schema

3. Post-migration
   - [ ] Tester l'application
   - [ ] Monitorer les erreurs
   - [ ] Retirer le mode maintenance
   - [ ] Communiquer la fin
```

---

## Etape 5: Verifier et Documenter

### Objectif
Valider la migration et mettre a jour la documentation.

### Checklist Verification

- [ ] Schema conforme aux attentes
- [ ] Donnees existantes intactes
- [ ] Application fonctionne correctement
- [ ] Pas d'erreurs dans les logs
- [ ] Performance acceptable

### Checklist Documentation

- [ ] Mettre a jour `docs/architecture.md` si necessaire
- [ ] Mettre a jour les models Dart concernes
- [ ] Ajouter au CHANGELOG
- [ ] Documenter dans le ticket/PR

### Template: Mise a jour Model Dart

Apres une migration, mettre a jour le model correspondant:

```dart
// Avant
class UserModel {
  final String id;
  final String username;
  // ...
}

// Apres (nouvel attribut)
class UserModel {
  final String id;
  final String username;
  final String? avatarUrl;  // Nouvel attribut
  // ...

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['\$id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],  // Nouveau
      // ...
    );
  }
}
```

---

## Checklist Finale

### Avant Merge
- [ ] Migration testee localement
- [ ] Rollback fonctionne
- [ ] Models Dart mis a jour
- [ ] Tests passes
- [ ] Documentation a jour

### Apres Deploiement
- [ ] Migration appliquee sur environnement cible
- [ ] Verification du schema
- [ ] Application fonctionnelle
- [ ] Monitoring des erreurs

---

## Types d'Attributs Appwrite

| Type | Methode | Parametres |
|------|---------|------------|
| String | `createStringAttribute` | size, required, default, array |
| Integer | `createIntegerAttribute` | min, max, required, default, array |
| Float | `createFloatAttribute` | min, max, required, default, array |
| Boolean | `createBooleanAttribute` | required, default, array |
| DateTime | `createDatetimeAttribute` | required, default, array |
| Email | `createEmailAttribute` | required, default, array |
| URL | `createUrlAttribute` | required, default, array |
| IP | `createIpAttribute` | required, default, array |
| Enum | `createEnumAttribute` | elements, required, default, array |
| Relationship | `createRelationshipAttribute` | relatedCollectionId, type, ... |

---

## Troubleshooting

### Erreur: "Attribute already exists"
```bash
# Verifier les attributs existants
appwrite databases listAttributes --databaseId fug_database --collectionId [collection]
```

### Erreur: "Index creation failed"
- Verifier que tous les attributs de l'index existent
- Attendre que les attributs soient "available"

### Migration bloquee
```bash
# Verifier le statut
node migrate.js status --env=development

# Forcer si necessaire (attention)
node migrate.js force-unlock --env=development
```

---

*Workflow BMAD-METHOD pour FUG - v1.0*
