import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ppTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.ppDownloadPdf,
            onPressed: () => _downloadPdf(context, l10n),
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
              l10n: l10n,
            ),
            const SizedBox(height: 24),

            // Table of contents
            _TableOfContents(theme: theme, colorScheme: colorScheme, l10n: l10n),
            const SizedBox(height: 24),

            // Section 1: Who are we?
            _PolicySection(
              id: 'responsable',
              title: l10n.ppSection1Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection1Content),
                const SizedBox(height: 12),
                _InfoCard(
                  colorScheme: colorScheme,
                  children: [
                    _InfoRow(label: l10n.ppPublisher, value: 'The Develobeers'),
                    _InfoRow(label: l10n.ppContact, value: 'privacy@fug.app'),
                    _InfoRow(label: l10n.ppHeadquarters, value: 'Belgique'),
                  ],
                ),
              ],
            ),

            // Section 2: What data do we collect?
            _PolicySection(
              id: 'donnees',
              title: l10n.ppSection2Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection2Content),
                const SizedBox(height: 12),
                _DataTable(colorScheme: colorScheme, l10n: l10n),
              ],
            ),

            // Section 3: Why do we collect this data?
            _PolicySection(
              id: 'finalites',
              title: l10n.ppSection3Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection3Content),
                const SizedBox(height: 8),
                _BulletPoint(text: l10n.ppSection3Item1),
                _BulletPoint(text: l10n.ppSection3Item2),
                _BulletPoint(text: l10n.ppSection3Item3),
                _BulletPoint(text: l10n.ppSection3Item4),
                _BulletPoint(text: l10n.ppSection3Item5),
              ],
            ),

            // Section 4: Legal basis
            _PolicySection(
              id: 'base-legale',
              title: l10n.ppSection4Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection4Content),
                const SizedBox(height: 12),
                _LegalBasisTable(colorScheme: colorScheme, l10n: l10n),
              ],
            ),

            // Section 5: Retention periods
            _PolicySection(
              id: 'conservation',
              title: l10n.ppSection5Title,
              theme: theme,
              children: [
                _RetentionTable(colorScheme: colorScheme, l10n: l10n),
              ],
            ),

            // Section 6: Data sharing
            _PolicySection(
              id: 'destinataires',
              title: l10n.ppSection6Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection6Content),
                const SizedBox(height: 8),
                _BulletPoint(text: l10n.ppSection6Item1),
                _BulletPoint(text: l10n.ppSection6Item2),
                _BulletPoint(text: l10n.ppSection6Item3),
                const SizedBox(height: 12),
                _InfoCard(
                  colorScheme: colorScheme,
                  children: [
                    _InfoRow(label: l10n.ppTransferOutsideEU, value: l10n.ppTransferOutsideEUValue),
                    _InfoRow(label: l10n.ppDataSale, value: l10n.ppDataSaleValue),
                  ],
                ),
              ],
            ),

            // Section 7: User rights
            _PolicySection(
              id: 'droits',
              title: l10n.ppSection7Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection7Content),
                const SizedBox(height: 12),
                _UserRightsCard(colorScheme: colorScheme, theme: theme, l10n: l10n),
                const SizedBox(height: 16),
                _PolicyParagraph(text: l10n.ppSection7Footer),
              ],
            ),

            // Section 8: Cookies and trackers
            _PolicySection(
              id: 'cookies',
              title: l10n.ppSection8Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection8Content),
                const SizedBox(height: 12),
                _CookiesTable(colorScheme: colorScheme, l10n: l10n),
              ],
            ),

            // Section 9: Security
            _PolicySection(
              id: 'securite',
              title: l10n.ppSection9Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection9Content),
                const SizedBox(height: 8),
                _BulletPoint(text: l10n.ppSection9Item1),
                _BulletPoint(text: l10n.ppSection9Item2),
                _BulletPoint(text: l10n.ppSection9Item3),
                _BulletPoint(text: l10n.ppSection9Item4),
                _BulletPoint(text: l10n.ppSection9Item5),
              ],
            ),

            // Section 10: Modifications
            _PolicySection(
              id: 'modifications',
              title: l10n.ppSection10Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection10Content1),
                const SizedBox(height: 12),
                _PolicyParagraph(text: l10n.ppSection10Content2),
              ],
            ),

            // Section 11: Contact
            _PolicySection(
              id: 'contact',
              title: l10n.ppSection11Title,
              theme: theme,
              children: [
                _PolicyParagraph(text: l10n.ppSection11Content),
                const SizedBox(height: 12),
                _ContactCard(colorScheme: colorScheme, l10n: l10n),
              ],
            ),

            const SizedBox(height: 32),

            // Download PDF button
            Center(
              child: FilledButton.icon(
                onPressed: () => _downloadPdf(context, l10n),
                icon: const Icon(Icons.download),
                label: Text(l10n.ppDownloadPdf),
              ),
            ),

            const SizedBox(height: 16),

            // Version history link
            Center(
              child: TextButton(
                onPressed: () => _showVersionHistory(context, l10n),
                child: Text(l10n.ppVersionHistory),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _downloadPdf(BuildContext context, AppLocalizations l10n) {
    // TODO: Implement PDF download
    // For MVP, show coming soon message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.ppDownloadPdfSoon),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVersionHistory(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ppVersionHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(l10n.ppVersion('1.0')),
              subtitle: Text('21 janvier 2026 - ${l10n.ppInitialVersion}'),
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
  final AppLocalizations l10n;

  const _VersionBanner({
    required this.version,
    required this.lastUpdated,
    required this.colorScheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withAlpha(51)),
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
                  l10n.ppVersion(version),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  l10n.ppLastUpdated(lastUpdated),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer.withAlpha(204),
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
  final AppLocalizations l10n;

  const _TableOfContents({
    required this.theme,
    required this.colorScheme,
    required this.l10n,
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
            l10n.ppTableOfContents,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _TocItem(number: '1', title: l10n.ppSection1Title.substring(3)),
          _TocItem(number: '2', title: l10n.ppSection2Title.substring(3)),
          _TocItem(number: '3', title: l10n.ppSection3Title.substring(3)),
          _TocItem(number: '4', title: l10n.ppSection4Title.substring(3)),
          _TocItem(number: '5', title: l10n.ppSection5Title.substring(3)),
          _TocItem(number: '6', title: l10n.ppSection6Title.substring(3)),
          _TocItem(number: '7', title: l10n.ppSection7Title.substring(3)),
          _TocItem(number: '8', title: l10n.ppSection8Title.substring(3)),
          _TocItem(number: '9', title: l10n.ppSection9Title.substring(3)),
          _TocItem(number: '10', title: l10n.ppSection10Title.substring(4)),
          _TocItem(number: '11', title: l10n.ppSection11Title.substring(4)),
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
  final AppLocalizations l10n;

  const _DataTable({required this.colorScheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DataTableHeader(colorScheme: colorScheme, l10n: l10n),
          _DataTableRow(
            category: l10n.ppDataIdentity,
            data: l10n.ppDataIdentityData,
            purpose: l10n.ppDataIdentityPurpose,
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: l10n.ppDataProfile,
            data: l10n.ppDataProfileData,
            purpose: l10n.ppDataProfilePurpose,
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: l10n.ppDataLocation,
            data: l10n.ppDataLocationData,
            purpose: l10n.ppDataLocationPurpose,
            colorScheme: colorScheme,
          ),
          _DataTableRow(
            category: l10n.ppDataActivity,
            data: l10n.ppDataActivityData,
            purpose: l10n.ppDataActivityPurpose,
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
  final AppLocalizations l10n;

  const _DataTableHeader({required this.colorScheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(77),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              l10n.ppDataCategory,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.ppDataData,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.ppDataPurpose,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
  final AppLocalizations l10n;

  const _LegalBasisTable({required this.colorScheme, required this.l10n});

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
              color: colorScheme.primaryContainer.withAlpha(77),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ppLegalTreatment,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.ppLegalBasis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _LegalBasisRow(
            treatment: l10n.ppLegalAccount,
            basis: l10n.ppLegalAccountBasis,
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: l10n.ppLegalGeo,
            basis: l10n.ppLegalGeoBasis,
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: l10n.ppLegalAnalytics,
            basis: l10n.ppLegalAnalyticsBasis,
            colorScheme: colorScheme,
          ),
          _LegalBasisRow(
            treatment: l10n.ppLegalSecurity,
            basis: l10n.ppLegalSecurityBasis,
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
  final AppLocalizations l10n;

  const _RetentionTable({required this.colorScheme, required this.l10n});

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
              color: colorScheme.primaryContainer.withAlpha(77),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ppRetentionData,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    l10n.ppRetentionDuration,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _RetentionRow(
            data: l10n.ppRetentionActive,
            duration: l10n.ppRetentionActiveDuration,
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: l10n.ppRetentionDeleted,
            duration: l10n.ppRetentionDeletedDuration,
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: l10n.ppRetentionLogs,
            duration: l10n.ppRetentionLogsDuration,
            colorScheme: colorScheme,
          ),
          _RetentionRow(
            data: l10n.ppRetentionAnonymized,
            duration: l10n.ppRetentionAnonymizedDuration,
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
  final AppLocalizations l10n;

  const _UserRightsCard({
    required this.colorScheme,
    required this.theme,
    required this.l10n,
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
            title: l10n.ppRightAccess,
            description: l10n.ppRightAccessDesc,
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.edit,
            title: l10n.ppRightRectification,
            description: l10n.ppRightRectificationDesc,
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.delete,
            title: l10n.ppRightErasure,
            description: l10n.ppRightErasureDesc,
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.download,
            title: l10n.ppRightPortability,
            description: l10n.ppRightPortabilityDesc,
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.block,
            title: l10n.ppRightObjection,
            description: l10n.ppRightObjectionDesc,
            colorScheme: colorScheme,
          ),
          _RightTile(
            icon: Icons.undo,
            title: l10n.ppRightWithdraw,
            description: l10n.ppRightWithdrawDesc,
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
  final AppLocalizations l10n;

  const _CookiesTable({required this.colorScheme, required this.l10n});

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
              color: colorScheme.primaryContainer.withAlpha(77),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.ppCookieTracker,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.ppCookiePurpose,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.ppCookieConsent,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          _CookieRow(
            tracker: l10n.ppCookieSession,
            purpose: l10n.ppCookieSessionPurpose,
            consent: l10n.ppCookieSessionConsent,
            colorScheme: colorScheme,
          ),
          _CookieRow(
            tracker: l10n.ppCookiePreferences,
            purpose: l10n.ppCookiePreferencesPurpose,
            consent: l10n.ppCookiePreferencesConsent,
            colorScheme: colorScheme,
          ),
          _CookieRow(
            tracker: l10n.ppCookieAnalytics,
            purpose: l10n.ppCookieAnalyticsPurpose,
            consent: l10n.ppCookieAnalyticsConsent,
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
  final AppLocalizations l10n;

  const _ContactCard({required this.colorScheme, required this.l10n});

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.ppContactEmail,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Text('privacy@fug.app'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ppContactDelay,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(l10n.ppContactDelayValue),
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
