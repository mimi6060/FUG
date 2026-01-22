import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import '../config/appwrite_config.dart';

/// Service singleton pour la gestion des connexions Appwrite
///
/// Fournit un accès centralisé à tous les services Appwrite:
/// - Client
/// - Account (authentification)
/// - Databases
/// - Realtime
/// - Storage
class AppwriteService {
  // Instance singleton
  static AppwriteService? _instance;

  // Services Appwrite
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Realtime _realtime;
  late final Storage _storage;
  late final Functions _functions;

  // Getters pour acceder aux services
  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Realtime get realtime => _realtime;
  Storage get storage => _storage;
  Functions get functions => _functions;

  /// Constructeur privé
  AppwriteService._internal() {
    _initializeClient();
  }

  /// Factory pour obtenir l'instance singleton
  factory AppwriteService() {
    _instance ??= AppwriteService._internal();
    return _instance!;
  }

  /// Obtenir l'instance (alias pour le factory)
  static AppwriteService get instance => AppwriteService();

  /// Initialise le client Appwrite et tous les services
  void _initializeClient() {
    _client = Client();

    _client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId)
        .setSelfSigned(status: kDebugMode); // Uniquement en debug pour le dev local

    // Initialiser tous les services
    _account = Account(_client);
    _databases = Databases(_client);
    _realtime = Realtime(_client);
    _storage = Storage(_client);
    _functions = Functions(_client);

    if (kDebugMode) {
      print('AppwriteService initialized');
      print('Endpoint: ${AppwriteConfig.endpoint}');
      print('Project: ${AppwriteConfig.projectId}');
    }
  }

  /// Réinitialise le service (utile pour les tests ou la déconnexion)
  static void reset() {
    _instance = null;
  }

  // ============================================
  // Méthodes utilitaires pour les Databases
  // ============================================

  /// Crée un document dans une collection
  Future<Document> createDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
    List<String>? permissions,
  }) async {
    return await _databases.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
      permissions: permissions,
    );
  }

  /// Récupère un document par son ID
  Future<Document> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await _databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  /// Met à jour un document
  Future<Document> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
    List<String>? permissions,
  }) async {
    return await _databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
      permissions: permissions,
    );
  }

  /// Supprime un document
  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  /// Liste les documents avec des requêtes optionnelles
  Future<DocumentList> listDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    return await _databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      queries: queries,
    );
  }

  // ============================================
  // Méthodes utilitaires pour le Storage
  // ============================================

  /// Upload un fichier
  Future<File> uploadFile({
    required String bucketId,
    required String fileId,
    required InputFile file,
    List<String>? permissions,
  }) async {
    return await _storage.createFile(
      bucketId: bucketId,
      fileId: fileId,
      file: file,
      permissions: permissions,
    );
  }

  /// Récupère l'URL de prévisualisation d'un fichier
  String getFilePreviewUrl({
    required String bucketId,
    required String fileId,
    int? width,
    int? height,
  }) {
    final uri = Uri.parse(AppwriteConfig.endpoint);
    var url = '${uri.scheme}://${uri.host}';
    if (uri.port != 80 && uri.port != 443) {
      url += ':${uri.port}';
    }
    url += '/v1/storage/buckets/$bucketId/files/$fileId/preview';
    url += '?project=${AppwriteConfig.projectId}';
    if (width != null) url += '&width=$width';
    if (height != null) url += '&height=$height';
    return url;
  }

  /// Récupère l'URL de téléchargement d'un fichier
  String getFileDownloadUrl({
    required String bucketId,
    required String fileId,
  }) {
    final uri = Uri.parse(AppwriteConfig.endpoint);
    var url = '${uri.scheme}://${uri.host}';
    if (uri.port != 80 && uri.port != 443) {
      url += ':${uri.port}';
    }
    url += '/v1/storage/buckets/$bucketId/files/$fileId/download';
    url += '?project=${AppwriteConfig.projectId}';
    return url;
  }

  /// Supprime un fichier
  Future<void> deleteFile({
    required String bucketId,
    required String fileId,
  }) async {
    await _storage.deleteFile(
      bucketId: bucketId,
      fileId: fileId,
    );
  }

  // ============================================
  // Méthodes utilitaires pour le Realtime
  // ============================================

  /// S'abonne à un channel Realtime
  RealtimeSubscription subscribe({
    required List<String> channels,
    required Function(RealtimeMessage) callback,
  }) {
    return _realtime.subscribe(channels).stream.listen(callback)
        as RealtimeSubscription;
  }

  /// S'abonne aux changements d'une collection
  RealtimeSubscription subscribeToCollection({
    required String collectionId,
    required Function(RealtimeMessage) callback,
  }) {
    final channel = 'databases.${AppwriteConfig.databaseId}.collections.$collectionId.documents';
    return subscribe(channels: [channel], callback: callback);
  }
}

/// Extension pour faciliter la gestion des erreurs Appwrite
extension AppwriteExceptionHandler on AppwriteException {
  /// Retourne un message d'erreur lisible
  String get readableMessage {
    switch (code) {
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Vous n\'avez pas les permissions nécessaires.';
      case 404:
        return 'Ressource non trouvée.';
      case 409:
        return 'Cette ressource existe déjà.';
      case 429:
        return 'Trop de requêtes. Veuillez patienter.';
      case 500:
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      default:
        return message ?? 'Une erreur est survenue.';
    }
  }
}
