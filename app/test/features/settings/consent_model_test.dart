import 'package:flutter_test/flutter_test.dart';
import 'package:fug_app/features/settings/domain/consent_model.dart';

void main() {
  group('ConsentModel', () {
    group('constructor', () {
      test('should create with required values', () {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        expect(consent.userId, 'user123');
        expect(consent.essentialConsent, true);
        expect(consent.analyticsConsent, true);
        expect(consent.marketingConsent, false);
        expect(consent.policyVersion, '1.0');
      });

      test('should have essentialConsent always true by default', () {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        expect(consent.essentialConsent, true);
      });
    });

    group('initial factory', () {
      test('should create with default values for new user', () {
        final consent = ConsentModel.initial('user123');

        expect(consent.userId, 'user123');
        expect(consent.essentialConsent, true);
        expect(consent.analyticsConsent, false);
        expect(consent.marketingConsent, false);
        expect(consent.policyVersion, '1.0');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON', () {
        final json = {
          'userId': 'user123',
          'essentialConsent': true,
          'analyticsConsent': true,
          'marketingConsent': false,
          'consentDate': '2026-01-21T10:00:00.000Z',
          'lastUpdated': '2026-01-21T10:00:00.000Z',
          'policyVersion': '1.0',
        };

        final consent = ConsentModel.fromJson(json);

        expect(consent.userId, 'user123');
        expect(consent.essentialConsent, true);
        expect(consent.analyticsConsent, true);
        expect(consent.marketingConsent, false);
        expect(consent.policyVersion, '1.0');
      });

      test('should use defaults for missing optional values', () {
        final json = {
          'userId': 'user123',
          'consentDate': '2026-01-21T10:00:00.000Z',
          'lastUpdated': '2026-01-21T10:00:00.000Z',
        };

        final consent = ConsentModel.fromJson(json);

        expect(consent.essentialConsent, true);
        expect(consent.analyticsConsent, false);
        expect(consent.marketingConsent, false);
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: true,
          consentDate: DateTime(2026, 1, 21, 10, 0, 0),
          lastUpdated: DateTime(2026, 1, 21, 10, 0, 0),
          policyVersion: '1.0',
        );

        final json = consent.toJson();

        expect(json['userId'], 'user123');
        expect(json['essentialConsent'], true);
        expect(json['analyticsConsent'], true);
        expect(json['marketingConsent'], true);
        expect(json['policyVersion'], '1.0');
        expect(json['consentDate'], contains('2026-01-21'));
        expect(json['lastUpdated'], contains('2026-01-21'));
      });
    });

    group('copyWith', () {
      test('should copy with new analytics value', () {
        final now = DateTime.now();
        final original = ConsentModel(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        final updated = original.copyWith(analyticsConsent: true);

        expect(updated.analyticsConsent, true);
        expect(updated.marketingConsent, false);
        expect(updated.essentialConsent, true);
        expect(updated.userId, 'user123');
      });

      test('should copy with new marketing value', () {
        final now = DateTime.now();
        final original = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        final updated = original.copyWith(marketingConsent: true);

        expect(updated.analyticsConsent, true);
        expect(updated.marketingConsent, true);
      });

      test('should preserve unchanged values', () {
        final date = DateTime(2026, 1, 21);
        final original = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: true,
          consentDate: date,
          lastUpdated: date,
          policyVersion: '1.0',
        );

        final updated = original.copyWith(analyticsConsent: false);

        expect(updated.analyticsConsent, false);
        expect(updated.marketingConsent, true);
        expect(updated.consentDate, date);
        expect(updated.policyVersion, '1.0');
        expect(updated.userId, 'user123');
      });
    });

    group('hasConsented', () {
      test('should return true for consent after 2020', () {
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: false,
          consentDate: DateTime(2026, 1, 21),
          lastUpdated: DateTime(2026, 1, 21),
        );

        expect(consent.hasConsented, true);
      });
    });

    group('hasAllConsents', () {
      test('should return true when all optional consents are given', () {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          essentialConsent: true,
          analyticsConsent: true,
          marketingConsent: true,
          consentDate: now,
          lastUpdated: now,
        );

        expect(consent.hasAllConsents, true);
      });

      test('should return false when analytics is false', () {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: true,
          consentDate: now,
          lastUpdated: now,
        );

        expect(consent.hasAllConsents, false);
      });

      test('should return false when marketing is false', () {
        final now = DateTime.now();
        final consent = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: now,
          lastUpdated: now,
        );

        expect(consent.hasAllConsents, false);
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final date = DateTime(2026, 1, 21);
        final consent1 = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: date,
          lastUpdated: date,
        );
        final consent2 = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: date,
          lastUpdated: date,
        );

        expect(consent1, equals(consent2));
      });

      test('should not be equal for different values', () {
        final date = DateTime(2026, 1, 21);
        final consent1 = ConsentModel(
          userId: 'user123',
          analyticsConsent: true,
          marketingConsent: false,
          consentDate: date,
          lastUpdated: date,
        );
        final consent2 = ConsentModel(
          userId: 'user123',
          analyticsConsent: false,
          marketingConsent: false,
          consentDate: date,
          lastUpdated: date,
        );

        expect(consent1, isNot(equals(consent2)));
      });
    });

    group('ConsentType enum', () {
      test('should have all consent types', () {
        expect(ConsentType.values, contains(ConsentType.essential));
        expect(ConsentType.values, contains(ConsentType.analytics));
        expect(ConsentType.values, contains(ConsentType.marketing));
      });
    });
  });
}
