import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/account_repository.dart';
import 'widgets/language_selector.dart';

/// Application settings screen
///
/// Allows users to manage:
/// - Account (profile, password)
/// - Notifications
/// - Privacy
/// - Account deletion (GDPR)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Account Section
          _SectionHeader(title: l10n.account),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(l10n.profile),
            subtitle: Text(l10n.editYourPersonalInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(l10n.password),
            subtitle: Text(l10n.changeYourPassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureComingSoon)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(l10n.email),
            subtitle: Text(user.valueOrNull?.email ?? l10n.notConnected),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureComingSoon)),
              );
            },
          ),

          const Divider(),

          // Notifications Section
          _SectionHeader(title: l10n.notifications),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.notificationPreferences),
            subtitle: Text(l10n.manageYourAlerts),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureComingSoon)),
              );
            },
          ),

          const Divider(),

          // Preferences Section (MOD-010: i18n)
          _SectionHeader(title: l10n.languagePreference),
          const LanguageTile(),

          const Divider(),

          // Privacy Section
          _SectionHeader(title: l10n.privacyAndData),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
            subtitle: Text(l10n.rgpdPrivacyInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy-policy'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.exportMyData),
            subtitle: Text(l10n.downloadYourData),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureComingSoon)),
              );
            },
          ),

          // Check if there is a pending deletion request
          user.when(
            data: (currentUser) {
              if (currentUser == null) return const SizedBox.shrink();

              return ref
                  .watch(pendingDeletionRequestProvider(currentUser.$id))
                  .when(
                    data: (request) {
                      final hasPendingRequest =
                          request != null && request.canBeCancelled;

                      return ListTile(
                        leading: Icon(
                          Icons.delete_forever,
                          color: hasPendingRequest ? Colors.orange : Colors.red,
                        ),
                        title: Text(
                          hasPendingRequest
                              ? l10n.deletionInProgress
                              : l10n.deleteMyAccount,
                          style: TextStyle(
                            color:
                                hasPendingRequest ? Colors.orange : Colors.red,
                          ),
                        ),
                        subtitle: hasPendingRequest
                            ? Text(
                                l10n.deletionInDays(request.daysUntilDeletion),
                                style: const TextStyle(color: Colors.orange),
                              )
                            : Text(l10n.exerciseRightToBeForgotten),
                        trailing: Icon(
                          Icons.chevron_right,
                          color:
                              hasPendingRequest ? Colors.orange : Colors.red,
                        ),
                        onTap: () => context.push('/settings/delete-account'),
                      );
                    },
                    loading: () => ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        l10n.deleteMyAccount,
                        style: const TextStyle(color: Colors.red),
                      ),
                      trailing: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        l10n.deleteMyAccount,
                        style: const TextStyle(color: Colors.red),
                      ),
                      subtitle: Text(l10n.exerciseRightToBeForgotten),
                      trailing:
                          const Icon(Icons.chevron_right, color: Colors.red),
                      onTap: () => context.push('/settings/delete-account'),
                    ),
                  );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(),

          // About Section
          _SectionHeader(title: l10n.about),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(l10n.helpAndSupport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.featureComingSoon)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l10n.aboutFug),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'FUG',
                applicationVersion: '1.0.0',
                applicationLegalese: '2026 The Develobeers',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'FUG (Fous-toi Une Guinze) is a geolocation-based '
                    'social networking app to find drinking companions.',
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.signOut,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.signOut),
                  content: Text(l10n.signOutConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authStateProvider.notifier).signOut();
              }
            },
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              l10n.version('1.0.0'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Section header
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
