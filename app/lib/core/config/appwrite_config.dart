/// Configuration Appwrite pour l'application FUG
///
/// Ce fichier contient toutes les constantes de configuration
/// pour la connexion à Appwrite.
class AppwriteConfig {
  // Empêcher l'instanciation
  AppwriteConfig._();

  /// Endpoint Appwrite - À modifier selon l'environnement
  static const String endpoint = 'http://localhost:9000/v1';

  /// ID du projet Appwrite
  static const String projectId = '697015400010787139b8';

  /// Clé API (optionnelle, pour les opérations serveur)
  static const String? apiKey = null;

  // ============================================
  // IDs des Databases
  // ============================================

  /// Database principale
  static const String databaseId = 'fug-db';

  // ============================================
  // IDs des Collections
  // ============================================

  /// Collection des utilisateurs (profils étendus)
  static const String usersCollectionId = 'users';

  /// Collection des événements
  static const String eventsCollectionId = 'events';

  /// Collection des participations aux événements
  static const String participationsCollectionId = 'participations';

  /// Collection des catégories d'événements
  static const String categoriesCollectionId = 'categories';

  /// Collection des notifications
  static const String notificationsCollectionId = 'notifications';

  /// Collection des commentaires/avis
  static const String reviewsCollectionId = 'reviews';

  /// Collection des signalements
  static const String reportsCollectionId = 'reports';

  // ============================================
  // IDs des Buckets Storage
  // ============================================

  /// Bucket pour les avatars utilisateurs
  static const String avatarsBucketId = 'avatars';

  /// Bucket pour les images d'événements
  static const String eventImagesBucketId = 'event_images';

  // ============================================
  // Configuration Realtime
  // ============================================

  /// Channel pour les événements en temps réel
  static String get eventsChannel =>
      'databases.$databaseId.collections.$eventsCollectionId.documents';

  /// Channel pour les participations en temps réel
  static String get participationsChannel =>
      'databases.$databaseId.collections.$participationsCollectionId.documents';

  /// Channel pour les notifications utilisateur
  static String userNotificationsChannel(String userId) =>
      'databases.$databaseId.collections.$notificationsCollectionId.documents';

  // ============================================
  // Configuration Géolocalisation
  // ============================================

  /// Rayon de recherche par défaut (en km)
  static const double defaultSearchRadiusKm = 10.0;

  /// Rayon de recherche maximum (en km)
  static const double maxSearchRadiusKm = 50.0;

  /// Limite de résultats par requête
  static const int defaultQueryLimit = 25;

  /// Limite maximum de résultats
  static const int maxQueryLimit = 100;
}
