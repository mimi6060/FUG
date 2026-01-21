import 'package:equatable/equatable.dart';

/// GDPR consent types
enum ConsentType {
  /// Essential data for app functionality (required)
  essential,

  /// Analytics to improve the application
  analytics,

  /// Marketing communications
  marketing,
}

/// Model representing user GDPR consent
///
/// Stores consent preferences with timestamps
/// for GDPR Article 7 compliance.
class ConsentModel extends Equatable {
  /// User ID
  final String userId;

  /// Consent for essential data (always true)
  final bool essentialConsent;

  /// Consent for analytics
  final bool analyticsConsent;

  /// Consent for marketing
  final bool marketingConsent;

  /// Date of first consent
  final DateTime consentDate;

  /// Date of last modification
  final DateTime lastUpdated;

  /// Version of accepted privacy policy
  final String policyVersion;

  const ConsentModel({
    required this.userId,
    this.essentialConsent = true,
    this.analyticsConsent = false,
    this.marketingConsent = false,
    required this.consentDate,
    required this.lastUpdated,
    this.policyVersion = '1.0',
  });

  /// Creates a default ConsentModel for a new user
  factory ConsentModel.initial(String userId) {
    final now = DateTime.now();
    return ConsentModel(
      userId: userId,
      essentialConsent: true,
      analyticsConsent: false,
      marketingConsent: false,
      consentDate: now,
      lastUpdated: now,
      policyVersion: '1.0',
    );
  }

  /// Creates a ConsentModel from a JSON Map
  factory ConsentModel.fromJson(Map<String, dynamic> json) {
    return ConsentModel(
      userId: json['userId'] as String,
      essentialConsent: json['essentialConsent'] as bool? ?? true,
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      consentDate: DateTime.parse(json['consentDate'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      policyVersion: json['policyVersion'] as String? ?? '1.0',
    );
  }

  /// Converts the ConsentModel to a JSON Map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'essentialConsent': essentialConsent,
      'analyticsConsent': analyticsConsent,
      'marketingConsent': marketingConsent,
      'consentDate': consentDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'policyVersion': policyVersion,
    };
  }

  /// Creates a copy with modified values
  ConsentModel copyWith({
    String? userId,
    bool? essentialConsent,
    bool? analyticsConsent,
    bool? marketingConsent,
    DateTime? consentDate,
    DateTime? lastUpdated,
    String? policyVersion,
  }) {
    return ConsentModel(
      userId: userId ?? this.userId,
      essentialConsent: essentialConsent ?? this.essentialConsent,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      consentDate: consentDate ?? this.consentDate,
      lastUpdated: lastUpdated ?? DateTime.now(),
      policyVersion: policyVersion ?? this.policyVersion,
    );
  }

  /// Checks if consent has been given
  bool get hasConsented => consentDate.isAfter(DateTime(2020));

  /// Checks if all optional consents are accepted
  bool get hasAllConsents => analyticsConsent && marketingConsent;

  @override
  List<Object?> get props => [
        userId,
        essentialConsent,
        analyticsConsent,
        marketingConsent,
        consentDate,
        lastUpdated,
        policyVersion,
      ];

  @override
  String toString() =>
      'ConsentModel(userId: $userId, analytics: $analyticsConsent, marketing: $marketingConsent)';
}
