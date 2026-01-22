import 'package:flutter/foundation.dart';

import 'appwrite_service.dart';

/// Service pour gerer les push notifications via Appwrite Messaging
///
/// Ce service gere l'enregistrement et le desenregistrement des appareils
/// pour recevoir des notifications push. Il utilise Appwrite Messaging
/// qui route les notifications vers FCM (Android) ou APNs (iOS).
///
/// Architecture:
/// ```
/// Flutter App --> Appwrite SDK --> Appwrite Messaging --> FCM/APNs --> Device
/// ```
///
/// Configuration requise:
/// - FCM: Configurer la cle serveur dans Appwrite Console > Messaging
/// - APNs: Configurer le certificat .p8 dans Appwrite Console > Messaging
class PushNotificationService {
  final AppwriteService _appwrite;

  /// Instance singleton
  static PushNotificationService? _instance;

  /// Factory pour obtenir l'instance singleton
  factory PushNotificationService({AppwriteService? appwrite}) {
    _instance ??= PushNotificationService._internal(
      appwrite: appwrite ?? AppwriteService.instance,
    );
    return _instance!;
  }

  /// Constructeur prive
  PushNotificationService._internal({required AppwriteService appwrite})
      : _appwrite = appwrite;

  /// Obtenir l'instance (alias pour le factory)
  static PushNotificationService get instance => PushNotificationService();

  /// Reinitialise le service (utile pour les tests)
  static void reset() {
    _instance = null;
  }

  /// Enregistre l'appareil pour recevoir des notifications push
  ///
  /// Cette methode doit etre appelee apres un login reussi.
  /// Elle cree un "target" dans Appwrite Messaging pour l'utilisateur.
  ///
  /// Note: L'implementation complete necessite:
  /// 1. Obtenir le token FCM/APNs via firebase_messaging ou autre
  /// 2. Enregistrer ce token comme target dans Appwrite Messaging
  ///
  /// Pour l'instant, cette implementation est un placeholder qui:
  /// - Log l'intention d'enregistrement
  /// - Ne bloque pas le flow de login en cas d'erreur
  Future<void> registerDevice(String userId) async {
    try {
      if (kDebugMode) {
        print('PushNotificationService: Registering device for user $userId');
      }

      // TODO: Implementation complete avec Appwrite Messaging SDK
      // Quand le SDK Dart supportera Messaging:
      //
      // 1. Obtenir le token FCM/APNs
      // final fcmToken = await FirebaseMessaging.instance.getToken();
      //
      // 2. Creer un target dans Appwrite Messaging
      // await _appwrite.messaging.createPushTarget(
      //   targetId: ID.unique(),
      //   identifier: fcmToken,
      //   providerId: 'fcm-provider-id', // Configure dans Appwrite Console
      // );
      //
      // 3. Stocker le token dans le profil utilisateur pour reference
      // await _appwrite.databases.updateDocument(
      //   databaseId: AppwriteConfig.databaseId,
      //   collectionId: AppwriteConfig.usersCollectionId,
      //   documentId: userId,
      //   data: {'fcmToken': fcmToken},
      // );

      if (kDebugMode) {
        print('PushNotificationService: Device registration placeholder called');
        print('PushNotificationService: Configure FCM/APNs in Appwrite Console');
      }
    } catch (e) {
      // Log error but don't crash - push is non-critical
      if (kDebugMode) {
        print('PushNotificationService: Failed to register device: $e');
      }
    }
  }

  /// Desenregistre l'appareil pour ne plus recevoir de notifications push
  ///
  /// Cette methode doit etre appelee avant ou apres un logout.
  /// Elle supprime le "target" de l'utilisateur dans Appwrite Messaging.
  Future<void> unregisterDevice(String userId) async {
    try {
      if (kDebugMode) {
        print('PushNotificationService: Unregistering device for user $userId');
      }

      // TODO: Implementation complete avec Appwrite Messaging SDK
      // Quand le SDK Dart supportera Messaging:
      //
      // 1. Recuperer le target ID de l'utilisateur
      // 2. Supprimer le target
      // await _appwrite.messaging.deletePushTarget(targetId: targetId);
      //
      // 3. Nettoyer le token du profil utilisateur
      // await _appwrite.databases.updateDocument(
      //   databaseId: AppwriteConfig.databaseId,
      //   collectionId: AppwriteConfig.usersCollectionId,
      //   documentId: userId,
      //   data: {'fcmToken': null},
      // );

      if (kDebugMode) {
        print('PushNotificationService: Device unregistration placeholder called');
      }
    } catch (e) {
      // Log error but don't crash - push is non-critical
      if (kDebugMode) {
        print('PushNotificationService: Failed to unregister device: $e');
      }
    }
  }

  /// Verifie si le service de push est disponible
  ///
  /// Retourne true si Appwrite Messaging est configure et accessible.
  Future<bool> isAvailable() async {
    try {
      // Pour l'instant, retourne toujours true car c'est un placeholder
      // L'implementation reelle verifierait la configuration Messaging
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService: Service not available: $e');
      }
      return false;
    }
  }
}
