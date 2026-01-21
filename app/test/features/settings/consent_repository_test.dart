import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fug_app/features/settings/domain/consent_model.dart';
import 'package:fug_app/features/settings/data/consent_repository.dart';

void main() {
  group('ConsentRepository', () {
    late ConsentRepository repository;

    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
      repository = ConsentRepository();
    });

    group('hasLocalConsent', () {
      test('should return false when no consent stored', () async {
        final hasConsent = await repository.hasLocalConsent();

        expect(hasConsent, false);
      });

      test('should return true after saving consent', () async {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        await repository.saveLocalConsent(consent);
        final hasConsent = await repository.hasLocalConsent();

        expect(hasConsent, true);
      });
    });

    group('saveLocalConsent', () {
      test('should save consent successfully', () async {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: true,
          consentDate: now,
          lastUpdated: now,
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
        final now = DateTime.now();
        final original = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
          policyVersion: '1.0',
        );

        await repository.saveLocalConsent(original);
        final retrieved = await repository.getLocalConsent();

        expect(retrieved, isNotNull);
        expect(retrieved!.userId, 'user123');
        expect(retrieved.analyticsConsent, true);
        expect(retrieved.marketingConsent, false);
        expect(retrieved.policyVersion, '1.0');
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

    group('clearLocalConsent', () {
      test('should clear stored consent', () async {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: true,
          consentDate: now,
          lastUpdated: now,
        );

        await repository.saveLocalConsent(consent);
        expect(await repository.hasLocalConsent(), true);

        await repository.clearLocalConsent();
        expect(await repository.hasLocalConsent(), false);
        expect(await repository.getLocalConsent(), null);
      });
    });
  });
}
