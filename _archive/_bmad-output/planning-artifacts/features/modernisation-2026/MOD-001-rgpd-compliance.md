# MOD-001: Conformite RGPD Complete

> **Priorite:** CRITIQUE
> **Phase:** 1 - Conformite & Obligations Legales
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Mettre l'application FUG en conformite complete avec le Reglement General sur la Protection des Donnees (RGPD/GDPR).

## Probleme

L'application collecte et traite des donnees personnelles (email, localisation, preferences) sans implementation complete des droits RGPD:
- Droit a l'oubli (US-006) non finalise
- Consentement explicite non implemente
- Export des donnees non disponible
- Politique de confidentialite incomplete

## Risques si Non-Implemente

| Risque | Impact | Probabilite |
|--------|--------|-------------|
| Amende CNIL jusqu'a 4% CA ou 20M EUR | CRITIQUE | Moyenne |
| Retrait des app stores | CRITIQUE | Faible |
| Perte de confiance utilisateurs | HAUTE | Haute |

---

## User Stories

### US-RGPD-01: Consentement Explicite
**En tant que** nouvel utilisateur
**Je veux** donner mon consentement explicite pour le traitement de mes donnees
**Afin de** comprendre et controler l'usage de mes informations

**Criteres d'acceptation:**
- [ ] Ecran de consentement au premier lancement
- [ ] Cases a cocher separees: donnees essentielles, analytics, marketing
- [ ] Lien vers politique de confidentialite complete
- [ ] Stockage du consentement avec horodatage
- [ ] Possibilite de modifier les consentements plus tard

**Points:** 5

### US-RGPD-02: Droit a l'Oubli (Finaliser US-006)
**En tant que** utilisateur
**Je veux** supprimer definitivement mon compte et mes donnees
**Afin de** exercer mon droit a l'oubli

**Criteres d'acceptation:**
- [ ] Bouton "Supprimer mon compte" dans parametres
- [ ] Double confirmation avec mot de passe
- [ ] Delai de grace 30 jours (annulable)
- [ ] Anonymisation des donnees historiques
- [ ] Suppression des fichiers (avatar, etc.)
- [ ] Email de confirmation
- [ ] Logs d'audit de la suppression

**Points:** 8

### US-RGPD-03: Export des Donnees (Portabilite)
**En tant que** utilisateur
**Je veux** exporter toutes mes donnees personnelles
**Afin de** exercer mon droit a la portabilite

**Criteres d'acceptation:**
- [ ] Bouton "Exporter mes donnees" dans parametres
- [ ] Generation fichier JSON/ZIP
- [ ] Inclus: profil, evenements, participations, followers
- [ ] Telechargement securise (lien temporaire)
- [ ] Notification par email quand pret

**Points:** 5

### US-RGPD-04: Politique de Confidentialite
**En tant que** utilisateur
**Je veux** consulter une politique de confidentialite claire
**Afin de** comprendre comment mes donnees sont utilisees

**Criteres d'acceptation:**
- [ ] Page dediee dans l'app
- [ ] Langage clair et comprehensible
- [ ] Sections: donnees collectees, finalites, duree, droits
- [ ] Version PDF telecharable
- [ ] Historique des versions

**Points:** 3

---

## Implementation Technique

### Backend (Appwrite)

```dart
// Function: export-user-data
Future<String> exportUserData(String userId) async {
  final userData = await databases.getDocument(
    databaseId: 'fug_database',
    collectionId: 'users',
    documentId: userId,
  );

  final events = await databases.listDocuments(
    databaseId: 'fug_database',
    collectionId: 'events',
    queries: [Query.equal('creator_id', userId)],
  );

  final participations = await databases.listDocuments(
    databaseId: 'fug_database',
    collectionId: 'event_participants',
    queries: [Query.equal('user_id', userId)],
  );

  // Generer JSON structure
  return jsonEncode({
    'export_date': DateTime.now().toIso8601String(),
    'user': userData.data,
    'events_created': events.documents.map((e) => e.data).toList(),
    'participations': participations.documents.map((p) => p.data).toList(),
  });
}
```

### Frontend (Flutter)

```dart
// Ecran de consentement
class ConsentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          Text('Vos donnees, votre controle'),
          CheckboxListTile(
            title: Text('Donnees essentielles (obligatoire)'),
            subtitle: Text('Necessaire au fonctionnement'),
            value: true,
            onChanged: null, // Obligatoire
          ),
          CheckboxListTile(
            title: Text('Analytics'),
            subtitle: Text('Ameliorer l\'application'),
            value: ref.watch(analyticsConsentProvider),
            onChanged: (v) => ref.read(analyticsConsentProvider.notifier).set(v),
          ),
          // ...
        ],
      ),
    );
  }
}
```

---

## Definition of Done

- [ ] Toutes les US implementees et testees
- [ ] Tests unitaires > 80% couverture
- [ ] Revue juridique de la politique de confidentialite
- [ ] Documentation technique mise a jour
- [ ] Validation par DPO ou conseiller juridique

---

## Stories Plane Associees

| Story Plane | Titre | Statut |
|-------------|-------|--------|
| US-006 | Suppression de compte | TODO |
| SPEC-005 | Audit conformite RGPD/DSA | TODO |

---

## Timeline

| Etape | Duree | Dependances |
|-------|-------|-------------|
| US-RGPD-01 Consentement | 3j | - |
| US-RGPD-02 Suppression | 5j | Backend function |
| US-RGPD-03 Export | 3j | Backend function |
| US-RGPD-04 Politique | 2j | Revue juridique |
| **TOTAL** | **~2 semaines** | |

---

*Feature BMAD - Epic E0 Modernisation 2026*
