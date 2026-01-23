# Workflow: Ajouter une Feature FUG

> Workflow personnalise BMAD pour l'ajout de nouvelles fonctionnalites au projet FUG

## Vue d'Ensemble

Ce workflow guide l'implementation complete d'une nouvelle feature dans l'application FUG, en suivant les principes de Clean Architecture et les conventions du projet.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     WORKFLOW: ADD-FUG-FEATURE                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. ANALYSE        2. DATABASE       3. MODEL         4. REPOSITORY    │
│  ┌─────────┐       ┌─────────┐       ┌─────────┐      ┌─────────┐      │
│  │ Specs & │  ───► │Migration│  ───► │  Dart   │ ───► │  Data   │      │
│  │ Impact  │       │ Appwrite│       │  Model  │      │  Layer  │      │
│  └─────────┘       └─────────┘       └─────────┘      └─────────┘      │
│                                                              │          │
│                                                              ▼          │
│  6. DOCS           5. TESTS          4. UI                              │
│  ┌─────────┐       ┌─────────┐       ┌─────────┐                        │
│  │Document │  ◄─── │  Write  │  ◄─── │ Screen  │                        │
│  │  Code   │       │  Tests  │       │ Widget  │                        │
│  └─────────┘       └─────────┘       └─────────┘                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Etape 1: Analyse et Specifications

### Objectif
Comprendre la feature et evaluer son impact sur le systeme existant.

### Checklist

- [ ] Lire la user story ou le ticket associe
- [ ] Identifier les collections Appwrite impactees
- [ ] Verifier si une Appwrite Function est necessaire
- [ ] Lister les ecrans UI a creer/modifier
- [ ] Evaluer l'impact sur les features existantes
- [ ] Estimer la complexite (S/M/L/XL)

### Questions a se poser

```markdown
1. Cette feature necessite-t-elle:
   - [ ] Une nouvelle collection Appwrite?
   - [ ] De nouveaux attributs sur une collection existante?
   - [ ] Une nouvelle Appwrite Function?
   - [ ] Des notifications push?
   - [ ] Du realtime?
   - [ ] De la geolocalisation?

2. Quels composants existants sont impactes?
   - [ ] Models
   - [ ] Repositories
   - [ ] Providers
   - [ ] Screens

3. Y a-t-il des dependances avec d'autres features?
```

### Output
Document de specs rapide avec:
- Description de la feature
- Collections/attributs impactes
- Estimation de la complexite
- Risques identifies

---

## Etape 2: Migration Database (si necessaire)

### Objectif
Mettre a jour le schema de base de donnees Appwrite.

### Checklist pour nouvelle collection

- [ ] Definir les attributs avec leurs types
- [ ] Configurer les index necessaires
- [ ] Definir les permissions (CRUD)
- [ ] Creer la collection via Appwrite Console ou CLI

### Checklist pour modification de collection

- [ ] Identifier les attributs a ajouter/modifier
- [ ] Verifier la retrocompatibilite
- [ ] Ajouter les nouveaux attributs
- [ ] Mettre a jour les index si necessaire

### Template: Nouvelle Collection

```yaml
Collection: [nom_collection]
Database: fug_database

Attributs:
  - name: [attribut1]
    type: String/Integer/Boolean/DateTime/Spatial
    required: true/false
    size: [pour String]
    default: [valeur par defaut]

  - name: [attribut2]
    ...

Indexes:
  - name: idx_[nom]
    type: Key/Unique/Fulltext
    attributes: [liste]
    orders: [ASC/DESC]

Permissions:
  Create: users / role:all / user:{userId}
  Read: users / any / user:{userId}
  Update: user:{userId} / role:admin
  Delete: user:{userId} / role:admin
```

### Commandes CLI utiles

```bash
# Deployer les modifications
appwrite deploy collection

# Verifier le schema
appwrite databases listCollections --databaseId fug_database
```

---

## Etape 3: Model Dart

### Objectif
Creer ou mettre a jour le model Dart correspondant.

### Emplacement
```
app/lib/features/[feature_name]/domain/[name]_model.dart
```

### Template: Model complet

```dart
import 'package:equatable/equatable.dart';

/// Model representant [description]
///
/// Stocke dans la collection '[collection_name]' d'Appwrite.
class [Name]Model extends Equatable {
  /// ID unique
  final String id;

  /// [Description attribut]
  final String field1;

  /// [Description attribut]
  final int? field2;

  /// Date de creation
  final DateTime createdAt;

  /// Date de derniere modification
  final DateTime updatedAt;

  const [Name]Model({
    required this.id,
    required this.field1,
    this.field2,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cree un [Name]Model a partir d'un document Appwrite
  factory [Name]Model.fromJson(Map<String, dynamic> json) {
    return [Name]Model(
      id: json['\$id'] as String,
      field1: json['field1'] as String,
      field2: json['field2'] as int?,
      createdAt: DateTime.parse(json['\$createdAt'] as String),
      updatedAt: DateTime.parse(json['\$updatedAt'] as String),
    );
  }

  /// Convertit en Map pour Appwrite
  Map<String, dynamic> toJson() {
    return {
      'field1': field1,
      'field2': field2,
    };
  }

  /// Cree une copie avec des valeurs modifiees
  [Name]Model copyWith({
    String? id,
    String? field1,
    int? field2,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return [Name]Model(
      id: id ?? this.id,
      field1: field1 ?? this.field1,
      field2: field2 ?? this.field2,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, field1, field2, createdAt, updatedAt];

  @override
  String toString() => '[Name]Model(id: $id, field1: $field1)';
}
```

### Checklist Model

- [ ] Heriter de `Equatable`
- [ ] Tous les champs documentes avec `///`
- [ ] Factory `fromJson` avec gestion des types nullable
- [ ] Methode `toJson` (sans $id, $createdAt, $updatedAt)
- [ ] Methode `copyWith`
- [ ] Override `props` pour Equatable
- [ ] Override `toString` pour debug

---

## Etape 4: Repository

### Objectif
Implementer la couche data pour interagir avec Appwrite.

### Emplacement
```
app/lib/features/[feature_name]/data/[name]_repository.dart
```

### Template: Repository

```dart
import 'package:appwrite/appwrite.dart';
import '../domain/[name]_model.dart';

/// Repository pour la gestion des [description]
class [Name]Repository {
  final Databases _databases;

  [Name]Repository(this._databases);

  static const String _databaseId = 'fug_database';
  static const String _collectionId = '[collection_name]';

  /// Recupere un [name] par son ID
  Future<[Name]Model> getById(String id) async {
    try {
      final document = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
      return [Name]Model.fromJson(document.data);
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  /// Recupere tous les [names] avec pagination
  Future<List<[Name]Model>> getAll({
    int limit = 25,
    int offset = 0,
    List<String>? queries,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _collectionId,
        queries: [
          Query.limit(limit),
          Query.offset(offset),
          ...?queries,
        ],
      );
      return response.documents
          .map((doc) => [Name]Model.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cree un nouveau [name]
  Future<[Name]Model> create([Name]Model model) async {
    try {
      final document = await _databases.createDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: ID.unique(),
        data: model.toJson(),
      );
      return [Name]Model.fromJson(document.data);
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  /// Met a jour un [name] existant
  Future<[Name]Model> update(String id, Map<String, dynamic> data) async {
    try {
      final document = await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
        data: data,
      );
      return [Name]Model.fromJson(document.data);
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  /// Supprime un [name]
  Future<void> delete(String id) async {
    try {
      await _databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _collectionId,
        documentId: id,
      );
    } on AppwriteException catch (e) {
      throw _handleError(e);
    }
  }

  /// Gere les erreurs Appwrite
  Exception _handleError(AppwriteException e) {
    // TODO: Implementer la gestion d'erreurs personnalisee
    return Exception('Erreur Appwrite: ${e.message}');
  }
}
```

### Checklist Repository

- [ ] Injection de `Databases` via constructeur
- [ ] Constantes pour databaseId et collectionId
- [ ] CRUD complet (getById, getAll, create, update, delete)
- [ ] Gestion des erreurs Appwrite
- [ ] Pagination avec limit/offset
- [ ] Documentation des methodes

---

## Etape 5: UI (Screen & Widgets)

### Objectif
Creer l'interface utilisateur de la feature.

### Emplacement
```
app/lib/features/[feature_name]/presentation/
  ├── screens/
  │   └── [name]_screen.dart
  ├── widgets/
  │   └── [name]_widget.dart
  └── providers/
      └── [name]_provider.dart
```

### Template: Screen avec Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ecran principal pour [description]
class [Name]Screen extends ConsumerWidget {
  const [Name]Screen({super.key});

  static const String routeName = '/[route-name]';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final state = ref.watch([name]Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('[Titre]'),
      ),
      body: const Center(
        child: Text('TODO: Implementer [Name]Screen'),
      ),
    );
  }
}
```

### Template: Provider Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/[name]_repository.dart';
import '../domain/[name]_model.dart';

/// Provider pour le repository
final [name]RepositoryProvider = Provider<[Name]Repository>((ref) {
  final databases = ref.watch(databasesProvider);
  return [Name]Repository(databases);
});

/// Provider pour recuperer un [name] par ID
final [name]Provider = FutureProvider.family<[Name]Model, String>(
  (ref, id) async {
    final repository = ref.watch([name]RepositoryProvider);
    return repository.getById(id);
  },
);

/// Provider pour la liste des [names]
final [name]ListProvider = FutureProvider<List<[Name]Model>>((ref) async {
  final repository = ref.watch([name]RepositoryProvider);
  return repository.getAll();
});
```

### Checklist UI

- [ ] Screen avec `ConsumerWidget` ou `ConsumerStatefulWidget`
- [ ] Route definie dans GoRouter
- [ ] Providers Riverpod pour l'etat
- [ ] Loading state
- [ ] Error state
- [ ] Empty state
- [ ] UI responsive

---

## Etape 6: Tests

### Objectif
Assurer la qualite avec des tests automatises.

### Emplacement
```
app/test/
  ├── unit/
  │   └── [name]_model_test.dart
  │   └── [name]_repository_test.dart
  └── widget/
      └── [name]_screen_test.dart
```

### Template: Test Model

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fug_app/features/[feature]/domain/[name]_model.dart';

void main() {
  group('[Name]Model', () {
    const testJson = {
      '\$id': 'test-id',
      'field1': 'value1',
      'field2': 42,
      '\$createdAt': '2026-01-01T00:00:00.000Z',
      '\$updatedAt': '2026-01-01T00:00:00.000Z',
    };

    test('fromJson creates valid model', () {
      final model = [Name]Model.fromJson(testJson);

      expect(model.id, 'test-id');
      expect(model.field1, 'value1');
      expect(model.field2, 42);
    });

    test('toJson creates valid map', () {
      final model = [Name]Model.fromJson(testJson);
      final json = model.toJson();

      expect(json['field1'], 'value1');
      expect(json['field2'], 42);
      expect(json.containsKey('\$id'), false);
    });

    test('copyWith creates modified copy', () {
      final model = [Name]Model.fromJson(testJson);
      final copy = model.copyWith(field1: 'new-value');

      expect(copy.field1, 'new-value');
      expect(copy.field2, model.field2);
      expect(copy.id, model.id);
    });

    test('equality works correctly', () {
      final model1 = [Name]Model.fromJson(testJson);
      final model2 = [Name]Model.fromJson(testJson);

      expect(model1, equals(model2));
    });
  });
}
```

### Checklist Tests

- [ ] Tests unitaires Model (fromJson, toJson, copyWith, equality)
- [ ] Tests unitaires Repository (mock Databases)
- [ ] Tests widget Screen (golden tests optionnels)
- [ ] Coverage >= 80%

### Commandes

```bash
# Lancer tous les tests
flutter test

# Avec coverage
flutter test --coverage

# Un fichier specifique
flutter test test/unit/[name]_model_test.dart
```

---

## Etape 7: Documentation

### Objectif
Documenter le code et mettre a jour la documentation projet.

### Checklist

- [ ] Tous les fichiers publics documentes avec `///`
- [ ] README de la feature si complexe
- [ ] Mise a jour du CHANGELOG si version
- [ ] Mise a jour du context project BMAD si necessaire

### Template: Documentation classe

```dart
/// Repository pour la gestion des [entites].
///
/// Fournit les operations CRUD pour interagir avec la collection
/// '[collection_name]' d'Appwrite.
///
/// ## Exemple d'utilisation
///
/// ```dart
/// final repository = [Name]Repository(databases);
/// final items = await repository.getAll();
/// ```
///
/// ## Voir aussi
///
/// * [[Name]Model] - Le model associe
/// * [[Name]Provider] - Provider Riverpod pour l'etat
class [Name]Repository {
  // ...
}
```

---

## Checklist Finale

Avant de considerer la feature comme terminee:

### Code
- [ ] Code compile sans erreur
- [ ] Pas de warnings lint
- [ ] Conventions de nommage respectees
- [ ] Code documente

### Tests
- [ ] Tests unitaires passent
- [ ] Tests widget passent
- [ ] Coverage >= 80%

### Fonctionnel
- [ ] Feature fonctionne en dev
- [ ] Cas nominaux testes manuellement
- [ ] Cas d'erreur geres

### Integration
- [ ] Pull Request cree
- [ ] Code review demande
- [ ] CI passe

---

## Exemples de Features

### Feature Simple (S)
- Ajouter un champ au profil utilisateur
- ~2-4h de travail
- 1-2 fichiers modifies

### Feature Moyenne (M)
- Nouveau type de notification
- ~1-2 jours de travail
- 3-5 fichiers modifies/crees

### Feature Large (L)
- Systeme de commentaires
- ~3-5 jours de travail
- Nouvelle collection + UI complete

### Feature XL
- Chat entre participants
- ~1-2 semaines
- Plusieurs collections + Functions + Realtime

---

*Workflow BMAD-METHOD pour FUG - v1.0*
