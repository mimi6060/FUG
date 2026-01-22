import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../core/providers/locale_provider.dart';

/// Modern language selector with flags
///
/// MOD-010: Internationalization
/// Displays a bottom sheet with available languages and their flags
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  /// Show the language selector bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LanguageSelector(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final effectiveLocale = ref.watch(effectiveLocaleProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              l10n.selectLanguage,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // System default option
            _LanguageOption(
              flag: '\u{1F310}', // Globe emoji
              name: l10n.systemDefault,
              nativeName: _getSystemLanguageHint(context),
              isSelected: currentLocale == null,
              onTap: () => _selectLanguage(context, ref, null),
            ),

            const Divider(height: 24),

            // Language options
            ...supportedLocalesInfo.map((info) => _LanguageOption(
                  flag: info.flag,
                  name: _getLocalizedLanguageName(l10n, info.locale.languageCode),
                  nativeName: info.nativeName,
                  isSelected: effectiveLocale.languageCode == info.locale.languageCode &&
                      currentLocale != null,
                  onTap: () => _selectLanguage(context, ref, info.locale),
                )),
          ],
        ),
      ),
    );
  }

  String _getSystemLanguageHint(BuildContext context) {
    final systemLocale = View.of(context).platformDispatcher.locale;
    final info = getLocaleInfo(systemLocale);
    if (info != null) {
      return '${info.flag} ${info.nativeName}';
    }
    return systemLocale.languageCode.toUpperCase();
  }

  String _getLocalizedLanguageName(AppLocalizations l10n, String code) {
    switch (code) {
      case 'fr':
        return l10n.languageFrench;
      case 'en':
        return l10n.languageEnglish;
      case 'nl':
        return l10n.languageDutch;
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    Locale? locale,
  ) async {
    Navigator.pop(context);
    await ref.read(localeProvider.notifier).setLocale(locale);
  }
}

/// Individual language option widget
class _LanguageOption extends StatelessWidget {
  final String flag;
  final String name;
  final String nativeName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.name,
    required this.nativeName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Flag
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),

              const SizedBox(width: 16),

              // Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (name != nativeName)
                      Text(
                        nativeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Check mark
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact language selector for settings list tile
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final effectiveLocale = ref.watch(effectiveLocaleProvider);

    final localeInfo = getLocaleInfo(effectiveLocale);
    final displayName = currentLocale == null
        ? l10n.systemDefault
        : localeInfo?.nativeName ?? effectiveLocale.languageCode;
    final flag = currentLocale == null
        ? '\u{1F310}' // Globe
        : localeInfo?.flag ?? '';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            flag,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(l10n.language),
      subtitle: Text(displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => LanguageSelector.show(context),
    );
  }
}
