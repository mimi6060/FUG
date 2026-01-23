# UX-001: Champ "Type de lieu" optionnel pour les FUG

## Contexte

Une FUG est un événement simple : "je bois ici, rejoignez-moi". Les anciennes catégories (sport, musique, tech...) n'ont pas de sens dans ce contexte.

## User Story

**En tant qu'** utilisateur créant une FUG,
**Je veux** pouvoir optionnellement indiquer le type de lieu,
**Afin de** permettre aux autres utilisateurs de filtrer/visualiser par type de lieu.

## Critères d'acceptation

- [x] Le champ "Catégorie" est renommé en "Type de lieu"
- [x] Les valeurs disponibles sont : Bar, Café, Restaurant, Parc, Maison, Autre
- [x] Le champ est optionnel (non obligatoire)
- [x] Les traductions sont disponibles en FR, EN, NL, DE
- [x] La base de données accepte une valeur null pour ce champ

## Changements techniques

### Fichiers modifiés

1. **Localisations** (`app/lib/l10n/app_*.arb`)
   - Supprimé : `categorySport`, `categoryMusic`, etc.
   - Ajouté : `locationType`, `locationTypeOptional`, `locationTypeBar`, `locationTypeCafe`, `locationTypeRestaurant`, `locationTypePark`, `locationTypeHome`, `locationTypeOther`

2. **Écran de création** (`app/lib/features/events/presentation/create_event_screen.dart`)
   - `_selectedCategory` → `_selectedLocationType` (nullable)
   - `_getCategories()` → `_getLocationTypes()`
   - Dropdown utilise `locationTypeOptional` comme label
   - Icône changée de `Icons.category` à `Icons.place`

3. **Repository** (`app/lib/features/events/data/event_repository.dart`)
   - Paramètre `categoryId` → `locationType` (nullable)
   - Le champ DB reste `category` pour compatibilité

### Migration existante

La migration `026_fix_event_categories.js` a déjà mis à jour les valeurs enum dans la base de données :
- Anciennes : `sport, music, food, tech, art, social, education, other`
- Nouvelles : `bar, cafe, restaurant, park, home, other`

## Priorité

Moyenne - Amélioration UX

## Estimation

Complété - 1h

## Statut

**DONE** - 2026-01-23
