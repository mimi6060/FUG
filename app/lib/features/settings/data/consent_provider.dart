import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/consent_model.dart';
import 'consent_repository.dart';

/// Provider for consent repository
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepository();
});

/// Provider to check if local consent exists
final hasLocalConsentProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.hasLocalConsent();
});

/// Provider to retrieve current consent preferences
final currentConsentPreferencesProvider =
    FutureProvider<ConsentPreferences?>((ref) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.getLocalConsent();
});

/// Provider to retrieve current ConsentModel (requires userId)
final currentConsentProvider =
    FutureProvider.family<ConsentModel?, String>((ref, userId) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.getLocalConsentModel(userId);
});

/// Provider for analytics consent
final analyticsConsentProvider =
    StateNotifierProvider<ConsentNotifier, bool>((ref) {
  return ConsentNotifier(ref, ConsentType.analytics);
});

/// Provider for marketing consent
final marketingConsentProvider =
    StateNotifierProvider<ConsentNotifier, bool>((ref) {
  return ConsentNotifier(ref, ConsentType.marketing);
});

/// Notifier to manage individual consent type
class ConsentNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final ConsentType _type;

  ConsentNotifier(this._ref, this._type) : super(false) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await _ref.read(currentConsentPreferencesProvider.future);
    if (prefs != null) {
      state = _type == ConsentType.analytics ? prefs.analytics : prefs.marketing;
    }
  }

  void set(bool? value) {
    if (value != null) {
      state = value;
    }
  }
}

/// Provider for complete consent management
final consentManagerProvider =
    AsyncNotifierProvider<ConsentManager, ConsentModel?>(() {
  return ConsentManager();
});

/// Manager for GDPR consent management
class ConsentManager extends AsyncNotifier<ConsentModel?> {
  ConsentRepository get _repository => ref.read(consentRepositoryProvider);

  @override
  Future<ConsentModel?> build() async {
    // Returns null because we need a userId to create a ConsentModel
    // ConsentModel will be loaded via currentConsentProvider.family
    final prefs = await _repository.getLocalConsent();
    if (prefs == null) return null;
    // Use a generic userId for initial build
    return _repository.preferencesToModel(prefs, 'unknown');
  }

  /// Saves initial consent (first launch)
  Future<bool> saveInitialConsent({
    required String userId,
    required bool analyticsConsent,
    required bool marketingConsent,
  }) async {
    state = const AsyncValue.loading();

    try {
      final consent = await _repository.createInitialConsent(
        userId: userId,
        analyticsConsent: analyticsConsent,
        marketingConsent: marketingConsent,
      );

      if (consent != null) {
        state = AsyncValue.data(consent);
        // Invalidate providers to force refresh
        ref.invalidate(hasLocalConsentProvider);
        ref.invalidate(currentConsentPreferencesProvider);
        return true;
      }

      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Updates existing consent
  Future<bool> updateConsent({
    required String userId,
    bool? analyticsConsent,
    bool? marketingConsent,
  }) async {
    state = const AsyncValue.loading();

    try {
      final consent = await _repository.updateConsent(
        userId: userId,
        analyticsConsent: analyticsConsent,
        marketingConsent: marketingConsent,
      );

      if (consent != null) {
        state = AsyncValue.data(consent);
        ref.invalidate(currentConsentPreferencesProvider);
        return true;
      }

      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Clears consent (logout or deletion)
  Future<bool> clearConsent() async {
    state = const AsyncValue.loading();

    try {
      final cleared = await _repository.clearLocalConsent();
      if (cleared) {
        state = const AsyncValue.data(null);
        ref.invalidate(hasLocalConsentProvider);
        ref.invalidate(currentConsentPreferencesProvider);
      }
      return cleared;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
