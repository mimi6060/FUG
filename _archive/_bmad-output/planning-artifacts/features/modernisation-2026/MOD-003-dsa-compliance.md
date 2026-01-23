# MOD-003: Conformite DSA (Digital Services Act)

> **Priorite:** HAUTE
> **Phase:** 1 - Conformite & Obligations Legales
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Mettre l'application FUG en conformite avec le Digital Services Act (DSA) europeen, en vigueur depuis fevrier 2024.

## Contexte Reglementaire

Le DSA impose des obligations aux plateformes en ligne concernant:
- La moderation de contenus
- La transparence des algorithmes
- Le signalement de contenus illegaux
- La protection des mineurs

**Note:** FUG est une "petite plateforme" (< 45M utilisateurs UE) donc obligations allegees, mais certaines restent obligatoires.

---

## Obligations Applicables a FUG

| Obligation DSA | Applicable | Priorite |
|----------------|------------|----------|
| Point de contact | Oui | Haute |
| Conditions generales claires | Oui | Haute |
| Mecanisme de signalement | Oui | Haute |
| Moderation transparente | Oui | Moyenne |
| Rapport de transparence | Non (< 45M) | - |
| Algorithmes transparents | Non (< 45M) | - |

---

## User Stories

### US-DSA-01: Point de Contact
**En tant que** autorite de regulation
**Je veux** contacter facilement FUG
**Afin de** communiquer sur des questions legales

**Criteres d'acceptation:**
- [ ] Adresse email dediee: dsa@fug.app
- [ ] Page "Contact legal" dans l'app
- [ ] Mention dans CGU et politique de confidentialite
- [ ] Reponse sous 24h ouvrables

**Points:** 2

### US-DSA-02: Conditions Generales Claires
**En tant que** utilisateur
**Je veux** comprendre les regles de la plateforme
**Afin de** savoir ce qui est autorise ou interdit

**Criteres d'acceptation:**
- [ ] CGU en langage clair et comprehensible
- [ ] Sections: contenus interdits, sanctions, recours
- [ ] Version simplifiee (resume)
- [ ] Acceptation explicite a l'inscription
- [ ] Notification des modifications

**Points:** 3

### US-DSA-03: Signalement de Contenu
**En tant que** utilisateur
**Je veux** signaler un contenu problematique
**Afin de** contribuer a une plateforme sure

**Criteres d'acceptation:**
- [ ] Bouton "Signaler" sur evenements et profils
- [ ] Categories: illegal, inapproprie, spam, autre
- [ ] Description optionnelle
- [ ] Confirmation de reception
- [ ] Suivi du signalement (accepte/rejete)

**Points:** 5

### US-DSA-04: Moderation Transparente
**En tant que** utilisateur dont le contenu est modere
**Je veux** comprendre pourquoi et pouvoir contester
**Afin de** beneficier d'un traitement equitable

**Criteres d'acceptation:**
- [ ] Notification en cas de moderation
- [ ] Raison explicite de la decision
- [ ] Mecanisme de contestation (appel)
- [ ] Delai de reponse a la contestation (72h)
- [ ] Decision finale motivee

**Points:** 5

### US-DSA-05: Protection des Mineurs
**En tant que** plateforme
**Je dois** empecher l'acces aux mineurs
**Afin de** respecter la legislation sur l'alcool

**Criteres d'acceptation:**
- [ ] Verification age a l'inscription (date naissance)
- [ ] Warning explicite "contenu 18+"
- [ ] Pas de publicite ciblee vers mineurs
- [ ] Blocage des comptes mineurs detectes

**Points:** 3

---

## Implementation Technique

### Signalement de Contenu

```dart
// Collection: reports
{
  'id': String,
  'reporter_id': String,      // Qui signale
  'content_type': String,     // 'event', 'user', 'comment'
  'content_id': String,       // ID du contenu signale
  'category': String,         // 'illegal', 'inappropriate', 'spam', 'other'
  'description': String?,     // Description optionnelle
  'status': String,           // 'pending', 'reviewed', 'actioned', 'dismissed'
  'moderator_id': String?,    // Qui a traite
  'moderator_note': String?,  // Note interne
  'action_taken': String?,    // 'warning', 'removed', 'banned', 'none'
  'created_at': DateTime,
  'reviewed_at': DateTime?,
}
```

### Ecran de Signalement

```dart
class ReportContentSheet extends StatelessWidget {
  final String contentType;
  final String contentId;

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      child: Column(
        children: [
          Text('Signaler ce contenu'),

          RadioListTile(
            title: Text('Contenu illegal'),
            subtitle: Text('Incitation a la haine, violence, etc.'),
            value: 'illegal',
            groupValue: selectedCategory,
            onChanged: (v) => setState(() => selectedCategory = v),
          ),

          RadioListTile(
            title: Text('Contenu inapproprie'),
            subtitle: Text('Ne respecte pas les CGU'),
            value: 'inappropriate',
            // ...
          ),

          RadioListTile(
            title: Text('Spam'),
            value: 'spam',
            // ...
          ),

          TextField(
            decoration: InputDecoration(
              labelText: 'Details (optionnel)',
            ),
            maxLines: 3,
          ),

          ElevatedButton(
            onPressed: _submitReport,
            child: Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
```

### Notification de Moderation

```dart
// Notification envoyee quand contenu modere
{
  'type': 'content_moderated',
  'title': 'Action de moderation',
  'body': 'Votre evenement "..." a ete retire',
  'data': {
    'content_type': 'event',
    'content_id': '...',
    'reason': 'Violation des CGU: contenu inapproprie',
    'action': 'removed',
    'appeal_url': 'https://fug.app/appeal/...',
  }
}
```

---

## Contenus Interdits (CGU)

A inclure dans les Conditions Generales:

1. **Contenus illegaux**
   - Incitation a la haine
   - Apologie de crimes
   - Contenu pedopornographique
   - Violation droits d'auteur

2. **Contenus inappropries**
   - Harcelement
   - Doxxing
   - Spam commercial
   - Fausses informations

3. **Comportements interdits**
   - Usurpation d'identite
   - Manipulation de la plateforme
   - Contournement des regles

---

## Definition of Done

- [ ] Point de contact DSA configure
- [ ] CGU mises a jour et validees juridiquement
- [ ] Systeme de signalement fonctionnel
- [ ] Workflow de moderation en place
- [ ] Mecanisme d'appel operationnel
- [ ] Documentation interne moderateurs

---

## Timeline

| Etape | Duree | Dependances |
|-------|-------|-------------|
| US-DSA-01 Point contact | 0.5j | Domaine email |
| US-DSA-02 CGU | 3j | Revue juridique |
| US-DSA-03 Signalement | 3j | - |
| US-DSA-04 Moderation | 3j | Backend moderation |
| US-DSA-05 Mineurs | 1j | Deja partiellement fait |
| **TOTAL** | **~2 semaines** | |

---

*Feature BMAD - Epic E0 Modernisation 2026*
