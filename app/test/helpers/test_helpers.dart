import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:mocktail/mocktail.dart';

import 'package:fug_app/core/services/appwrite_service.dart';
import 'package:fug_app/features/auth/domain/user_model.dart';
import 'package:fug_app/features/events/domain/event_model.dart';

// ============================================
// Mock Classes
// ============================================

/// Mock du service Appwrite
class MockAppwriteService extends Mock implements AppwriteService {}

/// Mock du client Appwrite
class MockClient extends Mock implements Client {}

/// Mock du service Account
class MockAccount extends Mock implements Account {}

/// Mock du service Databases
class MockDatabases extends Mock implements Databases {}

/// Mock du service Realtime
class MockRealtime extends Mock implements Realtime {}

/// Mock du service Storage
class MockStorage extends Mock implements Storage {}

/// Mock d'un Document Appwrite
class MockDocument extends Mock implements Document {}

/// Mock d'une DocumentList Appwrite
class MockDocumentList extends Mock implements DocumentList {}

// ============================================
// Fake Classes pour Mocktail registerFallbackValue
// ============================================

/// Fake User pour les tests
class FakeUser extends Fake implements models.User {
  @override
  String get $id => 'fake-user-id';

  @override
  String get email => 'fake@example.com';

  @override
  String get name => 'Fake User';

  @override
  DateTime get $createdAt => DateTime(2024, 1, 1);

  @override
  DateTime get $updatedAt => DateTime(2024, 1, 1);

  @override
  bool get emailVerification => false;

  @override
  bool get phoneVerification => false;

  @override
  String get phone => '';

  @override
  Map<String, dynamic> get prefs => {};

  @override
  bool get status => true;

  @override
  String get password => '';

  @override
  String get hash => '';

  @override
  String get hashOptions => '';

  @override
  DateTime get registration => DateTime(2024, 1, 1);

  @override
  bool get mfa => false;

  @override
  List<models.Target> get targets => [];

  @override
  DateTime get accessedAt => DateTime(2024, 1, 1);

  @override
  Map<String, dynamic> toMap() => {
        '\$id': $id,
        'email': email,
        'name': name,
      };
}

/// Fake Session pour les tests
class FakeSession extends Fake implements models.Session {
  @override
  String get $id => 'fake-session-id';

  @override
  String get userId => 'fake-user-id';

  @override
  DateTime get $createdAt => DateTime(2024, 1, 1);

  @override
  DateTime get expire => DateTime(2024, 12, 31);

  @override
  String get provider => 'email';

  @override
  String get providerUid => 'fake@example.com';

  @override
  String get providerAccessToken => '';

  @override
  DateTime get providerAccessTokenExpiry => DateTime(2024, 12, 31);

  @override
  String get providerRefreshToken => '';

  @override
  String get ip => '127.0.0.1';

  @override
  String get osCode => 'MAC';

  @override
  String get osName => 'macOS';

  @override
  String get osVersion => '14.0';

  @override
  String get clientType => 'desktop';

  @override
  String get clientCode => 'FL';

  @override
  String get clientName => 'Flutter';

  @override
  String get clientVersion => '3.0';

  @override
  String get clientEngine => '';

  @override
  String get clientEngineVersion => '';

  @override
  String get deviceName => 'Test Device';

  @override
  String get deviceBrand => 'Apple';

  @override
  String get deviceModel => 'MacBook Pro';

  @override
  String get countryCode => 'FR';

  @override
  String get countryName => 'France';

  @override
  bool get current => true;

  @override
  List<String> get factors => [];

  @override
  String get secret => '';

  @override
  bool get mfaUpdatedAt => false;

  @override
  Map<String, dynamic> toMap() => {
        '\$id': $id,
        'userId': userId,
        'provider': provider,
      };
}

/// Fake Event pour les tests
class FakeEvent extends Fake implements EventModel {
  @override
  String get id => 'fake-event-id';

  @override
  String get title => 'Fake Event';

  @override
  String get description => 'A fake event for testing';

  @override
  String get organizerId => 'fake-organizer-id';

  @override
  String get organizerName => 'Fake Organizer';

  @override
  String get categoryId => 'fake-category-id';

  @override
  String? get categoryName => 'Fake Category';

  @override
  String get address => '123 Fake Street, Paris';

  @override
  double get latitude => 48.8566;

  @override
  double get longitude => 2.3522;

  @override
  DateTime get startDate => DateTime(2024, 6, 15, 18, 0);

  @override
  DateTime get endDate => DateTime(2024, 6, 15, 22, 0);

  @override
  EventStatus get status => EventStatus.published;

  @override
  DateTime get createdAt => DateTime(2024, 1, 1);

  @override
  DateTime get updatedAt => DateTime(2024, 1, 1);
}

// ============================================
// Test Data Generators
// ============================================

/// Classe utilitaire pour generer des donnees de test
class TestData {
  TestData._();

  /// Genere un UserModel de test
  static UserModel createUser({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? interests,
    int? eventsCreated,
    int? eventsAttended,
    double? rating,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email ?? 'test@example.com',
      name: name ?? 'Test User',
      avatarUrl: avatarUrl,
      bio: bio,
      location: location,
      latitude: latitude,
      longitude: longitude,
      interests: interests ?? [],
      eventsCreated: eventsCreated ?? 0,
      eventsAttended: eventsAttended ?? 0,
      rating: rating ?? 0.0,
      isVerified: isVerified ?? false,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Genere un EventModel de test
  static EventModel createEvent({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? additionalImages,
    String? address,
    double? latitude,
    double? longitude,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? currentParticipants,
    int? price,
    String? currency,
    List<String>? tags,
    EventStatus? status,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return EventModel(
      id: id ?? 'test-event-${now.millisecondsSinceEpoch}',
      title: title ?? 'Test Event',
      description: description ?? 'Test event description',
      organizerId: organizerId ?? 'test-organizer-id',
      organizerName: organizerName ?? 'Test Organizer',
      categoryId: categoryId ?? 'test-category-id',
      categoryName: categoryName ?? 'Test Category',
      imageUrl: imageUrl,
      additionalImages: additionalImages ?? [],
      address: address ?? '123 Test Street, Paris',
      latitude: latitude ?? 48.8566,
      longitude: longitude ?? 2.3522,
      venueName: venueName,
      startDate: startDate ?? now.add(const Duration(days: 7)),
      endDate: endDate ?? now.add(const Duration(days: 7, hours: 4)),
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants ?? 0,
      price: price ?? 0,
      currency: currency ?? 'EUR',
      tags: tags ?? [],
      status: status ?? EventStatus.published,
      isFeatured: isFeatured ?? false,
      rating: rating ?? 0.0,
      reviewCount: reviewCount ?? 0,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Genere des donnees JSON pour un utilisateur
  static Map<String, dynamic> createUserJson({
    String? userId,
    String? email,
    String? name,
    String? avatarUrl,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? interests,
    int? eventsCreated,
    int? eventsAttended,
    double? rating,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      'userId': userId ?? 'test-user-id',
      '\$id': userId ?? 'test-user-id',
      'email': email ?? 'test@example.com',
      'name': name ?? 'Test User',
      'avatarUrl': avatarUrl,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'interests': interests ?? [],
      'eventsCreated': eventsCreated ?? 0,
      'eventsAttended': eventsAttended ?? 0,
      'rating': rating ?? 0.0,
      'isVerified': isVerified ?? false,
      'createdAt': (createdAt ?? now).toIso8601String(),
      'updatedAt': (updatedAt ?? now).toIso8601String(),
    };
  }

  /// Genere des donnees JSON pour un evenement
  static Map<String, dynamic> createEventJson({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? additionalImages,
    String? address,
    double? latitude,
    double? longitude,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? currentParticipants,
    int? price,
    String? currency,
    List<String>? tags,
    String? status,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return {
      '\$id': id ?? 'test-event-id',
      'id': id ?? 'test-event-id',
      'title': title ?? 'Test Event',
      'description': description ?? 'Test event description',
      'organizerId': organizerId ?? 'test-organizer-id',
      'organizerName': organizerName ?? 'Test Organizer',
      'categoryId': categoryId ?? 'test-category-id',
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages ?? [],
      'address': address ?? '123 Test Street, Paris',
      'latitude': latitude ?? 48.8566,
      'longitude': longitude ?? 2.3522,
      'venueName': venueName,
      'startDate': (startDate ?? now.add(const Duration(days: 7))).toIso8601String(),
      'endDate': (endDate ?? now.add(const Duration(days: 7, hours: 4))).toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants ?? 0,
      'price': price ?? 0,
      'currency': currency ?? 'EUR',
      'tags': tags ?? [],
      'status': status ?? 'published',
      'isFeatured': isFeatured ?? false,
      'rating': rating ?? 0.0,
      'reviewCount': reviewCount ?? 0,
      'createdAt': (createdAt ?? now).toIso8601String(),
      'updatedAt': (updatedAt ?? now).toIso8601String(),
    };
  }

  /// Genere une liste d'evenements de test
  static List<EventModel> createEventList({int count = 5}) {
    return List.generate(count, (index) {
      return createEvent(
        id: 'event-$index',
        title: 'Event $index',
        latitude: 48.8566 + (index * 0.01),
        longitude: 2.3522 + (index * 0.01),
      );
    });
  }

  /// Genere une liste d'utilisateurs de test
  static List<UserModel> createUserList({int count = 5}) {
    return List.generate(count, (index) {
      return createUser(
        id: 'user-$index',
        name: 'User $index',
        email: 'user$index@example.com',
      );
    });
  }
}

// ============================================
// Setup Functions
// ============================================

/// Configure les fallback values pour Mocktail
void setUpTestHelpers() {
  registerFallbackValue(FakeUser());
  registerFallbackValue(FakeSession());
  registerFallbackValue(FakeEvent());
}

/// Cree un mock Document avec les donnees specifiees
Document createMockDocument(Map<String, dynamic> data) {
  return Document(
    $id: data['\$id'] ?? 'mock-doc-id',
    $collectionId: 'mock-collection',
    $databaseId: 'mock-database',
    $createdAt: DateTime.now().toIso8601String(),
    $updatedAt: DateTime.now().toIso8601String(),
    $permissions: [],
    data: data,
  );
}

/// Cree un mock DocumentList avec les documents specifies
DocumentList createMockDocumentList(List<Map<String, dynamic>> documents) {
  return DocumentList(
    total: documents.length,
    documents: documents.map((data) => createMockDocument(data)).toList(),
  );
}
