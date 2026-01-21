import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/account_repository.dart';

/// Account deletion screen (GDPR compliance)
///
/// Allows users to exercise their right to be forgotten:
/// - Clear information about deleted data
/// - 30-day grace period
/// - Double confirmation with password
/// - Ability to cancel during grace period
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
        title: const Text('Delete my account'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      body: user.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(
              child: Text('You must be logged in to access this page.'),
            );
          }

          return ref
              .watch(pendingDeletionRequestProvider(currentUser.$id))
              .when(
                data: (request) {
                  // If a request is pending, show cancellation screen
                  if (request != null && request.canBeCancelled) {
                    return _buildPendingDeletionView(
                      context,
                      request,
                      currentUser.$id,
                    );
                  }

                  // Otherwise, show the request form
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
          child: Text('Loading error'),
        ),
      ),
    );
  }

  /// View displayed when a deletion request is pending
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
          // Visual alert
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
                        'Scheduled deletion',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your account will be deleted in ${request.daysUntilDeletion} days.',
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Request information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Request date',
                    _formatDate(request.requestedAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Scheduled deletion',
                    _formatDate(request.scheduledDeletionAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Days remaining',
                    '${request.daysUntilDeletion} days',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Explanatory message
          Text(
            'You can cancel this request at any time before the scheduled deletion date. '
            'After this date, your account and all your data will be permanently deleted.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          // Cancel button
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
              label: Text(_isLoading ? 'Cancelling...' : 'Cancel deletion'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Back button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to settings'),
            ),
          ),
        ],
      ),
    );
  }

  /// Deletion request form
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
            // Warning
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
                          'Warning',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This action is irreversible after the grace period.',
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

            // Grace period
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
                            'Grace period: 30 days',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can cancel your request at any time during this period.',
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

            // Deleted data
            Text(
              'Data that will be deleted',
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

            // Anonymized data
            Text(
              'Anonymized data (not deleted)',
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
                'I understand that my data will be permanently deleted after 30 days.',
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
                'I confirm that I want to delete my account and all my data.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // Password
            Text(
              'Confirm with your password',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
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
                  return 'Please enter your password';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Deletion button
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
                  _isLoading ? 'Processing...' : 'Delete my account',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
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

    // Final confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final confirmation'),
        content: const Text(
          'Are you absolutely sure you want to delete your account?\n\n'
          'You have 30 days to change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, delete'),
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

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deletion request submitted. '
            'You have 30 days to cancel.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Sign out user
      await ref.read(authStateProvider.notifier).signOut();

      if (!mounted) return;

      // Redirect to login page
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
          content: Text('Deletion request cancelled successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to settings
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
