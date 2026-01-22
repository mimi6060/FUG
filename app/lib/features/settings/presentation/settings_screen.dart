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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            subtitle: const Text('Edit your personal information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Password'),
            subtitle: const Text('Change your password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Password change screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(user.valueOrNull?.email ?? 'Not connected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Email modification screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),

          const Divider(),

          // Notifications Section
          _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification preferences'),
            subtitle: const Text('Manage your alerts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Notification settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),

          const Divider(),

          // Preferences Section (MOD-010: i18n)
          _SectionHeader(title: 'Preferences'),
          const LanguageTile(),

          const Divider(),

          // Privacy Section
          _SectionHeader(title: 'Privacy and data'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy policy'),
            subtitle: const Text('RGPD compliant privacy information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy-policy'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export my data'),
            subtitle: const Text('Download a copy of your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Data export (GDPR)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
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
                              ? 'Deletion in progress...'
                              : 'Delete my account',
                          style: TextStyle(
                            color:
                                hasPendingRequest ? Colors.orange : Colors.red,
                          ),
                        ),
                        subtitle: hasPendingRequest
                            ? Text(
                                'Deletion in ${request.daysUntilDeletion} days',
                                style: const TextStyle(color: Colors.orange),
                              )
                            : const Text('Exercise your right to be forgotten'),
                        trailing: Icon(
                          Icons.chevron_right,
                          color:
                              hasPendingRequest ? Colors.orange : Colors.red,
                        ),
                        onTap: () => context.push('/settings/delete-account'),
                      );
                    },
                    loading: () => const ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text(
                        'Delete my account',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'Delete my account',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Exercise your right to be forgotten'),
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
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help and support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About FUG'),
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
            title: const Text(
              'Sign out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text(
                    'Are you sure you want to sign out?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sign out'),
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
              'Version 1.0.0',
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
