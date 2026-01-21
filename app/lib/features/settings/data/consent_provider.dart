import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/consent_model.dart';
import 'consent_repository.dart';

/// Provider pour le repository de consentement
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepository();
});

/// Provider pour verifier si un consentement local existe
final hasLocalConsentProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.hasLocalConsent();
});

/// Provider pour recuperer les preferences de consentement actuelles
final currentConsentPreferencesProvider =
    FutureProvider<ConsentPreferences?>((ref) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.getLocalConsent();
});

/// Provider pour recuperer le ConsentModel actuel (necessite un userId)
final currentConsentProvider =
    FutureProvider.family<ConsentModel?, String>((ref, userId) async {
  final repository = ref.watch(consentRepositoryProvider);
  return repository.getLocalConsentModel(userId);
});

/// Provider pour le consentement analytics
final analyticsConsentProvider =
    StateNotifierProvider<ConsentNotifier, bool>((ref) {
  return ConsentNotifier(ref, ConsentType.analytics);
});

/// Provider pour le consentement marketing
final marketingConsentProvider =
    StateNotifierProvider<ConsentNotifier, bool>((ref) {
  return ConsentNotifier(ref, ConsentType.marketing);
});

/// Notifier pour gerer un type de consentement individuel
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

/// Provider pour la gestion complete du consentement
final consentManagerProvider =
    AsyncNotifierProvider<ConsentManager, ConsentModel?>(() {
  return ConsentManager();
});

/// Manager pour la gestion du consentement RGPD
class ConsentManager extends AsyncNotifier<ConsentModel?> {
  ConsentRepository get _repository => ref.read(consentRepositoryProvider);

  @override
  Future<ConsentModel?> build() async {
    // Retourne null car on a besoin d'un userId pour creer un ConsentModel
    // Le ConsentModel sera charge via currentConsentProvider.family
    final prefs = await _repository.getLocalConsent();
    if (prefs == null) return null;
    // On utilise un userId generique pour le build initial
    return _repository.preferencesToModel(prefs, 'unknown');
  }

  /// Sauvegarde le consentement initial (premier lancement)
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
        // Invalider les providers pour forcer refresh
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

  /// Met a jour le consentement existant
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

  /// Efface le consentement (deconnexion ou suppression)
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
