import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consent_model.dart';

/// Cle de stockage pour le consentement local
const String _consentKey = 'user_consent';

/// Exception personnalisee pour le consentement
class ConsentException implements Exception {
  final String message;
  final int? code;

  ConsentException(this.message, {this.code});

  @override
  String toString() => 'ConsentException: $message';
}

/// Preferences de consentement stockees localement
///
/// Version simplifiee du ConsentModel pour le stockage local.
class ConsentPreferences {
  /// Consentement analytics
  final bool analytics;

  /// Consentement marketing
  final bool marketing;

  /// Date du consentement
  final DateTime consentDate;

  /// Version de la politique acceptee
  final String policyVersion;

  const ConsentPreferences({
    required this.analytics,
    required this.marketing,
    required this.consentDate,
    this.policyVersion = '1.0',
  });

  /// Cree a partir d'un JSON
  factory ConsentPreferences.fromJson(Map<String, dynamic> json) {
    return ConsentPreferences(
      analytics: json['analytics'] as bool? ?? false,
      marketing: json['marketing'] as bool? ?? false,
      consentDate: DateTime.parse(json['consentDate'] as String),
      policyVersion: json['policyVersion'] as String? ?? '1.0',
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'analytics': analytics,
      'marketing': marketing,
      'consentDate': consentDate.toIso8601String(),
      'policyVersion': policyVersion,
    };
  }
}

/// Repository pour la gestion du consentement RGPD
///
/// Gere le stockage local et la synchronisation avec Appwrite
/// des preferences de consentement utilisateur.
class ConsentRepository {
  final SharedPreferences? _prefs;

  /// Constructeur avec injection optionnelle de SharedPreferences
  ConsentRepository({SharedPreferences? prefs}) : _prefs = prefs;

  /// Obtient l'instance SharedPreferences
  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Recupere les preferences de consentement stockees localement
  Future<ConsentPreferences?> getLocalConsent() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(_consentKey);

      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConsentPreferences.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local consent: $e');
      }
      return null;
    }
  }

  /// Sauvegarde les preferences de consentement localement
  Future<bool> saveLocalConsent(ConsentPreferences consent) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(consent.toJson());
      return prefs.setString(_consentKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local consent: $e');
      }
      return false;
    }
  }

  /// Verifie si un consentement existe localement
  Future<bool> hasLocalConsent() async {
    final consent = await getLocalConsent();
    return consent != null;
  }

  /// Verifie si le consentement est requis (aucun consentement stocke)
  Future<bool> isConsentRequired() async {
    return !(await hasLocalConsent());
  }

  /// Supprime le consentement local (pour deconnexion ou suppression de compte)
  Future<bool> clearLocalConsent() async {
    try {
      final prefs = await _getPrefs();
      return prefs.remove(_consentKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing local consent: $e');
      }
      return false;
    }
  }

  // ============================================
  // Methodes avec ConsentModel (pour compatibilite)
  // ============================================

  /// Convertit ConsentPreferences en ConsentModel
  ConsentModel? preferencesToModel(ConsentPreferences? prefs, String userId) {
    if (prefs == null) return null;
    return ConsentModel(
      userId: userId,
      essentialConsent: true,
      analyticsConsent: prefs.analytics,
      marketingConsent: prefs.marketing,
      consentDate: prefs.consentDate,
      lastUpdated: prefs.consentDate,
      policyVersion: prefs.policyVersion,
    );
  }

  /// Convertit ConsentModel en ConsentPreferences
  ConsentPreferences modelToPreferences(ConsentModel model) {
    return ConsentPreferences(
      analytics: model.analyticsConsent,
      marketing: model.marketingConsent,
      consentDate: model.consentDate,
      policyVersion: model.policyVersion,
    );
  }

  /// Recupere le ConsentModel stocke localement
  Future<ConsentModel?> getLocalConsentModel(String userId) async {
    final prefs = await getLocalConsent();
    return preferencesToModel(prefs, userId);
  }

  /// Sauvegarde un ConsentModel localement
  Future<bool> saveLocalConsentModel(ConsentModel consent) async {
    final prefs = modelToPreferences(consent);
    return saveLocalConsent(prefs);
  }

  /// Met a jour le consentement
  Future<ConsentModel?> updateConsent({
    required String userId,
    bool? analyticsConsent,
    bool? marketingConsent,
  }) async {
    try {
      // Recuperer le consentement existant ou en creer un nouveau
      var consent = await getLocalConsentModel(userId);
      consent ??= ConsentModel.initial(userId);

      // Mettre a jour les valeurs
      final updatedConsent = consent.copyWith(
        userId: userId,
        analyticsConsent: analyticsConsent ?? consent.analyticsConsent,
        marketingConsent: marketingConsent ?? consent.marketingConsent,
        lastUpdated: DateTime.now(),
      );

      // Sauvegarder localement
      final saved = await saveLocalConsentModel(updatedConsent);
      if (!saved) {
        return null;
      }

      return updatedConsent;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating consent: $e');
      }
      return null;
    }
  }

  /// Cree un nouveau consentement initial
  Future<ConsentModel?> createInitialConsent({
    required String userId,
    required bool analyticsConsent,
    required bool marketingConsent,
  }) async {
    try {
      final now = DateTime.now();
      final consent = ConsentModel(
        userId: userId,
        essentialConsent: true,
        analyticsConsent: analyticsConsent,
        marketingConsent: marketingConsent,
        consentDate: now,
        lastUpdated: now,
        policyVersion: '1.0',
      );

      // Sauvegarder localement
      final saved = await saveLocalConsentModel(consent);
      if (!saved) {
        return null;
      }

      return consent;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating initial consent: $e');
      }
      return null;
    }
  }
}
