# MOD-006: Politique de Confidentialite Complete

> **Priorite:** HAUTE
> **Phase:** 2 - Mise a Jour Technique
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Creer une politique de confidentialite complete, conforme RGPD/DSA, accessible dans l'application.

## Exigences Legales

- **RGPD Art. 13-14**: Information des personnes concernees
- **DSA**: Transparence sur le traitement des donnees
- **App Store/Play Store**: Privacy policy obligatoire

---

## Structure de la Politique

### 1. Identite du Responsable
- Nom: The Develobeers
- Adresse: [A completer]
- Contact: privacy@fug.app
- DPO: [Si applicable]

### 2. Donnees Collectees

| Categorie | Donnees | Finalite | Base legale |
|-----------|---------|----------|-------------|
| Identite | Email, pseudo, nom | Compte utilisateur | Contrat |
| Profil | Photo, bio, preferences | Personnalisation | Consentement |
| Localisation | GPS | Fonctionnalite core | Consentement |
| Activite | Evenements, participations | Service | Contrat |
| Technique | Device ID, logs | Securite, debug | Interet legitime |

### 3. Finalites du Traitement

1. Gestion du compte utilisateur
2. Fonctionnement du service (evenements, carte)
3. Notifications et communications
4. Amelioration du service (analytics)
5. Securite et prevention des fraudes

### 4. Duree de Conservation

| Donnee | Duree | Justification |
|--------|-------|---------------|
| Compte actif | Duree du compte | Service |
| Compte supprime | 30 jours puis anonymisation | Droit de retractation |
| Logs techniques | 12 mois | Debug et securite |
| Donnees anonymisees | Illimitee | Statistiques |

### 5. Destinataires

- Hebergeur: Appwrite / [Cloud provider]
- Sous-traitants: [Liste]
- Pas de vente a des tiers

### 6. Transferts Hors UE

- Mesures de protection: [Clauses contractuelles types]
- Pays concernes: [Liste]

### 7. Droits des Utilisateurs

- Droit d'acces
- Droit de rectification
- Droit a l'effacement
- Droit a la portabilite
- Droit d'opposition
- Droit de retirer le consentement

**Exercice des droits:** privacy@fug.app

### 8. Cookies et Traceurs

| Traceur | Finalite | Consentement |
|---------|----------|--------------|
| Session | Fonctionnement | Non requis |
| Analytics | Amelioration | Requis |
| [Autres] | [Finalite] | [Oui/Non] |

### 9. Modifications

- Notification 30 jours avant
- Historique des versions disponible

---

## Implementation

### Page In-App

```dart
class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Politique de confidentialite')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Derniere mise a jour: 21 janvier 2026'),
            SizedBox(height: 16),

            _Section(
              title: '1. Qui sommes-nous ?',
              content: '...',
            ),

            _Section(
              title: '2. Quelles donnees collectons-nous ?',
              content: '...',
            ),

            // ... autres sections

            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Telecharger en PDF'),
              onPressed: _downloadPdf,
            ),
          ],
        ),
      ),
    );
  }
}
```

### Acces depuis l'App

Liens vers la politique depuis:
- Ecran d'inscription
- Parametres > Confidentialite
- Footer de l'app
- Ecran de consentement

---

## Definition of Done

- [ ] Politique redigee en francais
- [ ] Traduction anglais
- [ ] Revue juridique validee
- [ ] Page in-app implementee
- [ ] Version PDF disponible
- [ ] Liens depuis tous les points d'acces

---

## Timeline

| Etape | Duree |
|-------|-------|
| Redaction | 2j |
| Revue juridique | 3j (externe) |
| Implementation UI | 1j |
| Traductions | 1j |
| **TOTAL** | **~1 semaine** |

---

*Feature BMAD - Epic E0 Modernisation 2026*
