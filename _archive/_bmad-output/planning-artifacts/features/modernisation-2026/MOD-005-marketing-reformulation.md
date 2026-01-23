# MOD-005: Marketing & Branding Reformulation

> Modernisation du message marketing et de l'image de marque FUG

## Contexte

L'application FUG a ete creee en 2014 avec un ton humoristique et provocateur ("Alcooliques Non-Anonymes"). Ce positionnement n'est plus adapte aux standards 2026 pour plusieurs raisons:

1. **App Store Guidelines**: Risque de rejet pour contenu promouvant la consommation excessive d'alcool
2. **Image professionnelle**: Necessaire pour attirer des partenaires (bars, brasseries)
3. **Responsabilite sociale**: Messages de moderation obligatoires dans plusieurs pays UE
4. **Public cible elargi**: Au-dela des etudiants, inclure les professionnels 25-45 ans

## Objectifs

- [x] Reformuler le tagline et la mission
- [x] Creer des descriptions App Store professionnelles
- [x] Ajouter des messages de consommation responsable
- [x] Moderniser le lexique (termes moins argotiques)
- [x] Mettre a jour la documentation projet

## Changements de Branding

### Ancien vs Nouveau

| Element | Ancien (2014) | Nouveau (2026) |
|---------|---------------|----------------|
| **Tagline** | "Alcooliques Non-Anonymes" | "Partagez des moments conviviaux" |
| **Mission** | "Boire plus et moins seuls" | "Connecter les gens autour de moments conviviaux" |
| **Ton** | Provocateur, humoristique | Chaleureux, inclusif, responsable |
| **Termes** | Guinze, Murge, Murgilarity | FUG (evenement), Score social, Points |

### Lexique Modernise

| Ancien terme | Nouveau terme | Contexte |
|--------------|---------------|----------|
| Guinze | FUG / Evenement | Nom de l'evenement |
| Murge | Sortie / Moment convivial | Description informelle |
| Murgilarity | Score social / Points FUG | Systeme de gamification |
| Preum's | Organisateur / Hote | Createur de l'evenement |
| Parfait guinzeur | Membre actif | Utilisateur engage |

**Note**: Le terme "Murgilarity" peut etre conserve dans le code et l'interface comme terme "fun" de la marque, mais doit etre accompagne d'explications claires.

## App Store Descriptions

### iOS App Store

**Nom**: FUG - Sorties & Rencontres

**Sous-titre**: Trouvez des compagnons de sortie

**Description courte** (170 caracteres):
```
Decouvrez les evenements sociaux autour de vous. Rejoignez des sorties, rencontrez de nouvelles personnes et partagez des moments conviviaux. A consommer avec moderation.
```

**Description complete**:
```
FUG vous connecte avec des personnes qui partagent votre envie de sortir et de decouvrir de nouveaux endroits.

FONCTIONNALITES PRINCIPALES

- Carte interactive des evenements a proximite
- Creez vos propres sorties et invitez vos amis
- Decouvrez les meilleurs bars, cafes et restaurants
- Suivez vos amis et soyez notifie de leurs sorties
- Gagnez des points et debloquez des badges

POURQUOI FUG ?

Vous cherchez de la compagnie pour un afterwork ? Un groupe pour decouvrir ce nouveau bar ? Des amis pour une soiree cinema suivie d'un verre ? FUG est fait pour vous.

Notre communaute bienveillante reunit des personnes de tous horizons, unies par l'envie de partager des moments conviviaux.

RESPECT ET RESPONSABILITE

FUG encourage une consommation responsable. L'abus d'alcool est dangereux pour la sante. A consommer avec moderation.

L'application est reservee aux personnes majeures (18+ ou age legal dans votre pays).

---
The Develobeers - Depuis 2014
```

**Mots-cles**: sorties, rencontres, afterwork, bars, amis, evenements, social, geolocalisation

### Google Play Store

**Titre**: FUG - Sorties & Rencontres Sociales

**Description courte** (80 caracteres):
```
Trouvez des compagnons de sortie et partagez des moments conviviaux pres de chez vous.
```

**Description complete**: (Identique a iOS avec adaptations mineures)

## Messages de Consommation Responsable

### Messages a afficher dans l'app

**A l'inscription**:
> "FUG encourage une consommation responsable d'alcool. L'abus d'alcool est dangereux pour la sante."

**Sur l'ecran de creation d'evenement**:
> "Pensez a prevoir des options sans alcool pour vos invites. Bonne soiree !"

**Dans les notifications (rotation)**:
- "Buvez de l'eau entre chaque verre"
- "Designez un conducteur sobre ou utilisez les transports"
- "Mangez avant et pendant la soiree"

**Footer app (legal)**:
> "L'abus d'alcool est dangereux pour la sante. A consommer avec moderation."

## Documents a Mettre a Jour

### 1. Document de vision.md

**Section 1.1.1 - Presentation de FUG**:
- Remplacer "Alcooliques Non-Anonymes" par "reseau social de sorties conviviales"
- Remplacer "boire seul" par "sortir seul"
- Ajouter mention de consommation responsable

### 2. README.md

**Description**:
- Mettre a jour la description avec le nouveau positionnement
- Ajouter badge "Responsible drinking"

### 3. App Store Listings

- Creer `metadata/ios/description.txt`
- Creer `metadata/android/description.txt`

## Implementation

### Fichiers crees/modifies

| Fichier | Action |
|---------|--------|
| `_bmad-output/.../MOD-005-marketing-reformulation.md` | Cree |
| `1. Document de vision.md` | Modifie |
| `README.md` | Modifie |
| `metadata/ios/description.txt` | Cree |
| `metadata/android/description.txt` | Cree |
| `app/lib/l10n/app_en.arb` | Modifie (messages responsables) |
| `app/lib/l10n/app_fr.arb` | Modifie (messages responsables) |
| `app/lib/l10n/app_nl.arb` | Modifie (messages responsables) |

## Criteres d'Acceptation

- [ ] Aucune mention de "Alcooliques Non-Anonymes" dans la documentation publique
- [ ] Message de consommation responsable visible dans l'app
- [ ] Descriptions App Store pretes pour soumission
- [ ] Ton coherent (chaleureux, inclusif) dans tous les documents

## Estimation

**Effort**: 3 jours
- Jour 1: Redaction des nouveaux contenus
- Jour 2: Mise a jour des documents et code
- Jour 3: Review et ajustements

## Statut

**Status**: DONE
**Date**: 2026-01-22
**Implementeur**: Claude Code (MOD-005 implementation)

---

*Feature de l'Epic E0 - Modernisation 2026*
