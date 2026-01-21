# MOD-007: Integrations Modernes

> **Priorite:** MOYENNE
> **Phase:** 3 - Nouvelles Fonctionnalites
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Integrer les plateformes et services modernes pour ameliorer la viralite et l'experience utilisateur.

## Integrations Prioritaires

### 1. Partage WhatsApp (Priorite: Haute)

**Pourquoi:** 2B+ utilisateurs, standard de communication

```dart
// Partage d'un evenement via WhatsApp
void shareToWhatsApp(Event event) {
  final text = '''
Je participe a "${event.title}" !
${event.venue ?? event.address}
${event.startsAt.format('dd/MM a HH:mm')}

Rejoins-moi sur FUG: https://fug.app/event/${event.id}
''';

  final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
  launchUrl(Uri.parse(url));
}
```

### 2. Partage Instagram Stories (Priorite: Moyenne)

**Pourquoi:** Viralite visuelle, audience jeune

```dart
// Generer image pour story Instagram
Future<void> shareToInstagramStory(Event event) async {
  // 1. Generer image avec branding FUG
  final image = await _generateEventCard(event);

  // 2. Sauvegarder temporairement
  final tempFile = await _saveToTemp(image);

  // 3. Partager via Instagram
  await Share.shareXFiles(
    [XFile(tempFile.path)],
    text: 'Rejoins-moi sur FUG !',
  );
}
```

### 3. Export Calendrier (Priorite: Haute)

**Pourquoi:** Ne pas oublier ses FUG

```dart
// Ajouter au calendrier natif
Future<void> addToCalendar(Event event) async {
  final calendarEvent = CalendarEvent(
    title: 'FUG: ${event.title}',
    description: event.description,
    location: event.address,
    startDate: event.startsAt,
    endDate: event.endsAt ?? event.startsAt.add(Duration(hours: 3)),
  );

  await Add2Calendar.addEvent2Cal(calendarEvent);
}
```

### 4. Integration Transport (Priorite: Basse - V2)

**Pourquoi:** Securite (pas de conduite en etat d'ivresse)

```dart
// Deep link vers Uber/Bolt
void openRideShare(Event event) {
  final destination = '${event.latitude},${event.longitude}';

  // Uber
  final uberUrl = 'uber://?action=setPickup&dropoff[latitude]=${event.latitude}&dropoff[longitude]=${event.longitude}';

  // Bolt
  final boltUrl = 'bolt://ride?destination=${event.address}';

  // Afficher choix utilisateur
  showModalBottomSheet(
    context: context,
    builder: (_) => RideSharePicker(
      uberUrl: uberUrl,
      boltUrl: boltUrl,
    ),
  );
}
```

---

## User Stories

### US-INT-01: Partage WhatsApp
- Points: 3
- Priorite: Should

### US-INT-02: Partage Instagram
- Points: 5
- Priorite: Could

### US-INT-03: Export Calendrier
- Points: 3
- Priorite: Should

### US-INT-04: Integration Transport
- Points: 5
- Priorite: Won't (V2)

---

## Definition of Done

- [ ] WhatsApp partage fonctionne iOS/Android
- [ ] Instagram partage fonctionne
- [ ] Calendrier export fonctionne
- [ ] Tests sur devices reels
- [ ] Analytics de partage en place

---

## Timeline

| Integration | Duree |
|-------------|-------|
| WhatsApp | 1j |
| Instagram | 2j |
| Calendrier | 1j |
| Transport | 2j (V2) |
| **TOTAL MVP** | **4 jours** |

---

*Feature BMAD - Epic E0 Modernisation 2026*
