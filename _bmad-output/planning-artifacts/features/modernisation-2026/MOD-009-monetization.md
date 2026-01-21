# MOD-009: Monetisation Ethique

> **Priorite:** BASSE
> **Phase:** 3 - Nouvelles Fonctionnalites (V2+)
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Definir un modele de monetisation ethique et durable pour FUG, en remplacement du modele 2014 (version gratuite + payante).

## Modele 2014 (Obsolete)

- Version gratuite avec pubs
- Version payante sans pubs
- Pubs localisees

**Problemes:**
- RGPD rend la pub ciblee complexe
- Modele freemium classique depasse
- Pas de valeur ajoutee claire pour le premium

---

## Nouveau Modele Propose

### Option A: FUG Premium (Recommande)

**Prix:** 4.99 EUR/mois ou 39.99 EUR/an

**Avantages Premium:**
| Feature | Gratuit | Premium |
|---------|---------|---------|
| Creer des FUG | 3/mois | Illimite |
| Voir qui consulte mon profil | Non | Oui |
| Badges exclusifs | Non | Oui |
| Support prioritaire | Non | Oui |
| Sans publicite | Non | Oui |
| Statistiques avancees | Basiques | Detaillees |
| Boost evenements | Non | 1/semaine |

### Option B: Partenariats Bars (Complementaire)

**Fonctionnement:**
1. Bars partenaires paient pour visibilite
2. Badge "Lieu partenaire" sur evenements
3. Offres speciales pour utilisateurs FUG

**Ethique:**
- Clairement identifie comme partenariat
- Pas de manipulation du classement
- Utilisateurs informes

### Option C: Badges Sponsorises (Optionnel)

**Exemple:**
- Badge "Amateur de Leffe" sponsorise par Leffe
- Badge "Decouverte du mois" sponsorise par un bar

**Contraintes:**
- Pas de sponsoring alcool fort
- Moderation du nombre de sponsors
- Coherent avec image de marque

---

## Ce qu'on NE FAIT PAS

| Pratique | Raison |
|----------|--------|
| Vente de donnees | Illegal RGPD, contraire a nos valeurs |
| Pub comportementale | Complexe RGPD, mauvaise UX |
| Pay-to-win | Detruit l'experience |
| Dark patterns | Contraire aux guidelines |
| Bloquer features core | Frustrant, contre-productif |

---

## Implementation

### In-App Purchases

```dart
// Gestion abonnements avec RevenueCat
class SubscriptionService {
  Future<void> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.monthly;

      if (package != null) {
        await Purchases.purchasePackage(package);
        // Mettre a jour le statut utilisateur
      }
    } on PlatformException catch (e) {
      // Gerer erreurs
    }
  }

  Stream<bool> get isPremium {
    return Purchases.customerInfoStream.map(
      (info) => info.entitlements.active.containsKey('premium'),
    );
  }
}
```

### UI Premium

```dart
class PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 48),
            Text('Passez a FUG Premium'),
            Text('Creez des FUG illimitees et bien plus'),
            ElevatedButton(
              onPressed: () => _showPremiumDetails(context),
              child: Text('Decouvrir'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Metriques de Succes

| Metrique | Cible |
|----------|-------|
| Conversion free -> premium | 2-5% |
| Retention premium 12 mois | 60% |
| Revenue/utilisateur | 0.50 EUR/mois |
| Satisfaction premium | 4.5/5 |

---

## User Stories

### US-MON-01: Ecran Premium
**Points:** 5
**Priorite:** Could (V2)

### US-MON-02: Gestion Abonnements
**Points:** 8
**Priorite:** Could (V2)

### US-MON-03: Dashboard Partenaires
**Points:** 13
**Priorite:** Won't (V3)

---

## Timeline

| Feature | Version |
|---------|---------|
| Premium basique | V2 |
| Partenariats | V3 |
| Badges sponsors | V3+ |

---

*Feature BMAD - Epic E0 Modernisation 2026*
