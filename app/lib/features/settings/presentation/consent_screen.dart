import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/consent_provider.dart';
import '../data/consent_repository.dart';

/// GDPR consent screen
///
/// Displayed on first launch or accessible from settings.
/// Allows user to manage consent preferences.
class ConsentScreen extends ConsumerStatefulWidget {
  /// Indicates if this is first launch (registration)
  final bool isFirstLaunch;

  const ConsentScreen({
    super.key,
    this.isFirstLaunch = true,
  });

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _essentialConsent = true; // Always true, required
  bool _analyticsConsent = false;
  bool _marketingConsent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConsent();
  }

  Future<void> _loadExistingConsent() async {
    final prefs = await ref.read(currentConsentPreferencesProvider.future);
    if (prefs != null && mounted) {
      setState(() {
        _analyticsConsent = prefs.analytics;
        _marketingConsent = prefs.marketing;
      });
    }
  }

  Future<void> _saveConsent() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      _showError('User not connected');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final manager = ref.read(consentManagerProvider.notifier);

      bool success;
      if (widget.isFirstLaunch) {
        success = await manager.saveInitialConsent(
          userId: user.$id,
          analyticsConsent: _analyticsConsent,
          marketingConsent: _marketingConsent,
        );
      } else {
        success = await manager.updateConsent(
          userId: user.$id,
          analyticsConsent: _analyticsConsent,
          marketingConsent: _marketingConsent,
        );
      }

      if (success && mounted) {
        if (widget.isFirstLaunch) {
          // Redirect to home page
          context.go('/home');
        } else {
          // Return to settings
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        _showError('Error saving preferences');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openPrivacyPolicy() {
    // Navigate to in-app privacy policy screen
    context.push('/settings/privacy-policy');
  }

  void _acceptAll() {
    setState(() {
      _analyticsConsent = true;
      _marketingConsent = true;
    });
  }

  void _rejectOptional() {
    setState(() {
      _analyticsConsent = false;
      _marketingConsent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: widget.isFirstLaunch
          ? null
          : AppBar(
              title: const Text('Consent Management'),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              if (widget.isFirstLaunch) ...[
                const SizedBox(height: 24),
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your data, your control',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We respect your privacy. Choose how we use your data.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],

              // GDPR info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'In compliance with GDPR, you can change your choices at any time in settings.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Essential data (required)
              _ConsentTile(
                icon: Icons.security,
                iconColor: colorScheme.secondary,
                title: 'Essential data',
                subtitle: 'Required for app functionality',
                details:
                    'Authentication, session management, basic preferences.',
                value: _essentialConsent,
                required: true,
                onChanged: null, // Required, not modifiable
              ),
              const SizedBox(height: 16),

              // Analytics
              _ConsentTile(
                icon: Icons.analytics_outlined,
                iconColor: colorScheme.tertiary,
                title: 'Analytics',
                subtitle: 'Help us improve FUG',
                details:
                    'Anonymous usage statistics to improve the experience.',
                value: _analyticsConsent,
                required: false,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _analyticsConsent = value ?? false;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Marketing
              _ConsentTile(
                icon: Icons.campaign_outlined,
                iconColor: colorScheme.error,
                title: 'Marketing communications',
                subtitle: 'Receive offers and news',
                details:
                    'Promotional emails, special event notifications.',
                value: _marketingConsent,
                required: false,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _marketingConsent = value ?? false;
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Quick buttons
              if (widget.isFirstLaunch) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _rejectOptional,
                        child: const Text('Reject optional'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _acceptAll,
                        child: const Text('Accept all'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Privacy policy link
              TextButton.icon(
                onPressed: _openPrivacyPolicy,
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Read our privacy policy'),
              ),
              const SizedBox(height: 24),

              // Validation button
              FilledButton(
                onPressed: _isLoading ? null : _saveConsent,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isFirstLaunch
                            ? 'Continue'
                            : 'Save my preferences',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              // Legal note
              Text(
                'By continuing, you accept the essential data required for app functionality.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display a consent option
class _ConsentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String details;
  final bool value;
  final bool required;
  final ValueChanged<bool?>? onChanged;

  const _ConsentTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.value,
    required this.required,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: value,
            onChanged: onChanged,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
              ),
            ),
            title: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (required) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(subtitle),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            child: Text(
              details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
