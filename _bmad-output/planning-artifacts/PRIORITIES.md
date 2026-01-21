# Priorités de Développement FUG

> **Version:** 1.0
> **Date:** 2026-01-21
> **Statut:** Approuvé

---

## Principe Directeur

**Les normes 2026 (conformité légale) passent AVANT les nouvelles fonctionnalités.**

Raison: Sans conformité RGPD/DSA/App Store, l'application risque:
- Amendes jusqu'à 4% du CA (RGPD)
- Rejet des app stores
- Perte de confiance utilisateurs

---

## Ordre de Priorité Global

### 0. INFRASTRUCTURE (FONDATION)

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P0** | INFRA-001 | Appwrite Infrastructure as Code | Sprint 9 |

> **INFRA-001 est CRITIQUE:** Sans automatisation complète, impossible de déployer en staging/prod de manière fiable.

### 1. CONFORMITÉ LÉGALE (BLOQUANT)

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P0** | MOD-001 | Conformité RGPD (consentement, suppression, export) | Sprint 9 ✅ |
| **P0** | MOD-002 | Apple Sign-In (obligatoire App Store - OPTIONNEL) | Sprint 9 ✅ |
| **P0** | US-006 | Suppression de compte (RGPD art. 17) | Sprint 9 ✅ |
| **P1** | MOD-003 | Conformité DSA (signalement, modération) | Sprint 10 |
| **P1** | MOD-006 | Politique de confidentialité complète | Sprint 10 |

### 2. FINALISATION MVP CORE

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P1** | US-020 | Rejoindre FUG public (finaliser) | Sprint 10 |
| **P1** | US-021 | Demander rejoindre FUG privé | Sprint 10 |
| **P1** | US-022 | Gérer demandes participation | Sprint 10 |
| **P1** | US-024 | Annuler participation | Sprint 11 |
| **P1** | US-025 | Annuler FUG | Sprint 11 |
| **P2** | US-027 | Notifications push | Sprint 11 |

### 3. QUALITÉ (QA)

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P2** | QA-001 | Tests Auth Flow | Sprint 12 |
| **P2** | QA-002 | Tests Profile | Sprint 12 |
| **P2** | QA-003 | Tests Social | Sprint 12 |
| **P2** | QA-004 | Tests Events | Sprint 12 |

### 4. AMÉLIORATIONS TECHNIQUES

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P3** | MOD-004 | Versions OS Minimales | Sprint 13 |
| **P3** | MOD-005 | Reformulation Marketing | Sprint 13 |
| **P3** | MOD-007 | Intégrations Modernes | Sprint 13-14 |

### 5. GAMIFICATION & FUTURES (V2)

| Priorité | Story | Description | Sprint |
|----------|-------|-------------|--------|
| **P4** | US-031 | Système de badges | Sprint 14+ |
| **P4** | US-033 | Niveaux et progression | Sprint 14+ |
| **P4** | MOD-008 | IA et Recommandations | V2 |
| **P5** | MOD-009 | Monétisation | V2+ |

---

## Définition des Niveaux de Priorité

| Niveau | Nom | Définition |
|--------|-----|------------|
| **P0** | Bloquant | Sans cette story, l'app ne peut pas être publiée |
| **P1** | Critique | Fonctionnalité core du MVP |
| **P2** | Important | Attendu par les utilisateurs |
| **P3** | Souhaitable | Amélioration de l'expérience |
| **P4** | Optionnel | Bonus, peut attendre V2 |
| **P5** | Futur | Post-MVP uniquement |

---

## Sprint Actuel: Sprint 9 - Infrastructure & Conformité

**Objectif:** Infrastructure automatisée + mise aux normes.

### Stories Sprint 9

1. [ ] **INFRA-001**: Appwrite Infrastructure as Code (EN COURS)
   - [ ] INFRA-001-A: Bootstrap Script
   - [ ] INFRA-001-B: Migration System Enhancement
   - [ ] INFRA-001-C: Bootstrap Migrations
   - [ ] INFRA-001-D: Documentation

2. [x] **MOD-001**: Conformité RGPD Complète ✅
   - [x] MOD-001-A: Écran de consentement
   - [ ] MOD-001-B: Export des données
   - [x] US-006: Suppression de compte

3. [x] **MOD-002**: Apple Sign-In ✅ (code prêt, config optionnelle)
   - [ ] Config Apple Developer (si iOS décidé)
   - [x] Config Appwrite Auth (Google configuré)
   - [x] Bouton iOS (code Flutter prêt)

### Definition of Done Sprint 9

- [x] Consentement RGPD fonctionnel
- [x] Suppression de compte fonctionnelle (avec délai 30j)
- [ ] Export données disponible
- [x] Google Sign-In configuré
- [ ] Infrastructure automatisée (INFRA-001)
- [ ] Tests manuels validés

---

## Matrice Effort/Impact

```
IMPACT
  ^
  |  P0: RGPD, Apple   |  P1: DSA, MVP Core
  |  Sign-In           |
  |--------------------+--------------------
  |  P3: OS Versions,  |  P4-P5: Gamif,
  |  Marketing         |  IA, Monétisation
  +----------------------------------------> EFFORT
```

---

## Dépendances

```
MOD-001 (RGPD) ─────┬─────> Publication App Store
                    │
MOD-002 (Apple) ────┤
                    │
MOD-003 (DSA) ──────┘

US-006 ──────> MOD-001 (fait partie de RGPD)

US-020,21,22 ──────> US-024,25 (participation avant annulation)

QA-* ──────> Après implémentation features concernées
```

---

## Métriques de Suivi

| Métrique | Valeur Actuelle | Cible |
|----------|-----------------|-------|
| Stories P0 complétées | 0/3 | 3/3 |
| Stories P1 complétées | 0/7 | 7/7 |
| Conformité RGPD | 60% | 100% |
| Conformité DSA | 0% | 100% |
| Couverture tests | ~0% | 70% |

---

*Document maintenu par l'équipe FUG - The Develobeers*
*Mis à jour: 2026-01-21*
