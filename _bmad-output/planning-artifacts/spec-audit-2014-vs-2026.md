# SPEC-001: Audit Spec 2014 vs Tendances 2026

> **Version:** 1.0
> **Date:** 21 janvier 2026
> **Auteur:** Claude Code (Audit automatise)
> **Statut:** En cours d'analyse

---

## Resume Executif

Ce document analyse la specification originale FUG de 2014 et identifie ce qui est obsolete, ce qui reste pertinent, et les opportunites de modernisation pour 2026.

**Verdict global:** La vision core reste valide mais necessite une mise a jour significative pour refleter les evolutions technologiques, reglementaires et sociologiques des 12 dernieres annees.

---

## 1. Elements Obsoletes (A Retirer/Modifier)

### 1.1 Plateformes Technologiques

| Element 2014 | Statut 2026 | Recommandation |
|--------------|-------------|----------------|
| **Windows Phone** | OS abandonne (2020) | Retirer completement |
| **Android >= 4.0.0** | Obsolete (min 8.0 recommande) | Mettre a jour vers Android 10+ |
| **Application native par OS** | Depasse par cross-platform | Valider choix Flutter (deja fait) |

**Impact:** Le choix actuel de Flutter resout ce probleme. Mettre a jour la spec pour refleter la strategie cross-platform.

### 1.2 Integrations Reseaux Sociaux

| Element 2014 | Probleme 2026 | Recommandation |
|--------------|---------------|----------------|
| Partage generique "reseaux sociaux" | APIs changees (Twitter -> X, deprecation APIs) | Specifier: Instagram, TikTok, WhatsApp, Threads |
| Google+ implicite | Service ferme (2019) | Retirer toute reference |
| Facebook OAuth prioritaire | Perte de popularite chez les jeunes | Privilegier Apple Sign-In et Google |

### 1.3 Formulations Problematiques

| Formulation 2014 | Probleme | Recommandation |
|------------------|----------|----------------|
| "Alcooliques Non-Anonymes" | Peut etre percu negativement, risque reputationnel | "Reseau social pour moments conviviaux" |
| "boire plus et moins seuls" | Encourage la surconsommation | "partager des moments autour d'un verre" |
| "rendre accro les utilisateurs" | Contraire aux guidelines app stores | "engagement via gamification positive" |
| "developpe en buvant un maximum" | Non-professionnel pour une spec | Retirer ou releguer en anecdote historique |

### 1.4 Modeles Economiques Obsoletes

| Element 2014 | Probleme 2026 | Recommandation |
|--------------|---------------|----------------|
| Version gratuite + payante | Modele freemium classique depasse | Considerer: Premium subscription, pas de version separee |
| "Pubs localisees" | RGPD/ePrivacy rendent la pub ciblee complexe | Rethink: Partenariats bars/marques consentis |

### 1.5 Contraintes Techniques Depassees

| Contrainte 2014 | Realite 2026 | Recommandation |
|-----------------|--------------|----------------|
| "economie connexion reseau" | 5G/WiFi6 generalisees, data illimite | Moins critique, focus sur UX fluide |
| "geolocalisation moins couteuse" | GPS moderne tres efficient | Focus sur precision et permissions |
| "Android >= 4.0.0" | Irrelevant | Cibler Android 10+ / iOS 14+ |

---

## 2. Elements Toujours Pertinents (A Conserver)

### 2.1 Vision Core

| Element | Validite 2026 | Note |
|---------|---------------|------|
| Creer des evenements sociaux geoloces | **Tres pertinent** | Tendance post-COVID de reconnexion sociale |
| Systeme de followers | **Pertinent** | Modele social eprouve |
| Gamification (badges, niveaux, classements) | **Pertinent** | Augmente engagement x3 en moyenne |
| Carte des evenements a proximite | **Essentiel** | UX attendue pour apps geoloc |

### 2.2 Regles Metier Core

| Regle | Validite | Justification |
|-------|----------|---------------|
| Age minimum legal | **Obligatoire** | Conformite legale |
| Evenements publics par defaut | **A nuancer** | Ajouter option "followers only" |
| Murgilarity (score reputation) | **Valide** | Encourage comportement positif |
| Anonymisation a la suppression | **Obligatoire** | Conformite RGPD |
| Conservation historique | **Valide** | Statistiques et integrite |

### 2.3 Fonctionnalites Essentielles

| Fonctionnalite | Priorite 2026 |
|----------------|---------------|
| Inscription email + OAuth | Must Have |
| Creation/participation evenements | Must Have |
| Carte interactive geoloc | Must Have |
| Systeme de followers | Must Have |
| Notifications push | Must Have |
| Badges et niveaux | Should Have |

---

## 3. Nouvelles Opportunites 2026

### 3.1 Intelligence Artificielle

| Opportunite | Description | Priorite |
|-------------|-------------|----------|
| **Recommandations personnalisees** | IA suggerant des FUG selon historique et preferences | High |
| **Detection contenu inapproprie** | Moderation auto des photos/textes | Medium |
| **Smart notifications** | IA determinant le meilleur moment pour notifier | Low (V2) |
| **Matching social** | Suggerer des utilisateurs a suivre | Medium |

**Implementation suggeree:**
- Phase 1: Moderation images via API (Google Vision, AWS Rekognition)
- Phase 2: Recommendations basees sur collaborative filtering
- Phase 3: NLP pour analyse de sentiments dans descriptions

### 3.2 Conformite Reglementaire Moderne

| Regulation | Exigence | Statut Actuel | Action |
|------------|----------|---------------|--------|
| **RGPD** (Europe) | Consentement explicite, droit a l'oubli | Partiellement implemente | Finaliser US-006 |
| **DSA** (Digital Services Act) | Moderation, transparence algorithmes | Non implemente | Nouvelle story |
| **DMA** (Digital Markets Act) | Interoperabilite | N/A pour FUG | Surveiller |
| **Loi Evin** (France) | Restrictions pub alcool | Non gere | Ajouter filtres contenus |

**Nouvelle User Story suggeree:**
```
US-XXX: Conformite DSA
En tant que plateforme
Je dois moderer les contenus et etre transparent sur mes algorithmes
Afin de respecter le Digital Services Act europeen
```

### 3.3 Integrations Modernes

| Integration | Benefice | Complexite |
|-------------|----------|------------|
| **Apple Wallet / Google Pay** | Billets evenements, loyalty cards | Medium |
| **Calendar Sync** | Export FUG vers calendrier natif | Low |
| **WhatsApp Business** | Partage et invitations | Low |
| **Instagram Stories** | Partage viral | Medium |
| **Spotify** | Playlists liees aux evenements | Low (V2) |
| **Uber/Bolt** | Commande transport depuis FUG | Medium |

### 3.4 Fonctionnalites Sociales Modernes

| Fonctionnalite | Tendance 2026 | Priorite FUG |
|----------------|---------------|--------------|
| **Stories ephemeres** | Standard social | Medium (V2) |
| **Reactions emoji** | Engagement rapide | Low |
| **Live location** | Partage position temps reel pendant FUG | Medium |
| **Widgets home screen** | Visibilite continue | Low |
| **Apple Watch / Wear OS** | Notifications au poignet | Low (V3) |

### 3.5 Monetisation Ethique 2026

| Modele | Description | Ethique |
|--------|-------------|---------|
| **FUG Premium** | Sans pub, fonctions avancees | Bon |
| **Partenariats bars** | Bars sponsors FUG = visibilite | Acceptable si transparent |
| **Badges sponsorises** | Marques offrent badges speciaux | Acceptable si modere |
| **Publicite contextuelle** | Non-personnalisee, consentie | Acceptable RGPD |

**A eviter:**
- Vente de donnees utilisateurs
- Publicite comportementale sans consentement
- Dark patterns d'engagement

---

## 4. Analyse des Use Cases Originaux (2014)

| Use Case 2014 | Statut Implementation | Note 2026 |
|---------------|----------------------|-----------|
| UC-01: S'inscrire | Done | Ajouter Apple Sign-In |
| UC-02: Se connecter | Done | OK |
| UC-03: Editer profil | Done | Ajouter verification identite? |
| UC-04: Rechercher utilisateur | Done | Ajouter suggestions IA |
| UC-05: Suivre utilisateur | Done | OK |
| UC-06: Creer FUG | Done | Ajouter templates evenements |
| UC-07: Voir FUG proches | Done | Ajouter filtres avances |
| UC-08: Participer FUG | Partial | Finaliser demandes privees |
| UC-09: Annuler participation | TODO | Priorite haute |
| UC-10: Annuler FUG | TODO | Priorite haute |
| UC-11: Gerer notifications | Partial | Push TODO |
| UC-12: Signaler bug | TODO | Ajouter feedback in-app |
| UC-13: Partager FUG | TODO | Integrer reseaux modernes |

---

## 5. Recommandations de Modernisation

### 5.1 Court Terme (Sprint actuel)

| Action | Impact | Effort |
|--------|--------|--------|
| Retirer references Windows Phone | Documentation | Trivial |
| Mettre a jour versions OS cibles | Documentation | Trivial |
| Reformuler langage marketing | Branding | Low |
| Finaliser US-006 (suppression compte RGPD) | Conformite | Medium |

### 5.2 Moyen Terme (3 prochains mois)

| Action | Impact | Effort |
|--------|--------|--------|
| Ajouter Apple Sign-In | Acquisition iOS | Medium |
| Integrer partage WhatsApp/Instagram | Viralite | Medium |
| Implementer moderation images IA | Securite | Medium |
| Ajouter option evenements "followers only" | Vie privee | Low |

### 5.3 Long Terme (6-12 mois)

| Action | Impact | Effort |
|--------|--------|--------|
| Systeme de recommandations IA | Engagement | High |
| Stories ephemeres | Modernite | High |
| Integration transport (Uber/Bolt) | UX | Medium |
| Apple Watch / Wear OS | Ecosystem | High |
| Conformite DSA complete | Legal | Medium |

---

## 6. Matrice de Decision

### Elements a Supprimer de la Spec

- [ ] Windows Phone comme plateforme cible
- [ ] Reference a Android < 8.0
- [ ] Formulation "Alcooliques Non-Anonymes" dans communication officielle
- [ ] "Rendre accro" comme objectif explicite
- [ ] References a Google+
- [ ] Modele "version gratuite + payante" separees

### Elements a Ajouter a la Spec

- [ ] Apple Sign-In comme methode d'authentification
- [ ] Conformite RGPD explicite
- [ ] Conformite DSA (moderation, transparence)
- [ ] Integrations reseaux sociaux modernes (WhatsApp, Instagram, TikTok)
- [ ] Option evenements prives (followers only)
- [ ] Moderation automatique par IA
- [ ] Support Flutter/Dart comme stack officiel

### Elements a Mettre a Jour

- [ ] Versions OS minimum: Android 10+, iOS 14+
- [ ] Regles de gamification (ajuster les points)
- [ ] Types de notifications (ajouter types modernes)
- [ ] Politique de confidentialite
- [ ] Conditions d'utilisation

---

## 7. Prochaines Etapes

1. **SPEC-002**: Valider les recommandations avec l'equipe
2. **SPEC-003**: Mettre a jour le Document de Vision
3. **SPEC-004**: Creer la roadmap IA/ML
4. **SPEC-005**: Auditer conformite RGPD/DSA
5. **SPEC-006**: Etudier nouvelles integrations
6. **SPEC-007**: Mettre a jour le backlog produit
7. **SPEC-008**: Finaliser documentation technique

---

## Annexe A: Sources et References

- RGPD (Reglement 2016/679)
- Digital Services Act (DSA) - 2024
- App Store Review Guidelines (2025)
- Google Play Developer Policy (2025)
- Loi Evin (Loi n 91-32 du 10 janvier 1991)
- Tendances Mobile 2025 (Gartner, Statista)

---

## Annexe B: Comparaison Stack Technique

| Composant | 2014 (prevu) | 2026 (actuel) | Note |
|-----------|--------------|---------------|------|
| Mobile | Natif Android/iOS | Flutter | Excellente decision |
| Backend | PHP/MySQL (implicite) | Appwrite | Moderne et scalable |
| Auth | Custom | Appwrite Auth + OAuth2 | Standard |
| Maps | Google Maps | OpenStreetMap (flutter_map) | Gratuit, flexible |
| Push | GCM | FCM + APNs | Standard actuel |
| State | N/A | Riverpod | Best practice Flutter |

---

*Document genere dans le cadre de l'Epic E0 - Modernisation Spec 2026*
*FUG Project - The Develobeers*
