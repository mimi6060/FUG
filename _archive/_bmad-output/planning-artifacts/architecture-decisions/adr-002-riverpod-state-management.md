# ADR-002: Riverpod pour la Gestion d'Etat

> Architecture Decision Record

## Informations

| Champ | Valeur |
|-------|--------|
| **ID** | ADR-002 |
| **Statut** | Accepte |
| **Date** | Janvier 2026 |
| **Decideurs** | The Develobeers |

---

## Contexte

Une application Flutter necessite une solution de gestion d'etat pour:
- Partager des donnees entre widgets
- Reagir aux changements de donnees
- Gerer les etats de chargement et d'erreur
- Injecter les dependances (repositories, services)

FUG a des besoins specifiques:
- Etat d'authentification global
- Liste d'evenements avec filtres et pagination
- Position geographique en temps reel
- Score de gamification actualise
- Notifications en temps reel

Plusieurs solutions de state management existent dans l'ecosysteme Flutter.

---

## Decision

Nous adoptons **Riverpod 2.x** comme solution unique de gestion d'etat et d'injection de dependances.

### Providers utilises

```dart
// Provider simple - valeur synchrone
final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService.instance;
});

// FutureProvider - valeur asynchrone
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

// StreamProvider - flux temps reel
final locationProvider = StreamProvider<Position>((ref) {
  return Geolocator.getPositionStream();
});

// StateNotifierProvider - etat mutable complexe
final eventsFilterProvider = StateNotifierProvider<EventsFilterNotifier, EventsFilter>((ref) {
  return EventsFilterNotifier();
});

// AsyncNotifierProvider (Riverpod 2.0+) - recommande
final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<EventModel>>(() {
  return EventsNotifier();
});
```

---

## Justification

### Avantages de Riverpod

1. **Compile-time safety**
   - Pas de runtime errors comme Provider
   - Erreurs detectees a la compilation
   - Autocompletion complete

2. **Independance du BuildContext**
   - Providers accessibles partout
   - Tests simplifies
   - Pas de Provider.of(context)

3. **Combine les patterns**
   - Injection de dependances
   - State management
   - Caching et invalidation

4. **Performance optimisee**
   - Rebuilds granulaires
   - Auto-dispose des ressources
   - Lazy initialization

5. **DevTools integration**
   - Visualisation des providers
   - Debug facilite
   - Historique des etats

### Usage dans FUG

| Cas d'usage | Type de Provider | Exemple |
|-------------|------------------|---------|
| Services singleton | Provider | `appwriteServiceProvider` |
| Repositories | Provider | `authRepositoryProvider` |
| Donnees chargees | FutureProvider | `currentUserProvider` |
| Position GPS | StreamProvider | `locationProvider` |
| Filtres UI | StateNotifierProvider | `eventsFilterProvider` |
| Liste paginee | AsyncNotifierProvider | `eventsProvider` |

---

## Alternatives Considerees

### 1. Provider (package provider)

**Avantages:**
- Simple a apprendre
- Recommande par Flutter team
- Grande communaute

**Inconvenients:**
- Runtime errors possibles
- Necessite BuildContext
- Pas de gestion async native
- ChangeNotifier verbose

**Raison du rejet:** Riverpod est le successeur de Provider par le meme auteur, avec toutes les ameliorations.

### 2. BLoC (flutter_bloc)

**Avantages:**
- Tres populaire
- Pattern reconnu
- Separation claire Events/States

**Inconvenients:**
- Boilerplate important (Event, State, Bloc)
- Courbe d'apprentissage elevee
- Pas d'injection de dependances native
- Un Bloc par feature = beaucoup de fichiers

**Raison du rejet:** Trop de boilerplate pour notre equipe reduite. Riverpod offre les memes benefices avec moins de code.

### 3. GetX

**Avantages:**
- Tout-en-un (routing, DI, state)
- Tres peu de boilerplate
- Performance

**Inconvenients:**
- Opiniated, difficile a mixer
- Mauvaises pratiques encouragees
- Moins de controle
- Communaute divisee

**Raison du rejet:** Trop magique, cache la complexite, difficile a debugger.

### 4. Redux (flutter_redux)

**Avantages:**
- Pattern prouve (React)
- DevTools excellents
- Predictibilite

**Inconvenients:**
- Tres verbose
- Actions, Reducers, Middleware
- Over-engineering pour mobile
- Pas adapte a Flutter

**Raison du rejet:** Pattern web force sur mobile, trop complexe pour nos besoins.

### 5. MobX

**Avantages:**
- Reactif et simple
- Annotations claires
- Peu de boilerplate

**Inconvenients:**
- Code generation obligatoire
- Moins populaire en Flutter
- Debug moins intuitif

**Raison du rejet:** Code generation ajoute de la complexite, Riverpod plus natif Flutter.

---

## Consequences

### Positives

- Code concis et lisible
- Tests unitaires simplifies (pas de context)
- Gestion automatique du cycle de vie
- Performances optimales par defaut
- Un seul pattern pour DI + state

### Negatives

- Syntaxe specifique a apprendre
- Documentation parfois incomplete
- Breaking changes entre versions
- Necessite Riverpod 2.x (migration si upgrade)

### Neutres

- Formation equipe necessaire
- Conventions a documenter

---

## Patterns Adoptes

### 1. Repository Provider

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final appwrite = ref.watch(appwriteServiceProvider);
  return AuthRepository(appwrite: appwrite);
});
```

### 2. Async State avec AsyncNotifier

```dart
class EventsNotifier extends AsyncNotifier<List<EventModel>> {
  @override
  Future<List<EventModel>> build() async {
    final repo = ref.watch(eventRepositoryProvider);
    return repo.getNearbyEvents(
      latitude: ref.watch(locationProvider).value?.latitude ?? 0,
      longitude: ref.watch(locationProvider).value?.longitude ?? 0,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> createEvent(EventModel event) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.createEvent(event);
    ref.invalidateSelf();
  }
}
```

### 3. Derived State

```dart
final upcomingEventsProvider = Provider<List<EventModel>>((ref) {
  final events = ref.watch(eventsProvider).value ?? [];
  return events.where((e) => e.isUpcoming).toList();
});
```

### 4. Family pour parametres

```dart
final eventDetailProvider = FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEvent(eventId);
});

// Usage
final event = ref.watch(eventDetailProvider('event_123'));
```

---

## Configuration

### pubspec.yaml

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

### main.dart

```dart
void main() {
  runApp(
    ProviderScope(
      child: FugApp(),
    ),
  );
}
```

---

## References

- [Riverpod Documentation](https://riverpod.dev)
- [Riverpod 2.0 Migration Guide](https://riverpod.dev/docs/migration/from_state_notifier)
- [Flutter State Management Comparison](https://docs.flutter.dev/data-and-backend/state-mgmt/options)

---

## Revision

| Date | Modification | Auteur |
|------|--------------|--------|
| Janvier 2026 | Creation initiale | The Develobeers |

---

*Document genere pour le projet FUG - The Develobeers*
