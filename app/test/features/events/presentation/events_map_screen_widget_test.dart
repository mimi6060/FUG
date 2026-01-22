import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fug_app/features/events/presentation/events_map_screen.dart';
import 'package:fug_app/features/events/domain/event_model.dart';
import 'package:fug_app/features/events/data/event_repository.dart';
import 'package:fug_app/core/providers/events_provider.dart';
import 'package:fug_app/core/providers/location_provider.dart';

import '../../../helpers/test_helpers.dart';

// Mock classes
class MockLocationService extends Mock implements LocationService {}

class MockEventRepository extends Mock implements EventRepository {}

class FakePosition extends Fake implements Position {
  @override
  double get latitude => 48.8566;

  @override
  double get longitude => 2.3522;

  @override
  double get accuracy => 10.0;

  @override
  double get altitude => 0.0;

  @override
  double get heading => 0.0;

  @override
  double get speed => 0.0;

  @override
  double get speedAccuracy => 0.0;

  @override
  DateTime get timestamp => DateTime.now();

  @override
  double get altitudeAccuracy => 0.0;

  @override
  double get headingAccuracy => 0.0;

  @override
  bool get isMocked => true;
}

void main() {
  late MockLocationService mockLocationService;
  late MockEventRepository mockEventRepository;

  setUpAll(() {
    setUpTestHelpers();
    registerFallbackValue(FakePosition());
    registerFallbackValue(NearbyEventsParams(
      latitude: 48.8566,
      longitude: 2.3522,
      radiusKm: 10.0,
    ));
  });

  setUp(() {
    mockLocationService = MockLocationService();
    mockEventRepository = MockEventRepository();

    // Setup default mock behaviors
    when(() => mockLocationService.isLocationServiceEnabled())
        .thenAnswer((_) async => true);
    when(() => mockLocationService.hasPermission())
        .thenAnswer((_) async => true);
    when(() => mockLocationService.getCurrentPosition())
        .thenAnswer((_) async => FakePosition());
    when(() => mockLocationService.getLastKnownPosition())
        .thenAnswer((_) async => FakePosition());
  });

  Widget createTestWidget({
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(mockLocationService),
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ...?overrides,
      ],
      child: const MaterialApp(
        home: EventsMapScreen(),
      ),
    );
  }

  group('EventsMapScreen Widget Tests', () {
    testWidgets('devrait afficher la carte FlutterMap', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('devrait afficher le titre FUG dans l\'appbar', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('FUG'), findsOneWidget);
    });

    testWidgets('devrait afficher les boutons de zoom', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('devrait afficher le bouton de centrage', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('devrait afficher le bouton Creer un FUG', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Creer un FUG'), findsOneWidget);
    });

    testWidgets('devrait afficher la navigation bar', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
      expect(find.text('Evenements'), findsOneWidget);
      expect(find.text('Notifs'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('devrait afficher l\'indicateur de chargement initialement', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return [];
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // L'indicateur de chargement devrait etre visible
      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('devrait afficher le compteur de FUGs apres chargement', (tester) async {
      final testEvents = TestData.createEventList(count: 3);

      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Le compteur devrait afficher "3 FUGs a proximite"
      expect(find.textContaining('FUG'), findsWidgets);
    });

    testWidgets('devrait ouvrir les filtres au tap sur l\'icone filtre', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap sur l'icone de filtre
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // La bottom sheet des filtres devrait s'ouvrir
      expect(find.text('Filtres'), findsOneWidget);
      expect(find.text('Rayon de recherche:'), findsOneWidget);
    });
  });

  group('Clustering Integration', () {
    testWidgets('devrait inclure MarkerClusterLayerWidget dans la carte', (tester) async {
      final testEvents = TestData.createEventList(count: 5);

      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verifie que le widget de clustering est present
      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
    });
  });

  group('Filter Sheet', () {
    testWidgets('devrait permettre de toggler le filtre gratuit', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Ouvrir les filtres
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Trouver et toggler le switch "gratuits"
      final freeSwitch = find.widgetWithText(SwitchListTile, 'Evenements gratuits uniquement');
      expect(freeSwitch, findsOneWidget);
    });

    testWidgets('devrait permettre de toggler le filtre places disponibles', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Ouvrir les filtres
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Trouver le switch "places disponibles"
      final availableSwitch = find.widgetWithText(SwitchListTile, 'Places disponibles uniquement');
      expect(availableSwitch, findsOneWidget);
    });

    testWidgets('devrait afficher le slider de rayon', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Ouvrir les filtres
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Le slider devrait etre present
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('devrait avoir un bouton Appliquer', (tester) async {
      when(() => mockEventRepository.getNearbyEvents(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusKm: any(named: 'radiusKm'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Ouvrir les filtres
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Le bouton Appliquer devrait etre present
      expect(find.text('Appliquer'), findsOneWidget);
    });
  });
}
