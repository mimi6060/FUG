# Changelog - FUG Specifications & Features

> Systeme de versioning pour le suivi des analyses et specifications

## Format de Version

```
MAJOR.MINOR.PATCH
  |     |     |
  |     |     +-- Corrections mineures, typos
  |     +-------- Nouvelles features, stories
  +-------------- Changements majeurs de spec

0.x.x = Pre-release / Developpement
1.0.0 = Premier MVP publie
```

---

## [Unreleased]

### En cours
- Sprint 9: Conformite (RGPD, Apple Sign-In)
- Implementation MOD-001 a MOD-003 (Phase 1)

---

## [0.2.0] - 2026-01-21

### Added
- **Systeme de versioning** pour les specs et analyses
- **9 Features BMAD** pour modernisation 2026 (MOD-001 a MOD-009)
- **16 nouvelles stories** dans Plane (Epic E0)
- **Document PRIORITIES.md** definissant l'ordre de developpement
- **Regle de synchronisation** BMAD <-> Plane dans CLAUDE.md

### Features Creees

| Feature | Priorite | Phase |
|---------|----------|-------|
| MOD-001 | CRITIQUE | Conformite RGPD |
| MOD-002 | CRITIQUE | Apple Sign-In |
| MOD-003 | HAUTE | Conformite DSA |
| MOD-004 | MOYENNE | Versions OS |
| MOD-005 | MOYENNE | Branding |
| MOD-006 | HAUTE | Privacy Policy |
| MOD-007 | MOYENNE | Integrations |
| MOD-008 | BASSE | IA/ML |
| MOD-009 | BASSE | Monetisation |

### Changed
- **Priorites reorganisees**: Normes 2026 passent en premier
- **CLAUDE.md** mis a jour avec workflow Plane

---

## [0.1.0] - 2026-01-21

### Added
- **SPEC-001**: Audit initial spec 2014 vs tendances 2026
  - Document: `spec-audit-2014-vs-2026.md`
  - Statut: Complete
  - Impact: Identification de 15+ elements obsoletes, 20+ opportunites

### Identified - Elements Obsoletes
- Windows Phone comme plateforme
- Android < 8.0 comme cible
- Formulation "Alcooliques Non-Anonymes"
- References Google+
- Modele economique version separee

### Identified - Nouvelles Opportunites
- Apple Sign-In (obligatoire iOS)
- Conformite RGPD complete
- Conformite DSA (Digital Services Act)
- Integrations modernes (WhatsApp, Instagram)
- IA pour recommandations et moderation

---

## [0.0.1] - 2026-01-20

### Added
- Import initial des stories dans Plane (40 stories)
- Mapping des stories existantes vs code (`stories-mapping.md`)
- Creation Epic E0 - Modernisation Spec 2026
- Installation Plane (gestionnaire de stories)

---

## Versions Planifiees

### [0.3.0] - Cible: Fin Janvier 2026
- Implementation MOD-001 (RGPD)
- Implementation MOD-002 (Apple Sign-In)
- US-006 complete (suppression compte)

### [0.4.0] - Cible: Fevrier 2026
- Implementation MOD-003 (DSA)
- Implementation MOD-006 (Privacy Policy)
- Finalisation US-020 a US-025 (participations)

### [0.5.0] - Cible: Mars 2026
- QA-001 a QA-006 (tests)
- MOD-004, MOD-005 (technique)

### [1.0.0] - MVP Release
- Toutes les stories P0 et P1 completees
- Conformite RGPD/DSA validee
- Apple Sign-In fonctionnel
- Tests QA passes
- Pret pour soumission App Store / Play Store

---

## References

| Document | Chemin | Version |
|----------|--------|---------|
| Audit 2014 vs 2026 | `spec-audit-2014-vs-2026.md` | 0.1.0 |
| Document de Vision | `../../1. Document de vision.md` | Original (2014) |
| Analyse Fonctionnelle | `../../2. Analyse fonctionnelle.md` | 2.0 |
| Architecture Technique | `../../3. Architecture technique.md` | 2.0 |
| Backlog Produit | `../../4. Backlog produit.md` | 1.0 |
| Priorites | `../PRIORITIES.md` | 0.2.0 |

---

*Maintenu par: The Develobeers*
*Derniere mise a jour: 2026-01-21*
