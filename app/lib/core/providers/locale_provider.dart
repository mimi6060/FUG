import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../config/appwrite_config.dart';
import '../services/appwrite_service.dart';
import 'auth_provider.dart';

/// Key for storing locale preference locally
const _localePrefsKey = 'app_locale';

/// Supported locales with their metadata
class LocaleInfo {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;

  const LocaleInfo({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

/// Available locales with flags (emoji flags for 2026 modern UI)
const supportedLocalesInfo = [
  LocaleInfo(
    locale: Locale('fr'),
    name: 'French',
    nativeName: 'Francais',
    flag: '\u{1F1EB}\u{1F1F7}', // France flag
  ),
  LocaleInfo(
    locale: Locale('en'),
    name: 'English',
    nativeName: 'English',
    flag: '\u{1F1EC}\u{1F1E7}', // UK flag
  ),
  LocaleInfo(
    locale: Locale('nl'),
    name: 'Dutch',
    nativeName: 'Nederlands',
    flag: '\u{1F1F3}\u{1F1F1}', // Netherlands flag
  ),
];

/// List of supported locales
final supportedLocales = supportedLocalesInfo.map((info) => info.locale).toList();

/// Default locale (French as primary language for FUG)
const defaultLocale = Locale('fr');

/// Get LocaleInfo by locale
LocaleInfo? getLocaleInfo(Locale? locale) {
  if (locale == null) return null;
  return supportedLocalesInfo.cast<LocaleInfo?>().firstWhere(
        (info) => info?.locale.languageCode == locale.languageCode,
        orElse: () => null,
      );
}

/// Provider for locale state
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs, ref);
});

/// Provider for the effective locale (resolves null to system or default)
final effectiveLocaleProvider = Provider<Locale>((ref) {
  final locale = ref.watch(localeProvider);

  if (locale != null) {
    return locale;
  }

  // Try to get system locale
  final systemLocale = PlatformDispatcher.instance.locale;

  // Check if system locale is supported
  for (final supported in supportedLocales) {
    if (supported.languageCode == systemLocale.languageCode) {
      return supported;
    }
  }

  // Fall back to default locale (French)
  return defaultLocale;
});

/// Notifier for managing locale state
class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;
  final Ref _ref;

  LocaleNotifier(this._prefs, this._ref) : super(null) {
    _loadLocale();
  }

  /// Load locale from local storage and user profile
  Future<void> _loadLocale() async {
    // First try to get from user profile if logged in
    final currentUser = _ref.read(currentUserProvider).value;
    if (currentUser != null) {
      try {
        final userDoc = await AppwriteService.instance.databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: 'users',
          documentId: currentUser.$id,
        );
        final userLocale = userDoc.data['preferredLanguage'] as String?;
        if (userLocale != null && userLocale.isNotEmpty) {
          state = Locale(userLocale);
          // Also save locally for offline access
          await _prefs.setString(_localePrefsKey, userLocale);
          return;
        }
      } catch (e) {
        debugPrint('Error loading user locale: $e');
      }
    }

    // Fallback to local storage
    final savedLocale = _prefs.getString(_localePrefsKey);
    if (savedLocale != null) {
      state = Locale(savedLocale);
    }
    // If null, effectiveLocaleProvider will use system default
  }

  /// Set the app locale
  ///
  /// If [syncToProfile] is true, will also update the user profile in Appwrite
  Future<void> setLocale(Locale? locale, {bool syncToProfile = true}) async {
    if (locale == null) {
      // Use system default
      await _prefs.remove(_localePrefsKey);
      state = null;
    } else {
      await _prefs.setString(_localePrefsKey, locale.languageCode);
      state = locale;
    }

    // Sync to user profile if logged in
    if (syncToProfile) {
      await _syncLocaleToProfile(locale);
    }
  }

  /// Sync locale preference to user profile in Appwrite
  Future<void> _syncLocaleToProfile(Locale? locale) async {
    final currentUser = _ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      await AppwriteService.instance.databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'users',
        documentId: currentUser.$id,
        data: {
          'preferredLanguage': locale?.languageCode,
        },
      );
    } catch (e) {
      debugPrint('Error syncing locale to profile: $e');
    }
  }

  /// Check if a specific locale is selected (not system default)
  bool get isUsingSystemDefault => state == null;

  /// Reload locale from user profile (useful after login)
  Future<void> reloadFromProfile() async {
    await _loadLocale();
  }
}
