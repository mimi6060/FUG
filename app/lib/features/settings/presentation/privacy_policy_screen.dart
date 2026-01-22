import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Privacy policy screen - RGPD compliant
///
/// Displays the complete privacy policy with all required RGPD information:
/// - Data controller identity
/// - Data collected and purposes
/// - Retention periods
/// - User rights
/// - Contact information
///
/// Also provides PDF download functionality.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  static const String policyVersion = '1.0';
  static const String lastUpdated = '21 janvier 2026';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Telecharger en PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with version info
            _VersionBanner(
              version: policyVersion,
              lastUpdated: lastUpdated,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),

            // Table of contents
            _TableOfContents(theme: theme, colorScheme: colorScheme),
            const SizedBox(height: 24),

            // Section 1: Who are we?
            _PolicySection(
              id: 'responsable',
              title: '1. Qui sommes-nous ?',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'FUG (Fous-toi Une Guinze) est une application mobile de reseau social geolocalisee, '
                      'editee par The Develobeers.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  colorScheme: colorScheme,
                  children: const [
                    _InfoRow(label: 'Editeur', value: 'The Develobeers'),
                    _InfoRow(
                      label: 'Contact',
                      value: 'privacy@fug.app',
                    ),
                    _InfoRow(
                      label: 'Siege social',
                      value: 'Belgique',
                    ),
                  ],
                ),
              ],
            ),

            // Section 2: What data do we collect?
            _PolicySection(
              id: 'donnees',
              title: '2. Quelles donnees collectons-nous ?',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'Nous collectons differentes categories de donnees pour fournir notre service:',
                ),
                const SizedBox(height: 12),
                _DataTable(colorScheme: colorScheme),
              ],
            ),

            // Section 3: Why do we collect this data?
            _PolicySection(
              id: 'finalites',
              title: '3. Pourquoi collectons-nous ces donnees ?',
              theme: theme,
              children: const [
                _PolicyParagraph(
                  text: 'Vos donnees sont utilisees pour:',
                ),
                SizedBox(height: 8),
                _BulletPoint(text: 'Gerer votre compte utilisateur'),
                _BulletPoint(
                  text:
                      'Permettre le fonctionnement du service (evenements, carte, recherche)',
                ),
                _BulletPoint(
                  text:
                      'Vous envoyer des notifications relatives a vos activites',
                ),
                _BulletPoint(
                  text:
                      'Ameliorer notre service via des statistiques anonymes (avec votre consentement)',
                ),
                _BulletPoint(
                  text: 'Assurer la securite et prevenir les fraudes',
                ),
              ],
            ),

            // Section 4: Legal basis
            _PolicySection(
              id: 'base-legale',
              title: '4. Sur quelle base legale ?',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'Conformement au RGPD, chaque traitement de donnees repose sur une base legale:',
                ),
                const SizedBox(height: 12),
                _LegalBasisTable(colorScheme: colorScheme),
              ],
            ),

            // Section 5: Retention periods
            _PolicySection(
              id: 'conservation',
              title: '5. Combien de temps conservons-nous vos donnees ?',
              theme: theme,
              children: [
                _RetentionTable(colorScheme: colorScheme),
              ],
            ),

            // Section 6: Data sharing
            _PolicySection(
              id: 'destinataires',
              title: '6. Avec qui partageons-nous vos donnees ?',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'Nous ne vendons jamais vos donnees personnelles. Elles peuvent etre partagees avec:',
                ),
                const SizedBox(height: 8),
                const _BulletPoint(
                  text:
                      'Notre hebergeur (Appwrite) pour le stockage securise des donnees',
                ),
                const _BulletPoint(
                  text:
                      'Les autres utilisateurs de FUG (uniquement les informations de profil public)',
                ),
                const _BulletPoint(
                  text:
                      'Les autorites competentes si requis par la loi',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  colorScheme: colorScheme,
                  children: const [
                    _InfoRow(
                      label: 'Transfert hors UE',
                      value: 'Non',
                    ),
                    _InfoRow(
                      label: 'Vente de donnees',
                      value: 'Jamais',
                    ),
                  ],
                ),
              ],
            ),

            // Section 7: User rights
            _PolicySection(
              id: 'droits',
              title: '7. Quels sont vos droits ?',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'Conformement au RGPD, vous disposez des droits suivants:',
                ),
                const SizedBox(height: 12),
                _UserRightsCard(colorScheme: colorScheme, theme: theme),
                const SizedBox(height: 16),
                const _PolicyParagraph(
                  text:
                      'Pour exercer vos droits, contactez-nous a privacy@fug.app ou utilisez '
                      'les fonctionnalites disponibles dans les parametres de l\'application.',
                ),
              ],
            ),

            // Section 8: Cookies and trackers
            _PolicySection(
              id: 'cookies',
              title: '8. Cookies et traceurs',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'L\'application mobile FUG utilise des identifiants techniques pour fonctionner:',
                ),
                const SizedBox(height: 12),
                _CookiesTable(colorScheme: colorScheme),
              ],
            ),

            // Section 9: Security
            _PolicySection(
              id: 'securite',
              title: '9. Comment protegeoons-nous vos donnees ?',
              theme: theme,
              children: const [
                _PolicyParagraph(
                  text: 'Nous mettons en oeuvre des mesures de securite appropriees:',
                ),
                SizedBox(height: 8),
                _BulletPoint(text: 'Chiffrement des donnees en transit (HTTPS/TLS)'),
                _BulletPoint(text: 'Chiffrement des mots de passe (bcrypt)'),
                _BulletPoint(text: 'Controle d\'acces strict aux donnees'),
                _BulletPoint(text: 'Journalisation des acces'),
                _BulletPoint(text: 'Mises a jour regulieres de securite'),
              ],
            ),

            // Section 10: Modifications
            _PolicySection(
              id: 'modifications',
              title: '10. Modifications de cette politique',
              theme: theme,
              children: const [
                _PolicyParagraph(
                  text:
                      'Nous pouvons mettre a jour cette politique de confidentialite. '
                      'En cas de modification substantielle, vous serez informe(e) par '
                      'notification dans l\'application au moins 30 jours avant l\'entree en vigueur.',
                ),
                SizedBox(height: 12),
                _PolicyParagraph(
                  text:
                      'L\'historique des versions est disponible sur demande.',
                ),
              ],
            ),

            // Section 11: Contact
            _PolicySection(
              id: 'contact',
              title: '11. Nous contacter',
              theme: theme,
              children: [
                const _PolicyParagraph(
                  text:
                      'Pour toute question concernant cette politique ou vos donnees personnelles:',
                ),
                const SizedBox(height: 12),
                _ContactCard(colorScheme: colorScheme),
              ],
            ),

            const SizedBox(height: 32),

            // Download PDF button
            Center(
              child: FilledButton.icon(
                onPressed: () => _downloadPdf(context),
                icon: const Icon(Icons.download),
                label: const Text('Telecharger en PDF'),
              ),
            ),

            const SizedBox(height: 16),

            // Version history link
            Center(
              child: TextButton(
                onPressed: () => _showVersionHistory(context),
                child: const Text('Voir l\'historique des versions'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _downloadPdf(BuildContext context) {
    // TODO: Implement PDF download
    // For MVP, show coming soon message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Telechargement PDF bientot disponible'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVersionHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des versions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Version 1.0'),
              subtitle: Text('21 janvier 2026 - Version initiale'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Private Widgets
// =============================================================================

class _VersionBanner extends StatelessWidget {
  final String version;
  final String lastUpdated;
  final ColorScheme colorScheme;

  const _VersionBanner({
    required this.version,
    required this.lastUpdated,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version $version',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Derniere mise a jour: $lastUpdated',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableOfContents extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _TableOfContents({
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sommaire',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const _TocItem(number: '1', title: 'Qui sommes-nous ?'),
          const _TocItem(number: '2', title: 'Quelles donnees collectons-nous ?'),
          const _TocItem(number: '3', title: 'Pourquoi collectons-nous ces donnees ?'),
          const _TocItem(number: '4', title: 'Sur quelle base legale ?'),
          const _TocItem(number: '5', title: 'Combien de temps conservons-nous vos donnees ?'),
          const _TocItem(number: '6', title: 'Avec qui partageons-nous vos donnees ?'),
          const _TocItem(number: '7', title: 'Quels sont vos droits ?'),
          const _TocItem(number: '8', title: 'Cookies et traceurs'),
          const _TocItem(number: '9', title: 'Comment protegeons-nous vos donnees ?'),
          const _TocItem(number: '10', title: 'Modifications de cette politique'),
          const _TocItem(number: '11', title: 'Nous contacter'),
        ],
      ),
    );
  }
}

class _TocItem extends StatelessWidget {
  final String number;
  final String title;

  const _TocItem({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String id;
  final String title;
  final ThemeData theme;
  final List<Widget> children;

  const _PolicySection({
    required this.id,
    required this.title,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  final String text;

  const _PolicyParagraph({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  \u2022  '),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Widget> children;

  const _InfoCard({
    required this.colorScheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DataTable extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DataTable({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DataTableHeader(colorScheme: colorScheme),
          _DataTableRow(
            category: 'Identite',
            data: 'Email, pseudo, nom',
            purpose: 'Compte utilisateur',
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: 'Profil',
            data: 'Photo, bio',
            purpose: 'Personnalisation',
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: 'Localisation',
            data: 'Position GPS',
            purpose: 'Fonctionnalite principale',
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: 'Activite',
            data: 'Evenements, participations',
            purpose: 'Service',
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DataTableHeader extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DataTableHeader({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Categorie',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Donnees',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Finalite',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataTableRow extends StatelessWidget {
  final String category;
  final String data;
  final String purpose;
  final ColorScheme colorScheme;
  final bool isLast;

  const _DataTableRow({
    required this.category,
    required this.data,
    required this.purpose,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(category)),
          Expanded(flex: 3, child: Text(data)),
          Expanded(flex: 3, child: Text(purpose)),
        ],
      ),
    );
  }
}

class _LegalBasisTable extends StatelessWidget {
  final ColorScheme colorScheme;

  const _LegalBasisTable({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Traitement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Base legale',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _LegalBasisRow(
            treatment: 'Gestion du compte',
            basis: 'Execution du contrat',
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: 'Geolocalisation',
            basis: 'Consentement',
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: 'Analytics',
            basis: 'Consentement',
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: 'Securite',
            basis: 'Interet legitime',
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _LegalBasisRow extends StatelessWidget {
  final String treatment;
  final String basis;
  final ColorScheme colorScheme;
  final bool isLast;

  const _LegalBasisRow({
    required this.treatment,
    required this.basis,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(treatment)),
          Expanded(child: Text(basis)),
        ],
      ),
    );
  }
}

class _RetentionTable extends StatelessWidget {
  final ColorScheme colorScheme;

  const _RetentionTable({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Donnee',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Duree',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _RetentionRow(
            data: 'Compte actif',
            duration: 'Duree du compte',
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: 'Compte supprime',
            duration: '30 jours puis anonymisation',
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: 'Logs techniques',
            duration: '12 mois',
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: 'Donnees anonymisees',
            duration: 'Illimitee',
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _RetentionRow extends StatelessWidget {
  final String data;
  final String duration;
  final ColorScheme colorScheme;
  final bool isLast;

  const _RetentionRow({
    required this.data,
    required this.duration,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(data)),
          Expanded(child: Text(duration)),
        ],
      ),
    );
  }
}

class _UserRightsCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _UserRightsCard({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _RightTile(
            icon: Icons.visibility,
            title: 'Droit d\'acces',
            description: 'Obtenir une copie de vos donnees',
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.edit,
            title: 'Droit de rectification',
            description: 'Corriger vos informations',
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.delete,
            title: 'Droit a l\'effacement',
            description: 'Supprimer votre compte et vos donnees',
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.download,
            title: 'Droit a la portabilite',
            description: 'Exporter vos donnees',
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.block,
            title: 'Droit d\'opposition',
            description: 'Refuser certains traitements',
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.undo,
            title: 'Retrait du consentement',
            description: 'Modifier vos preferences a tout moment',
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _RightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;
  final bool isLast;

  const _RightTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CookiesTable extends StatelessWidget {
  final ColorScheme colorScheme;

  const _CookiesTable({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Traceur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Finalite',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Consentement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _CookieRow(
            tracker: 'Session',
            purpose: 'Authentification',
            consent: 'Non requis',
            colorScheme: colorScheme,
          ),
          _CookieRow(
            tracker: 'Preferences',
            purpose: 'Theme, langue',
            consent: 'Non requis',
            colorScheme: colorScheme,
          ),
          _CookieRow(
            tracker: 'Analytics',
            purpose: 'Statistiques',
            consent: 'Requis',
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _CookieRow extends StatelessWidget {
  final String tracker;
  final String purpose;
  final String consent;
  final ColorScheme colorScheme;
  final bool isLast;

  const _CookieRow({
    required this.tracker,
    required this.purpose,
    required this.consent,
    required this.colorScheme,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(tracker)),
          Expanded(flex: 3, child: Text(purpose)),
          Expanded(flex: 2, child: Text(consent)),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ContactCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.email, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text('privacy@fug.app'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delai de reponse',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text('Nous vous repondrons sous 30 jours maximum'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
