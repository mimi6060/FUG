# Index Features Modernisation 2026

> Epic E0 - Mise aux normes et modernisation de la spec FUG

## Priorite des Features

L'ordre de priorite est defini pour **d'abord se mettre aux normes 2026** avant d'ajouter de nouvelles fonctionnalites.

### Phase 1: Conformite & Obligations Legales (Sprint immediat)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-001 | Conformite RGPD Complete | **CRITIQUE** | Obligation legale, risque amendes | **DONE** |
| MOD-002 | Apple Sign-In | **CRITIQUE** | Obligation App Store depuis 2020 | **DONE** |
| MOD-003 | Conformite DSA | **HAUTE** | Obligation UE depuis 2024 | To Do |

### Phase 2: Mise a Jour Technique (Sprint suivant)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-004 | Versions OS Minimales | MOYENNE | Securite et maintenance | To Do |
| MOD-005 | Reformulation Marketing | MOYENNE | Image de marque | To Do |
| MOD-006 | Politique Confidentialite | HAUTE | Transparence obligatoire | To Do |
| MOD-010 | Internationalization (i18n) | **HAUTE** | UX multi-langue | To Do |

### Phase 3: Nouvelles Fonctionnalites (Sprints ulterieurs)

| ID | Feature | Priorite | Justification | Statut |
|----|---------|----------|---------------|--------|
| MOD-007 | Integrations Modernes | MOYENNE | Growth et viralite | To Do |
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
| MOD-010 | (To create) |

---

## Statut Global

| Phase | Features | Done | % |
|-------|----------|------|---|
| Phase 1 - Conformite | 3 | 2 | 66% |
| Phase 2 - Technique | 4 | 0 | 0% |
| Phase 3 - Features | 3 | 0 | 0% |
| **TOTAL** | **10** | **2** | **20%** |

---

## Implementation Progress

### Phase 1 (Sprint 9-10)
- [x] MOD-001: Conformite RGPD Complete - **IMPLEMENTED**
  - [x] MOD-001-A: Ecran de consentement RGPD
  - [ ] MOD-001-B: Export des donnees
- [x] MOD-002: Apple Sign-In - **IMPLEMENTED**
- [ ] MOD-003: Conformite DSA
  - [ ] MOD-003-A: Systeme de signalement
  - [ ] MOD-003-B: Workflow de moderation

### Phase 2 (Sprint 11-12)
- [ ] MOD-004: Versions OS Minimales
- [ ] MOD-005: Reformulation Marketing
- [ ] MOD-006: Politique de Confidentialite
- [ ] MOD-010: Internationalization (i18n) - **NEW**

### Phase 3 (Sprint 13+)
- [ ] MOD-007: Integrations Modernes
  - [ ] MOD-007-A: Partage WhatsApp
  - [ ] MOD-007-B: Export Calendrier
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

1. **MOD-010 (i18n)**: Implement localization system
   - Detect device language (iOS/Android/Web)
   - Support French and English
   - Migrate all hardcoded strings

2. **MOD-003 (DSA)**: Content reporting system

3. **MOD-001-B**: Data export functionality

---

*Last updated: 2026-01-21*
*Synchronized with Plane: Partial*
