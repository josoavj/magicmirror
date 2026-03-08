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

### 1. Google Calendar API (Agenda)

#### Setup OAuth2
1. Aller à [Google Cloud Console](https://console.cloud.google.com)
2. Créer un nouveau projet
3. Activer l'API "Google Calendar API"
4. Créer les credentials OAuth2:
   - Type: Application Web
   - Redirection URIs: `com.googleusercontent.apps.{CLIENT_ID}:/oauth2redirect`

#### Android
Ajouter dans `android/app/build.gradle`:
```gradle
client_id='YOUR_CLIENT_ID.apps.googleusercontent.com'
```

#### iOS
Ajouter dans `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

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
