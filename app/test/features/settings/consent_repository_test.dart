import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fug_app/features/settings/domain/consent_model.dart';
import 'package:fug_app/features/settings/data/consent_repository.dart';

void main() {
  group('ConsentPreferences', () {
    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'analytics': true,
          'marketing': false,
          'consentDate': '2026-01-21T10:00:00.000Z',
          'policyVersion': '1.0',
        };

        final prefs = ConsentPreferences.fromJson(json);

        expect(prefs.analytics, true);
        expect(prefs.marketing, false);
        expect(prefs.policyVersion, '1.0');
      });

      test('should use defaults for missing optional values', () {
        final json = {
          'consentDate': '2026-01-21T10:00:00.000Z',
        };

        final prefs = ConsentPreferences.fromJson(json);

        expect(prefs.analytics, false);
        expect(prefs.marketing, false);
        expect(prefs.policyVersion, '1.0');
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final prefs = ConsentPreferences(
          analytics: true,
          marketing: true,
          consentDate: DateTime(2026, 1, 21, 10, 0, 0),
          policyVersion: '1.0',
        );

        final json = prefs.toJson();

        expect(json['analytics'], true);
        expect(json['marketing'], true);
        expect(json['policyVersion'], '1.0');
        expect(json['consentDate'], contains('2026-01-21'));
      });
    });
  });

  group('ConsentRepository', () {
    late ConsentRepository repository;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = ConsentRepository(prefs: prefs);
    });

    group('hasLocalConsent', () {
      test('should return false when no consent stored', () async {
        final hasConsent = await repository.hasLocalConsent();

        expect(hasConsent, false);
      });

      test('should return true after saving consent', () async {
        final consent = ConsentPreferences(
          analytics: true,
          marketing: false,
          consentDate: DateTime.now(),
        );

        await repository.saveLocalConsent(consent);
        final hasConsent = await repository.hasLocalConsent();

        expect(hasConsent, true);
      });
    });

    group('saveLocalConsent', () {
      test('should save consent successfully', () async {
        final consent = ConsentPreferences(
          analytics: true,
          marketing: true,
          consentDate: DateTime.now(),
        );

        final result = await repository.saveLocalConsent(consent);

        expect(result, true);
      });
    });

    group('getLocalConsent', () {
      test('should return null when no consent stored', () async {
        final consent = await repository.getLocalConsent();

        expect(consent, null);
      });

      test('should return stored consent', () async {
        final original = ConsentPreferences(
          analytics: true,
          marketing: false,
          consentDate: DateTime.now(),
          policyVersion: '1.0',
        );

        await repository.saveLocalConsent(original);
        final retrieved = await repository.getLocalConsent();

        expect(retrieved, isNotNull);
        expect(retrieved!.analytics, true);
        expect(retrieved.marketing, false);
        expect(retrieved.policyVersion, '1.0');
      });
    });

    group('isConsentRequired', () {
      test('should return true when no consent stored', () async {
        final required = await repository.isConsentRequired();

        expect(required, true);
      });

      test('should return false when consent stored', () async {
        final consent = ConsentPreferences(
          analytics: false,
          marketing: false,
          consentDate: DateTime.now(),
        );

        await repository.saveLocalConsent(consent);
        final required = await repository.isConsentRequired();

        expect(required, false);
      });
    });

    group('createInitialConsent', () {
      test('should create and save initial consent', () async {
        final consent = await repository.createInitialConsent(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
        );

        expect(consent, isNotNull);
        expect(consent!.userId, 'user123');
        expect(consent.essentialConsent, true);
        expect(consent.analyticsConsent, true);
        expect(consent.marketingConsent, false);
        expect(consent.policyVersion, '1.0');

        // Verify it was saved
        final hasConsent = await repository.hasLocalConsent();
        expect(hasConsent, true);
      });
    });

    group('updateConsent', () {
      test('should update existing consent', () async {
        // Create initial consent
        await repository.createInitialConsent(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: false,
        );

        // Update consent
        final updated = await repository.updateConsent(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: true,
        );

        expect(updated, isNotNull);
        expect(updated!.analyticsConsent, true);
        expect(updated.marketingConsent, true);
      });

      test('should create new consent if none exists', () async {
        final consent = await repository.updateConsent(
          userId: 'user123',
          analyticsConsent: true,
        );

        expect(consent, isNotNull);
        expect(consent!.userId, 'user123');
        expect(consent.analyticsConsent, true);
        expect(consent.marketingConsent, false);
      });
    });

    group('getLocalConsentModel', () {
      test('should return null when no consent stored', () async {
        final consent = await repository.getLocalConsentModel('user123');

        expect(consent, null);
      });

      test('should return ConsentModel with userId', () async {
        // Save preferences first
        final prefs = ConsentPreferences(
          analytics: true,
          marketing: false,
          consentDate: DateTime.now(),
        );
        await repository.saveLocalConsent(prefs);

        // Get as model
        final model = await repository.getLocalConsentModel('user123');

        expect(model, isNotNull);
        expect(model!.userId, 'user123');
        expect(model.analyticsConsent, true);
        expect(model.marketingConsent, false);
      });
    });

    group('preferencesToModel', () {
      test('should convert preferences to model', () {
        final prefs = ConsentPreferences(
          analytics: true,
          marketing: false,
          consentDate: DateTime(2026, 1, 21),
          policyVersion: '1.0',
        );

        final model = repository.preferencesToModel(prefs, 'user123');

        expect(model, isNotNull);
        expect(model!.userId, 'user123');
        expect(model.essentialConsent, true);
        expect(model.analyticsConsent, true);
        expect(model.marketingConsent, false);
        expect(model.policyVersion, '1.0');
      });

      test('should return null for null preferences', () {
        final model = repository.preferencesToModel(null, 'user123');

        expect(model, null);
      });
    });

    group('modelToPreferences', () {
      test('should convert model to preferences', () {
        final now = DateTime.now();
        final model = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
          policyVersion: '1.0',
        );

        final prefs = repository.modelToPreferences(model);

        expect(prefs.analytics, true);
        expect(prefs.marketing, false);
        expect(prefs.policyVersion, '1.0');
      });
    });

    group('clearLocalConsent', () {
      test('should clear stored consent', () async {
        final consent = ConsentPreferences(
          analytics: true,
          marketing: true,
          consentDate: DateTime.now(),
        );

        await repository.saveLocalConsent(consent);
        expect(await repository.hasLocalConsent(), true);

        await repository.clearLocalConsent();
        expect(await repository.hasLocalConsent(), false);
        expect(await repository.getLocalConsent(), null);
      });
    });
  });

  group('ConsentException', () {
    test('should create exception with message', () {
      final exception = ConsentException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.code, null);
    });

    test('should create exception with message and code', () {
      final exception = ConsentException('Test error', code: 500);

      expect(exception.message, 'Test error');
      expect(exception.code, 500);
    });

    test('toString should include message', () {
      final exception = ConsentException('Test error');

      expect(exception.toString(), 'ConsentException: Test error');
    });
  });
}
