# Index Features Modernisation 2026

> Epic E0 - Mise aux normes et modernisation de la spec FUG

## Priorite des Features

L'ordre de priorite est defini pour **d'abord se mettre aux normes 2026** avant d'ajouter de nouvelles fonctionnalites.

### Phase 1: Conformite & Obligations Legales (Sprint immediat)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-001 | Conformite RGPD Complete | **CRITIQUE** | Obligation legale, risque amendes | **DONE** |
| MOD-002 | Apple Sign-In | **CRITIQUE** | Obligation App Store depuis 2020 | **DONE** |
| MOD-003 | Conformite DSA | **HAUTE** | Obligation UE depuis 2024 | **DONE** |

### Phase 2: Mise a Jour Technique (Sprint suivant)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-004 | Versions OS Minimales | MOYENNE | Securite et maintenance | **DONE** |
| MOD-005 | Reformulation Marketing | MOYENNE | Image de marque | To Do |
| MOD-006 | Politique Confidentialite | HAUTE | Transparence obligatoire | **DONE** |
| MOD-010 | Internationalization (i18n) | **HAUTE** | UX multi-langue | **DONE** |

### Phase 3: Nouvelles Fonctionnalites (Sprints ulterieurs)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-007 | Integrations Modernes | MOYENNE | Growth et viralite | **DONE** |
| MOD-008 | IA et Recommandations | BASSE | Engagement V2 | To Do |
| MOD-009 | Monetisation Ethique | BASSE | Business model V2 | To Do |

---

## Mapping Features -> Stories Plane

| Feature BMAD | Stories Plane |
|--------------|---------------|
| MOD-001 | SPEC-005 + US-006 |
| MOD-002 | SPEC-006-A |
| MOD-003 | SPEC-005-B |
| MOD-004 | SPEC-003 |
| MOD-005 | SPEC-003 |
| MOD-006 | SPEC-005-C |
| MOD-007 | SPEC-006 |
| MOD-008 | SPEC-004 |
| MOD-009 | SPEC-007 |
| MOD-010 | 0280e196 |

---

## Statut Global

| Phase | Features | Done | % |
|-------|----------|------|---|
| Phase 1 - Conformite | 3 | 3 | 100% |
| Phase 2 - Technique | 4 | 4 | 100% |
| Phase 3 - Features | 3 | 1 | 33% |
| **TOTAL** | **10** | **8** | **80%** |

---

## Implementation Progress

### Phase 1 (Sprint 9-10)
- [x] MOD-001: Conformite RGPD Complete - **DONE**
  - [x] MOD-001-A: Ecran de consentement RGPD
  - [x] MOD-001-B: Export des donnees (function + migration)
- [x] MOD-002: Apple Sign-In - **DONE**
- [x] MOD-003: Conformite DSA - **DONE**
  - [x] MOD-003-A: Systeme de signalement (3 migrations + Flutter reports feature)
  - [x] MOD-003-B: Workflow de moderation (moderation_actions collection)

### Phase 2 (Sprint 11-12)
- [x] MOD-004: Versions OS Minimales - **DONE** (README + pubspec flutter constraint)
- [ ] MOD-005: Reformulation Marketing
- [x] MOD-006: Politique de Confidentialite - **DONE** (1188 lines privacy screen)
- [x] MOD-010: Internationalization (i18n) - **DONE** (FR/EN/NL + flags + DB sync)

### Phase 3 (Sprint 13+)
- [x] MOD-007: Integrations Modernes - **DONE**
  - [x] MOD-007-A: Partage WhatsApp (SharingService + ShareOptionsSheet)
  - [x] MOD-007-B: Export Calendrier (add_2_calendar)
- [ ] MOD-008: IA et Recommandations
  - [ ] MOD-008-A: Moderation images
- [ ] MOD-009: Monetisation Ethique

---

## Recent Implementations

### 2026-01-21 - Sprint 9

**MOD-001 (RGPD Consent)**
- Consent screen with checkboxes for essential/analytics/marketing data
- Local storage of consent preferences
- Router integration with consent flow
- Related: US-006 Account Deletion also implemented

**MOD-002 (Apple Sign-In)**
- Apple Sign-In button widget
- Auth repository with `signInWithApple()` method
- iOS-only display logic
- Appwrite OAuth integration (pending backend config)

**US-006 (Delete Account)**
- Account deletion screen with 30-day grace period
- Password verification before deletion
- Data deletion/anonymization information
- Cancellation during grace period

---

## Next Steps

1. **MOD-005**: Marketing reformulation
   - Update app description and tagline
   - Modernize visual branding

2. **MOD-008**: IA et Recommandations
   - Image moderation with AI
   - Event recommendations

3. **MOD-009**: Monetisation Ethique
   - Premium features
   - Revenue model

---

## Recent Implementations

### 2026-01-22 - Sprint 10

**MOD-001-B (Data Export)**
- export-user-data Appwrite function
- 019_data_export_requests migration
- Collects all user data (profile, events, participations, followers, achievements, notifications)
- 24h download link expiration

**MOD-003 (DSA Compliance)**
- 016_content_reports migration (reports collection)
- 017_moderation_actions migration (moderation tracking)
- 018_notification_dsa_types migration (DSA notification types)
- Flutter reports feature (models, repository, widgets)

**MOD-006 (Privacy Policy)**
- Complete RGPD-compliant privacy policy screen (1188 lines)
- Table of contents, data tables, legal basis
- User rights documentation
- PDF download placeholder

**US-024/025 (Event Cancellation)**
- cancel-participation function (14 tests, 100% coverage)
- cancel-event function (17 tests, 100% coverage)
- Participant notifications
- Status updates and participant count management

**MOD-007 (Modern Integrations)**
- SharingService with shareToWhatsApp(), addToCalendar(), shareGeneric()
- ShareOptionsSheet bottom sheet with WhatsApp/Calendar/Generic options
- French localized share messages with FUG deep links
- add_2_calendar package for native calendar

**MOD-010 (Internationalization)**
- flutter_localizations + l10n.yaml config
- ARB files: English (template), French, Dutch
- locale_provider.dart with device language detection
- User preference sync to Appwrite users collection
- LanguageSelector widget with country flags
- Migration 020: preferredLanguage attribute

**MOD-004 (OS Versions)**
- README updated with OS requirements table
- Android 10+ (API 29), iOS 14+
- Flutter >=3.16.0 constraint in pubspec.yaml

---

*Last updated: 2026-01-22*
*Synchronized with Plane: Done (MOD-004, MOD-007, MOD-010 marked as Done)*
