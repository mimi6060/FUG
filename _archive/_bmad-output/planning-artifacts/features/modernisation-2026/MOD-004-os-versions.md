# MOD-004: Mise a Jour Versions OS Minimales

> **Priorite:** MOYENNE
> **Phase:** 2 - Mise a Jour Technique
> **Version:** 1.0
> **Date:** 2026-01-21

---

## Resume

Mettre a jour les versions minimum des OS supportes pour refleter les standards 2026 et garantir la securite.

## Situation Actuelle

| Plateforme | Spec 2014 | Actuel | Recommande 2026 |
|------------|-----------|--------|-----------------|
| Android | 4.0 (Ice Cream Sandwich) | ? | 10.0 (API 29) |
| iOS | Non specifie | ? | 14.0 |
| Web | Non specifie | Oui | Navigateurs modernes |

## Justification

### Securite
- Android < 10: pas de scoped storage, vulnerabilites connues
- iOS < 14: pas de App Tracking Transparency

### Fonctionnalites
- Android 10+: Dark mode natif, geolocalisation amelioree
- iOS 14+: Widgets, App Clips, privacy labels

### Market Share
- Android 10+ = 85%+ des devices actifs
- iOS 14+ = 95%+ des devices actifs

---

## Actions

### 1. Mettre a jour pubspec.yaml

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.16.0'

# android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 29  # Android 10
        targetSdkVersion 34  # Android 14
    }
}

# ios/Podfile
platform :ios, '14.0'
```

### 2. Mettre a jour la documentation

- README.md
- Document de vision
- Store listings

### 3. Communiquer aux utilisateurs

Si des utilisateurs sont sur d'anciennes versions:
- Notification in-app avant mise a jour
- Message explicatif sur stores

---

## Definition of Done

- [ ] pubspec.yaml mis a jour
- [ ] build.gradle Android mis a jour
- [ ] Podfile iOS mis a jour
- [ ] Tests sur versions minimales
- [ ] Documentation mise a jour

---

## Timeline

| Etape | Duree |
|-------|-------|
| Configuration | 0.5j |
| Tests | 1j |
| Documentation | 0.5j |
| **TOTAL** | **2 jours** |

---

*Feature BMAD - Epic E0 Modernisation 2026*
