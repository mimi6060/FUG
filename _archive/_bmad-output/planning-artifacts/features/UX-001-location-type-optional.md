# UX-001: Simplification du modèle FUG

## Contexte

Une FUG est un concept simple : "je bois ici, rejoignez-moi". Le modèle doit refléter cette simplicité :
- Pas de catégories complexes (sport, musique, tech...) → juste un type de lieu
- Jamais payant → retrait du concept de prix
- Visibilité contrôlée → notion de FUG privée (future)

---

## Partie 1 : Type de lieu optionnel (DONE)

### User Story

**En tant qu'** utilisateur créant une FUG,
**Je veux** pouvoir optionnellement indiquer le type de lieu,
**Afin de** permettre aux autres de filtrer par type d'endroit.

### Critères d'acceptation

- [x] Le champ "Catégorie" est renommé en "Type de lieu"
- [x] Les valeurs disponibles sont : Bar, Café, Restaurant, Parc, Maison, Autre
- [x] Le champ est optionnel (non obligatoire)
- [x] Les traductions sont disponibles en FR, EN, NL, DE

### Fichiers modifiés

- `app/lib/l10n/app_*.arb` - Nouvelles clés de localisation
- `app/lib/features/events/presentation/create_event_screen.dart`
- `app/lib/features/events/data/event_repository.dart`
- `app/lib/core/providers/events_provider.dart`

---

## Partie 2 : Suppression du prix (DONE)

### User Story

**En tant qu'** utilisateur,
**Je sais qu'une** FUG est toujours gratuite,
**Donc** le concept de prix n'a pas lieu d'être.

### Critères d'acceptation

- [x] Retrait du switch "Événement gratuit" du formulaire
- [x] Retrait du champ prix du formulaire
- [x] Retrait des paramètres `price` et `currency` des méthodes

### Fichiers modifiés

- `app/lib/features/events/presentation/create_event_screen.dart`
- `app/lib/features/events/data/event_repository.dart`
- `app/lib/core/providers/events_provider.dart`

### À faire (cleanup UI)

- [ ] Retirer le filtre "Gratuit uniquement" de la carte (inutile)
- [ ] Retirer l'affichage du prix dans les détails d'événement
- [ ] Retirer l'affichage du prix dans la liste d'événements

---

## Partie 3 : FUG Privée et Cercles (FUTURE)

### Concept

Une FUG peut être :
1. **Publique** - Visible par tous les utilisateurs
2. **Privée** - Visible uniquement par :
   - Les followers acceptés (personnes qu'on suit ET qui nous suivent mutuellement)
   - Les membres d'un même cercle

### Cercles (Circles)

Un cercle est un groupe d'utilisateurs partageant un intérêt commun :
- Étudiants d'une école (ex: "IPSMA", "ENEN", "Carolo")
- Membres d'un club
- Collègues d'une entreprise

#### Fonctionnalités des cercles

1. **Création de cercle**
   - Nom du cercle
   - Description (optionnelle)
   - Visibilité : ouvert (tout le monde peut rejoindre) ou fermé (sur invitation)

2. **Rejoindre un cercle**
   - Cercle ouvert : rejoindre directement
   - Cercle fermé : demander à rejoindre, attendre approbation admin

3. **Rôles dans un cercle**
   - Admin : peut gérer les membres, modifier le cercle
   - Membre : peut voir les FUG du cercle

4. **FUG et cercles**
   - Lors de la création d'une FUG, choisir la visibilité :
     - Publique
     - Followers uniquement
     - Cercle(s) spécifique(s)
     - Combinaison (followers + cercles)

### Schéma de données (proposition)

```
Collection: circles
- id: string
- name: string
- description: string?
- creatorId: string
- visibility: enum (open, closed)
- memberCount: int
- createdAt: datetime

Collection: circle_members
- id: string
- circleId: string
- userId: string
- role: enum (admin, member)
- joinedAt: datetime

Collection: events (ajouts)
- visibility: enum (public, followers, circles)
- allowedCircles: string[] (IDs des cercles autorisés)
```

### User Stories (futures)

**US-CIRCLE-001**: En tant qu'utilisateur, je veux créer un cercle pour regrouper mes amis proches.

**US-CIRCLE-002**: En tant qu'utilisateur, je veux rejoindre un cercle existant pour voir les FUG de ce groupe.

**US-CIRCLE-003**: En tant que créateur de FUG, je veux pouvoir limiter la visibilité de ma FUG à mes followers ou à certains cercles.

**US-CIRCLE-004**: En tant qu'admin de cercle, je veux pouvoir accepter ou refuser les demandes d'adhésion.

---

## Statut

| Partie | Statut |
|--------|--------|
| Type de lieu optionnel | DONE |
| Suppression du prix | DONE |
| FUG Privée et Cercles | PLANNED |

**Date**: 2026-01-23
