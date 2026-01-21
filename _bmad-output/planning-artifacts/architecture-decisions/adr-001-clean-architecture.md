# ADR-001: Adoption de Clean Architecture

> Architecture Decision Record

## Informations

| Champ | Valeur |
|-------|--------|
| **ID** | ADR-001 |
| **Statut** | Accepte |
| **Date** | Janvier 2026 |
| **Decideurs** | The Develobeers |

---

## Contexte

Le projet FUG est une application mobile Flutter avec un backend Appwrite. L'application doit etre:
- Maintenable sur le long terme
- Testable de maniere isolee
- Evoluable avec de nouvelles fonctionnalites
- Comprehensible pour les nouveaux developpeurs

Plusieurs patterns architecturaux existent pour les applications Flutter:
- MVC (Model-View-Controller)
- MVVM (Model-View-ViewModel)
- Clean Architecture
- BLoC Pattern simple

---

## Decision

Nous adoptons **Clean Architecture** adaptee a Flutter, organisee par features avec trois couches distinctes:

### Structure adoptee

```
lib/
├── core/                    # Services et configuration partages
│   ├── config/              # Configuration Appwrite, environnements
│   ├── constants/           # Constantes applicatives
│   ├── errors/              # Gestion des erreurs
│   ├── services/            # Services techniques (Appwrite, Location)
│   └── providers/           # Providers Riverpod globaux
│
├── features/                # Features organisees par domaine
│   ├── auth/
│   │   ├── data/            # Repositories (implementation)
│   │   ├── domain/          # Models, interfaces
│   │   └── presentation/    # Screens, widgets, providers
│   │
│   ├── events/
│   ├── profile/
│   ├── notifications/
│   └── gamification/
│
└── main.dart
```

### Couches

1. **Presentation Layer**
   - Screens (pages de l'application)
   - Widgets (composants reutilisables)
   - Providers (gestion d'etat avec Riverpod)

2. **Domain Layer**
   - Models (classes de donnees avec Equatable)
   - Repository Interfaces (contrats abstraits)
   - Business logic pure

3. **Data Layer**
   - Repository Implementations
   - Data Sources (interaction avec Appwrite)
   - Mapping JSON <-> Models

---

## Justification

### Avantages de Clean Architecture

1. **Separation des responsabilites**
   - Chaque couche a un role precis
   - Facilite la comprehension du code
   - Reduit le couplage

2. **Testabilite**
   - Domain layer testable sans dependencies externes
   - Mocking facile des repositories
   - Tests unitaires isoles

3. **Maintenabilite**
   - Changement de backend sans impact sur la presentation
   - Evolution des features independamment
   - Refactoring securise

4. **Onboarding**
   - Structure predictible
   - Documentation par convention
   - Patterns reconnus dans l'industrie

### Adaptation a Flutter

Clean Architecture originelle est pensee pour des langages orientes objet traditionnels. Notre adaptation:
- **Pas de Use Cases separes**: Trop verbose pour une app mobile, la logique reste dans les repositories
- **Feature-first**: Organisation par domaine metier plutot que par couche technique
- **Riverpod comme DI**: Injection de dependances via providers plutot que conteneur IoC

---

## Alternatives Considerees

### 1. MVC Simple

**Avantages:**
- Plus simple a mettre en place
- Moins de boilerplate

**Inconvenients:**
- Controllers deviennent monolithiques
- Testabilite reduite
- Couplage fort View-Model

**Raison du rejet:** Ne scale pas pour une application complexe avec geolocalisation et gamification.

### 2. BLoC Pattern Seul

**Avantages:**
- Pattern populaire en Flutter
- Separation reactive claire

**Inconvenients:**
- Boilerplate important (events, states)
- Pas de structure pour data layer
- Courbe d'apprentissage

**Raison du rejet:** Riverpod offre les memes benefices avec moins de boilerplate.

### 3. Clean Architecture Stricte

**Avantages:**
- Separation maximale
- Use Cases explicites

**Inconvenients:**
- Trop de fichiers et classes
- Over-engineering pour une app mobile
- Ralentit le developpement

**Raison du rejet:** Version adaptee plus pragmatique pour Flutter.

---

## Consequences

### Positives

- Code organise et predictible
- Nouveaux developpeurs operationnels rapidement
- Tests unitaires facilites
- Refactoring backend possible sans impact UI

### Negatives

- Plus de fichiers que MVC simple
- Necessite discipline pour maintenir la structure
- Courbe d'apprentissage initiale

### Neutres

- Documentation a maintenir
- Revue de code pour verifier les patterns

---

## Exemples d'Implementation

### Repository Pattern

```dart
// domain/auth_repository_interface.dart (optionnel)
abstract class IAuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> signIn(String email, String password);
}

// data/auth_repository.dart
class AuthRepository implements IAuthRepository {
  final AppwriteService _appwrite;

  @override
  Future<UserModel?> getCurrentUser() async {
    final doc = await _appwrite.databases.getDocument(...);
    return UserModel.fromJson(doc.data);
  }
}
```

### Provider Pattern

```dart
// presentation/providers/auth_provider.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getCurrentUser();
});
```

### Screen avec Riverpod

```dart
// presentation/screens/login_screen.dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: authState.when(
        data: (user) => user != null ? HomeScreen() : LoginForm(),
        loading: () => CircularProgressIndicator(),
        error: (e, _) => ErrorWidget(e),
      ),
    );
  }
}
```

---

## References

- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Clean Architecture - Reso Coder](https://resocoder.com/category/tutorials/flutter/tdd-clean-architecture/)
- [Riverpod Documentation](https://riverpod.dev)

---

## Revision

| Date | Modification | Auteur |
|------|--------------|--------|
| Janvier 2026 | Creation initiale | The Develobeers |

---

*Document genere pour le projet FUG - The Develobeers*
