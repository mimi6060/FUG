import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/account_repository.dart';

/// Ecran de suppression de compte (conformite RGPD)
///
/// Permet a l'utilisateur d'exercer son droit a l'oubli:
/// - Information claire sur les donnees supprimees
/// - Delai de grace de 30 jours
/// - Double confirmation avec mot de passe
/// - Possibilite d'annuler pendant le delai de grace
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _confirmCheckbox1 = false;
  bool _confirmCheckbox2 = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final dataToDelete = ref.watch(dataToBeDeletedProvider);
    final dataToAnonymize = ref.watch(dataToBeAnonymizedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supprimer mon compte'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      body: user.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(
              child: Text('Vous devez etre connecte pour acceder a cette page.'),
            );
          }

          return ref
              .watch(pendingDeletionRequestProvider(currentUser.$id))
              .when(
                data: (request) {
                  // Si une demande est en cours, afficher l'ecran d'annulation
                  if (request != null && request.canBeCancelled) {
                    return _buildPendingDeletionView(
                      context,
                      request,
                      currentUser.$id,
                    );
                  }

                  // Sinon, afficher le formulaire de demande
                  return _buildDeletionRequestForm(
                    context,
                    currentUser.$id,
                    dataToDelete,
                    dataToAnonymize,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _buildDeletionRequestForm(
                  context,
                  currentUser.$id,
                  dataToDelete,
                  dataToAnonymize,
                ),
              );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Erreur de chargement'),
        ),
      ),
    );
  }

  /// Vue affichee quand une demande de suppression est en cours
  Widget _buildPendingDeletionView(
    BuildContext context,
    AccountDeletionRequest request,
    String userId,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alerte visuelle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suppression programmee',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre compte sera supprime dans ${request.daysUntilDeletion} jours.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Informations sur la demande
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details de la demande',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Date de demande',
                    _formatDate(request.requestedAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Suppression prevue',
                    _formatDate(request.scheduledDeletionAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Jours restants',
                    '${request.daysUntilDeletion} jours',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Message explicatif
          Text(
            'Vous pouvez annuler cette demande a tout moment avant la date de suppression prevue. '
            'Apres cette date, votre compte et toutes vos donnees seront definitivement supprimes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Bouton d'annulation
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _cancelDeletion(request.id, userId),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(_isLoading ? 'Annulation...' : 'Annuler la suppression'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton retour
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour aux parametres'),
            ),
          ),
        ],
      ),
    );
  }

  /// Formulaire de demande de suppression
  Widget _buildDeletionRequestForm(
    BuildContext context,
    String userId,
    List<String> dataToDelete,
    List<String> dataToAnonymize,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avertissement
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.onErrorContainer,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attention',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cette action est irreversible apres le delai de grace.',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delai de grace
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue.shade700),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delai de grace: 30 jours',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Vous pouvez annuler votre demande a tout moment pendant cette periode.',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Donnees supprimees
            Text(
              'Donnees qui seront supprimees',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...dataToDelete.map((data) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Donnees anonymisees
            Text(
              'Donnees anonymisees (non supprimees)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...dataToAnonymize.map((data) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.visibility_off,
                          size: 20, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 32),

            // Confirmation 1
            CheckboxListTile(
              value: _confirmCheckbox1,
              onChanged: (value) {
                setState(() {
                  _confirmCheckbox1 = value ?? false;
                });
              },
              title: const Text(
                'Je comprends que mes donnees seront definitivement supprimees apres 30 jours.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Confirmation 2
            CheckboxListTile(
              value: _confirmCheckbox2,
              onChanged: (value) {
                setState(() {
                  _confirmCheckbox2 = value ?? false;
                });
              },
              title: const Text(
                'Je confirme vouloir supprimer mon compte et toutes mes donnees.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Mot de passe
            Text(
              'Confirmez avec votre mot de passe',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Entrez votre mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Bouton de suppression
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_confirmCheckbox1 && _confirmCheckbox2 && !_isLoading)
                    ? () => _requestDeletion(userId)
                    : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(
                  _isLoading ? 'Traitement...' : 'Supprimer mon compte',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton annuler
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Annuler'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _requestDeletion(String userId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Confirmation finale
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: const Text(
          'Etes-vous absolument sur de vouloir supprimer votre compte ?\n\n'
          'Vous avez 30 jours pour changer d\'avis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non, annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Oui, supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(accountDeletionNotifierProvider.notifier).requestDeletion(
            userId: userId,
            password: _passwordController.text,
          );

      if (!mounted) return;

      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Demande de suppression enregistree. '
            'Vous avez 30 jours pour annuler.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Deconnecter l'utilisateur
      await ref.read(authStateProvider.notifier).signOut();

      if (!mounted) return;

      // Rediriger vers la page de connexion
      context.go('/login');
    } on AccountException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelDeletion(String requestId, String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(accountDeletionNotifierProvider.notifier).cancelDeletion(
            requestId: requestId,
            userId: userId,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de suppression annulee avec succes.'),
          backgroundColor: Colors.green,
        ),
      );

      // Retourner aux parametres
      context.pop();
    } on AccountException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
