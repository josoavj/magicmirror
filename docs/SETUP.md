# Configuration production — Magic Mirror

> Guide complet pour configurer et déployer Magic Mirror en environnement de production.

---

## Table des matières

1. [Prérequis](#prérequis)
2. [Configuration API](#configuration-api)
3. [Build & déploiement](#build--déploiement)
4. [Checklist finale](#checklist-finale)

---

## Prérequis

| Outil | Version minimale |
|---|---|
| Flutter | ≥ 3.1.0 |
| Dart | ≥ 3.1.0 |
| Xcode | Dernière version stable *(iOS uniquement)* |
| Android Studio | Dernière version stable *(Android uniquement)* |

Les comptes API (Supabase, OpenWeatherMap) doivent également être configurés — voir les sections suivantes.

---

## Configuration API

### 1. Supabase — Auth, profil & agenda

Renseigner les variables dans `.env` :

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Puis exécuter les scripts SQL documentés dans [SUPABASE_SETUP.md](https://github.com/josoavj/magicmirror/blob/master/docs/SUPABASE_SETUP.md) :

- Table `profiles` + politiques RLS
- Bucket `avatars` + politiques de stockage
- Table `agenda_events` + politiques RLS

### 2. OpenWeatherMap — Météo

```env
OPENWEATHERMAP_API_KEY=your_production_key
```

Voir [WEATHER_SETUP.md](https://github.com/josoavj/magicmirror/blob/master/docs/WEATHER_SETUP.md) pour le guide complet et les options de configuration.

---

## Build & déploiement

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommandé pour le Play Store)
flutter build appbundle --release
```

Fichiers générés :

```
build/app/outputs/flutter-apk/       # APK
build/app/outputs/bundle/release/    # App Bundle
```

### iOS

```bash
# Build release
flutter build ios --release

# Ouvrir le workspace Xcode pour archiver
open ios/Runner.xcworkspace
# Xcode → Product → Archive
# Puis : Organizer → Distribute App → App Store Connect
```

### Web

```bash
flutter build web --release
# Fichiers générés dans : build/web/
# Déployer sur Netlify, Firebase Hosting, ou tout autre hébergeur statique
```

### Linux

```bash
flutter build linux --release
# Fichiers générés dans : build/linux/x64/release/bundle/
```

### Windows

```bash
flutter build windows --release
# Fichiers générés dans : build/windows/runner/Release/
```

---

## Checklist finale

### Configuration

- [ ] Variables d'environnement renseignées dans `.env`
- [ ] Clés et certificats configurés pour toutes les plateformes cibles
- [ ] Permissions Android et iOS déclarées

### Qualité

- [ ] `flutter analyze` sans erreurs
- [ ] Tous les tests passent (`flutter test`)

### Apparence

- [ ] Icônes et écrans de démarrage (*splash screens*) en place
- [ ] Numéros de version et de build à jour

### Légal & distribution

- [ ] Politique de confidentialité et conditions d'utilisation rédigées
- [ ] Comptes App Store et Play Store créés
- [ ] Certificats de signature configurés

---

Voir aussi [ARCHITECTURE.md](https://github.com/josoavj/magicmirror/blob/master/ARCHITECTURE.md) pour la structure interne du code.