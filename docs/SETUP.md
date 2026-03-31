# 📋 Configuration Production - Magic Mirror

## 🔧 Configuration complète pour la production

Ce guide couvre toutes les étapes nécessaires pour configurer Magic Mirror en environnement production.

### Table des matières
1. [Prérequis](#prérequis)
2. [Configuration API](#configuration-api)
3. [Build & Déploiement](#build--déploiement)
4. [Checklist finale](#checklist-finale)

---

## Prérequis

- ✅ Flutter >= 3.1.0
- ✅ Dart >= 3.1.0
- ✅ Xcode (pour iOS)
- ✅ Android Studio (pour Android)
- ✅ Comptes API configurés (voir sections suivantes)

---

## Configuration API

### 1. Supabase (Auth + Profil + Agenda)

Configurer les variables dans votre `.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Puis executer les scripts SQL documentes dans [SUPABASE_SETUP.md](SUPABASE_SETUP.md):
- table `profiles` + politiques RLS
- bucket `avatars` + politiques storage
- table `agenda_events` + politiques RLS

### 2. OpenWeatherMap API (Météo)

Voir: [WEATHER_SETUP.md](WEATHER_SETUP.md) pour détails complets.

```env
OPENWEATHERMAP_API_KEY=your_production_key
```

---

## Build & Déploiement

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Localiser build
cd build/app/outputs/flutter-apk/
# ou
cd build/app/outputs/bundle/release/
```

### iOS

```bash
# Build
flutter build ios --release

# Archive pour App Store
open ios/Runner.xcworkspace
# Xcode > Product > Archive

# Export IPA
# Dans Organizer > Distribute App > App Store Connect
```

### Web

```bash
flutter build web --release

# Output: build/web/
# Déployer sur votre hosting (Netlify, Firebase, etc)
```

### Linux

```bash
flutter build linux --release

# Output: build/linux/x64/release/bundle/
```

### Windows

```bash
flutter build windows --release

# Output: build/windows/runner/Release/
```

---

## Checklist finale

- [ ] Variables d'environnement configurées (`.env`)
- [ ] Keys/Certificates pour toutes les platefomes
- [ ] Tous les tests passent (`flutter test`)
- [ ] `flutter analyze` sans erreurs
- [ ] Permissions Android/iOS configurées
- [ ] Icons et splash screens en place
- [ ] Version/build numbers à jour
- [ ] Privacy policy et terms of service ready
- [ ] Comptes app store/play store créés
- [ ] Receipt signing certificates configured

Voir aussi: [ARCHITECTURE.md](ARCHITECTURE.md) pour la structure interne du code
