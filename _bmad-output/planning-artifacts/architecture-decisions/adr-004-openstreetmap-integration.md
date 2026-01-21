# ADR-004: OpenStreetMap pour la Cartographie

> Architecture Decision Record

## Informations

| Champ | Valeur |
|-------|--------|
| **ID** | ADR-004 |
| **Statut** | Accepte |
| **Date** | Janvier 2026 |
| **Decideurs** | The Develobeers |

---

## Contexte

FUG est une application geolocalisee qui necessite:
- Afficher une carte interactive
- Placer des marqueurs pour les evenements
- Permettre la selection d'un lieu lors de la creation d'evenement
- Effectuer du geocoding (adresse <-> coordonnees)
- Calculer des distances

L'application cible Android et iOS, avec une version web possible.

---

## Decision

Nous adoptons **OpenStreetMap (OSM)** via le package **flutter_map** pour l'affichage cartographique, combine avec des services de geocoding gratuits.

### Stack cartographique

| Composant | Solution |
|-----------|----------|
| Affichage carte | `flutter_map` + tuiles OSM |
| Marqueurs | `flutter_map_marker_cluster` |
| Geocoding | Nominatim (OSM) ou `geocoding` package |
| Geolocalisation | `geolocator` |
| Calcul distance | Formule Haversine |

### Configuration de base

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(50.8503, 4.3517), // Bruxelles
    initialZoom: 13.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.develobeers.fug',
    ),
    MarkerLayer(markers: eventMarkers),
  ],
)
```

---

## Justification

### Avantages d'OpenStreetMap

1. **Gratuit et Open Source**
   - Pas de frais de licence
   - Pas de limites de requetes (avec cache)
   - Donnees communautaires

2. **Couverture mondiale**
   - Excellent en Europe
   - Mise a jour frequente
   - POI detailles

3. **Independance**
   - Pas de vendor lock-in
   - Multiples providers de tuiles
   - Self-hosting possible

4. **flutter_map bien maintenu**
   - Package mature
   - Bonne documentation
   - Plugins nombreux

5. **Legalite**
   - Licence ODbL claire
   - Attribution simple
   - RGPD compatible

### Comparaison avec alternatives

| Critere | OSM/flutter_map | Google Maps | Mapbox |
|---------|-----------------|-------------|--------|
| Cout | Gratuit | Pay-as-you-go | Freemium |
| Qualite cartes | Tres bonne | Excellente | Excellente |
| Limite requetes | Non (tuiles) | Oui | Oui |
| SDK Flutter | Communaute | Officiel | Communaute |
| Personnalisation | Elevee | Limitee | Elevee |
| Offline | Oui (avec setup) | Limite | Oui |
| Vendor lock-in | Non | Oui | Oui |

---

## Alternatives Considerees

### 1. Google Maps (google_maps_flutter)

**Avantages:**
- SDK officiel Flutter
- Qualite cartes exceptionnelle
- Street View
- Places API puissante

**Inconvenients:**
- Payant au-dela du quota gratuit
- $200/mois gratuit, puis $7/1000 requetes
- API key exposee
- Vendor lock-in Google
- Terms of Service restrictifs

**Raison du rejet:** Cout potentiellement eleve avec croissance, vendor lock-in, API key a securiser.

### 2. Mapbox (flutter_mapbox_gl)

**Avantages:**
- Cartes tres personnalisables
- Bonne performance
- SDK moderne
- 50k vues gratuites/mois

**Inconvenients:**
- Payant au-dela du quota
- SDK Flutter non-officiel
- Configuration plus complexe
- Token a gerer

**Raison du rejet:** Cout et complexite non justifies pour nos besoins.

### 3. Apple Maps (via platform views)

**Avantages:**
- Natif iOS
- Pas de cout additionnel
- Bonne qualite

**Inconvenients:**
- iOS uniquement
- Pas de package Flutter mature
- Pas disponible sur Android/Web

**Raison du rejet:** Pas cross-platform.

### 4. HERE Maps

**Avantages:**
- Bon pour navigation
- 250k transactions/mois gratuites

**Inconvenients:**
- SDK Flutter non-officiel
- Moins connu
- Configuration complexe

**Raison du rejet:** Pas de valeur ajoutee pour notre use case.

---

## Consequences

### Positives

- Zero cout pour les cartes
- Independance complete
- Personnalisation possible
- Communaute active flutter_map

### Negatives

- Qualite cartes parfois inferieure (zones rurales)
- Pas de Street View
- Geocoding moins precis que Google
- Attribution OSM obligatoire

### Neutres

- Documentation communautaire
- Multiples providers de tuiles disponibles

---

## Implementation Technique

### 1. Affichage de la Carte

```dart
// lib/features/events/presentation/events_map_screen.dart
class EventsMapScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final userLocation = ref.watch(locationProvider);

    return FlutterMap(
      options: MapOptions(
        initialCenter: userLocation.value ?? LatLng(50.8503, 4.3517),
        initialZoom: 14.0,
        onTap: (tapPosition, point) {
          // Fermer les popups
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.develobeers.fug',
          // Cache avec flutter_map_cache
        ),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 80,
            markers: _buildMarkers(events.value ?? []),
            builder: (context, markers) => _buildCluster(markers),
          ),
        ),
        // Marqueur position utilisateur
        MarkerLayer(
          markers: [
            if (userLocation.hasValue)
              Marker(
                point: userLocation.value!,
                child: Icon(Icons.my_location, color: Colors.blue),
              ),
          ],
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<EventModel> events) {
    return events.map((event) => Marker(
      point: LatLng(event.latitude, event.longitude),
      child: GestureDetector(
        onTap: () => _showEventPreview(event),
        child: Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    )).toList();
  }
}
```

### 2. Selection de Lieu (Creation Evenement)

```dart
class LocationPickerScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onTap: (tapPosition, point) {
                setState(() => _selectedPoint = point);
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(...),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      child: Icon(Icons.location_pin),
                    ),
                  ],
                ),
            ],
          ),
          // Barre de recherche d'adresse
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: AddressSearchBar(
              onAddressSelected: (address, latLng) {
                _mapController.move(latLng, 16);
                setState(() => _selectedPoint = latLng);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Geocoding avec Nominatim

```dart
class GeocodingService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';

  /// Recherche d'adresse -> coordonnees
  Future<List<GeocodingResult>> searchAddress(String query) async {
    final response = await http.get(
      Uri.parse('$_nominatimUrl/search?q=$query&format=json&limit=5'),
      headers: {'User-Agent': 'FUG-App/1.0'},
    );

    final results = jsonDecode(response.body) as List;
    return results.map((r) => GeocodingResult.fromNominatim(r)).toList();
  }

  /// Coordonnees -> adresse (reverse geocoding)
  Future<String?> reverseGeocode(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$_nominatimUrl/reverse?lat=$lat&lon=$lng&format=json'),
      headers: {'User-Agent': 'FUG-App/1.0'},
    );

    final data = jsonDecode(response.body);
    return data['display_name'] as String?;
  }
}
```

### 4. Calcul de Distance

```dart
import 'dart:math';

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  /// Calcule la distance entre deux points (formule Haversine)
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Formate la distance pour affichage
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${km.round()} km';
    }
  }
}
```

### 5. Geolocalisation Utilisateur

```dart
// lib/core/providers/location_provider.dart
final locationProvider = StreamProvider<Position>((ref) {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Mise a jour tous les 100m
    ),
  );
});

final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }

  return Geolocator.getCurrentPosition();
});
```

---

## Dependencies

```yaml
dependencies:
  flutter_map: ^6.1.0
  flutter_map_marker_cluster: ^1.3.0
  latlong2: ^0.9.0
  geolocator: ^11.0.0
  http: ^1.2.0  # Pour Nominatim

# Optionnel
  flutter_map_cache: ^1.5.0  # Cache des tuiles
  flutter_map_location_marker: ^8.0.0  # Marqueur position
```

---

## Limites et Workarounds

### 1. Qualite des donnees OSM

**Probleme:** Certaines zones rurales moins detaillees.
**Solution:** Acceptable pour notre cible (zones urbaines, bars/cafes).

### 2. Rate limiting Nominatim

**Probleme:** 1 requete/seconde, ban si abuse.
**Solution:**
- Debounce sur recherche d'adresse (500ms)
- Cache local des resultats
- User-Agent correct

### 3. Pas de Street View

**Probleme:** Pas d'equivalent a Google Street View.
**Solution:** Non critique pour FUG, photos d'evenements suffisent.

---

## Attribution OSM

Obligatoire selon licence ODbL:

```dart
// Dans la carte ou le footer
Text(
  '(c) OpenStreetMap contributors',
  style: TextStyle(fontSize: 10),
)
```

Ou via TileLayer:

```dart
TileLayer(
  urlTemplate: '...',
  attributionWidget: RichAttributionWidget(
    attributions: [
      TextSourceAttribution('OpenStreetMap contributors'),
    ],
  ),
)
```

---

## References

- [flutter_map Documentation](https://docs.fleaflet.dev/)
- [OpenStreetMap](https://www.openstreetmap.org)
- [Nominatim API](https://nominatim.org/release-docs/latest/api/Overview/)
- [geolocator Package](https://pub.dev/packages/geolocator)

---

## Revision

| Date | Modification | Auteur |
|------|--------------|--------|
| Janvier 2026 | Creation initiale | The Develobeers |

---

*Document genere pour le projet FUG - The Develobeers*
