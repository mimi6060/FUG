import 'package:equatable/equatable.dart';

/// Types de consentement RGPD
enum ConsentType {
  /// Donnees essentielles au fonctionnement (obligatoire)
  essential,

  /// Analytics pour ameliorer l'application
  analytics,

  /// Communications marketing
  marketing,
}

/// Modele representant le consentement utilisateur RGPD
///
/// Stocke les preferences de consentement avec horodatage
/// pour conformite RGPD Article 7.
class ConsentModel extends Equatable {
  /// ID de l'utilisateur
  final String userId;

  /// Consentement pour les donnees essentielles (toujours true)
  final bool essentialConsent;

  /// Consentement pour les analytics
  final bool analyticsConsent;

  /// Consentement pour le marketing
  final bool marketingConsent;

  /// Date du premier consentement
  final DateTime consentDate;

  /// Date de la derniere modification
  final DateTime lastUpdated;

  /// Version de la politique de confidentialite acceptee
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

  /// Cree un ConsentModel par defaut pour un nouvel utilisateur
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

  /// Cree un ConsentModel a partir d'un Map JSON
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

  /// Convertit le ConsentModel en Map JSON
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

  /// Cree une copie avec des valeurs modifiees
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

  /// Verifie si le consentement a ete donne
  bool get hasConsented => consentDate.isAfter(DateTime(2020));

  /// Verifie si tous les consentements optionnels sont acceptes
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
