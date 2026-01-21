import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/account_repository.dart';

/// Ecran des parametres de l'application
///
/// Permet a l'utilisateur de gerer:
/// - Son compte (profil, mot de passe)
/// - Les notifications
/// - La confidentialite
/// - La suppression de compte (RGPD)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
      ),
      body: ListView(
        children: [
          // Section Compte
          _SectionHeader(title: 'Compte'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            subtitle: const Text('Modifier vos informations personnelles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Mot de passe'),
            subtitle: const Text('Modifier votre mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Ecran de changement de mot de passe
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(user.valueOrNull?.email ?? 'Non connecte'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Ecran de modification d'email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),

          const Divider(),

          // Section Notifications
          _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Preferences de notifications'),
            subtitle: const Text('Gerer vos alertes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Ecran de parametres de notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),

          const Divider(),

          // Section Confidentialite
          _SectionHeader(title: 'Confidentialite et donnees'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Politique de confidentialite'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // TODO: Ouvrir la politique de confidentialite
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Exporter mes donnees'),
            subtitle: const Text('Telecharger une copie de vos donnees'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Export des donnees (RGPD)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),

          // Verifier s'il y a une demande de suppression en cours
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
                              ? 'Suppression en cours...'
                              : 'Supprimer mon compte',
                          style: TextStyle(
                            color:
                                hasPendingRequest ? Colors.orange : Colors.red,
                          ),
                        ),
                        subtitle: hasPendingRequest
                            ? Text(
                                'Suppression dans ${request.daysUntilDeletion} jours',
                                style: const TextStyle(color: Colors.orange),
                              )
                            : const Text('Exercer votre droit a l\'oubli'),
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
                        'Supprimer mon compte',
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
                        'Supprimer mon compte',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Exercer votre droit a l\'oubli'),
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

          // Section A propos
          _SectionHeader(title: 'A propos'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide et support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Ecran d'aide
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalite a venir')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('A propos de FUG'),
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
                    'FUG (Fous-toi Une Guinze) est une application '
                    'de reseau social geolocalisee pour trouver '
                    'des compagnons de boisson.',
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Deconnexion
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Deconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Deconnexion'),
                  content: const Text(
                    'Etes-vous sur de vouloir vous deconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Deconnexion'),
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

/// En-tete de section
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
