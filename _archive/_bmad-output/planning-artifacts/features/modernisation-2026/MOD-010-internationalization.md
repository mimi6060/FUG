# MOD-010: Internationalization (i18n)

> **Priority:** HIGH
> **Effort:** Medium (3-5 days)
> **Dependencies:** None
> **Status:** To Do

---

## Context

Currently, UI strings are hardcoded in the codebase. This prevents proper localization and makes it impossible to support multiple languages. The app needs proper internationalization to:

1. Detect device/browser language automatically
2. Support French (primary) and English (secondary) at minimum
3. Allow easy addition of future languages
4. Follow Flutter best practices for i18n

## Requirements

### R1: Flutter Internationalization Setup
- [ ] Add `flutter_localizations` package
- [ ] Add `intl` package for message generation
- [ ] Configure `l10n.yaml` for localization
- [ ] Set up `arb` files for translations

### R2: Automatic Language Detection
- [ ] Detect device language on mobile (iOS/Android)
- [ ] Detect browser language on web
- [ ] Fall back to French if language not supported
- [ ] Allow manual language override in settings

### R3: Supported Languages
- [ ] French (fr) - Primary language
- [ ] English (en) - Secondary language
- [ ] Structure for easy addition of more languages

### R4: Translation Files
- [ ] Create `app_fr.arb` with French translations
- [ ] Create `app_en.arb` with English translations
- [ ] Extract all existing hardcoded strings

### R5: Settings Integration
- [ ] Add language selector in Settings screen
- [ ] Persist language preference locally
- [ ] Hot-reload translations without app restart

---

## Technical Implementation

### 1. Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

### 2. Localization Configuration

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 3. ARB File Structure

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "settings": "Settings",
  "profile": "Profile",
  "deleteAccount": "Delete my account",
  "deleteAccountConfirmation": "Are you sure you want to delete your account?",
  "daysRemaining": "{count, plural, =1{1 day} other{{count} days}}",
  "@daysRemaining": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

### 4. MaterialApp Configuration

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: userSelectedLocale, // From provider
)
```

### 5. Usage in Code

```dart
// Before
Text('Delete my account')

// After
Text(AppLocalizations.of(context)!.deleteAccount)
```

---

## Files to Modify

### New Files
- `lib/l10n/app_en.arb` - English translations
- `lib/l10n/app_fr.arb` - French translations
- `lib/core/providers/locale_provider.dart` - Locale state management
- `lib/features/settings/presentation/language_settings_screen.dart`
- `l10n.yaml` - Localization configuration

### Modified Files
- `pubspec.yaml` - Add dependencies
- `lib/main.dart` - Add localization delegates
- `lib/features/settings/presentation/settings_screen.dart` - Add language setting
- `lib/features/settings/presentation/consent_screen.dart` - Use l10n
- `lib/features/settings/presentation/delete_account_screen.dart` - Use l10n
- All UI files with hardcoded strings

---

## Acceptance Criteria

1. [ ] App detects device language automatically
2. [ ] French and English fully translated
3. [ ] Settings screen has language selector
4. [ ] Language preference persists after restart
5. [ ] All UI strings use localization system
6. [ ] No hardcoded user-visible strings in code

---

## Testing

### Unit Tests
- Locale provider tests
- Translation file validation

### Integration Tests
- Language switch in settings
- Persistence of language choice
- App restart with saved language

### Manual Tests
- Test on French device
- Test on English device
- Test language switch
- Test fallback behavior

---

## Estimated Effort

| Task | Estimate |
|------|----------|
| Setup i18n infrastructure | 0.5 day |
| Extract strings to ARB files | 1 day |
| French translations | 0.5 day |
| English translations | 0.5 day |
| Settings integration | 0.5 day |
| Testing | 1 day |
| **Total** | **4 days** |

---

## Notes

- Consider using `easy_localization` package as alternative (simpler API)
- Plan for RTL languages if expanding to Arabic/Hebrew
- Consider gender-specific translations for some languages
- Keep translation keys semantic (e.g., `deleteAccount` not `button1`)

---

*Created: 2026-01-21*
*Author: BMAD System*
