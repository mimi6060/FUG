import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consent_model.dart';

/// Storage key for local consent
const String _consentKey = 'user_consent';

/// Custom exception for consent operations
class ConsentException implements Exception {
  final String message;
  final int? code;

  ConsentException(this.message, {this.code});

  @override
  String toString() => 'ConsentException: $message';
}

/// Consent preferences stored locally
///
/// Simplified version of ConsentModel for local storage.
class ConsentPreferences {
  /// Analytics consent
  final bool analytics;

  /// Marketing consent
  final bool marketing;

  /// Consent date
  final DateTime consentDate;

  /// Accepted policy version
  final String policyVersion;

  const ConsentPreferences({
    required this.analytics,
    required this.marketing,
    required this.consentDate,
    this.policyVersion = '1.0',
  });

  /// Creates from JSON
  factory ConsentPreferences.fromJson(Map<String, dynamic> json) {
    return ConsentPreferences(
      analytics: json['analytics'] as bool? ?? false,
      marketing: json['marketing'] as bool? ?? false,
      consentDate: DateTime.parse(json['consentDate'] as String),
      policyVersion: json['policyVersion'] as String? ?? '1.0',
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'analytics': analytics,
      'marketing': marketing,
      'consentDate': consentDate.toIso8601String(),
      'policyVersion': policyVersion,
    };
  }
}

/// Repository for GDPR consent management
///
/// Handles local storage and synchronization with Appwrite
/// for user consent preferences.
class ConsentRepository {
  final SharedPreferences? _prefs;

  /// Constructor with optional SharedPreferences injection
  ConsentRepository({SharedPreferences? prefs}) : _prefs = prefs;

  /// Gets the SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Retrieves locally stored consent preferences
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

  /// Saves consent preferences locally
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

  /// Checks if local consent exists
  Future<bool> hasLocalConsent() async {
    final consent = await getLocalConsent();
    return consent != null;
  }

  /// Checks if consent is required (no stored consent)
  Future<bool> isConsentRequired() async {
    return !(await hasLocalConsent());
  }

  /// Clears local consent (for logout or account deletion)
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
  // Methods with ConsentModel (for compatibility)
  // ============================================

  /// Converts ConsentPreferences to ConsentModel
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

  /// Converts ConsentModel to ConsentPreferences
  ConsentPreferences modelToPreferences(ConsentModel model) {
    return ConsentPreferences(
      analytics: model.analyticsConsent,
      marketing: model.marketingConsent,
      consentDate: model.consentDate,
      policyVersion: model.policyVersion,
    );
  }

  /// Retrieves locally stored ConsentModel
  Future<ConsentModel?> getLocalConsentModel(String userId) async {
    final prefs = await getLocalConsent();
    return preferencesToModel(prefs, userId);
  }

  /// Saves a ConsentModel locally
  Future<bool> saveLocalConsentModel(ConsentModel consent) async {
    final prefs = modelToPreferences(consent);
    return saveLocalConsent(prefs);
  }

  /// Updates consent
  Future<ConsentModel?> updateConsent({
    required String userId,
    bool? analyticsConsent,
    bool? marketingConsent,
  }) async {
    try {
      // Get existing consent or create a new one
      var consent = await getLocalConsentModel(userId);
      consent ??= ConsentModel.initial(userId);

      // Update values
      final updatedConsent = consent.copyWith(
        userId: userId,
        analyticsConsent: analyticsConsent ?? consent.analyticsConsent,
        marketingConsent: marketingConsent ?? consent.marketingConsent,
        lastUpdated: DateTime.now(),
      );

      // Save locally
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

  /// Creates a new initial consent
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

      // Save locally
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
