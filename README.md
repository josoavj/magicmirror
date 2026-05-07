<p align="center">
  <img src="https://github.com/josoavj/magicmirror/assets/76913187/5dda5a6a-5e5d-41e6-a818-17b853a7957f" alt="Magic Mirror Logo" width="150"/>
</p>

<h1 align="center">Magic Mirror</h1>

<p align="center">
  <strong>Miroir intelligent avec caméra, météo et suggestions de tenues</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.1.0-blue?style=flat-square" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.1.0-blue?style=flat-square" alt="Dart Version">
  <img src="https://img.shields.io/badge/Version-1.0.1--beta%2B2-orange?style=flat-square" alt="Version actuelle">
  <img src="https://img.shields.io/badge/Status-Beta-yellow?style=flat-square" alt="Statut Beta">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="Licence">
  <img src="https://img.shields.io/github/last-commit/josoavj/magicmirror?style=flat-square" alt="Dernier commit">
</p>

---

## 📊 Vue d'ensemble des fonctionnalités

| Fonctionnalité | Statut | Détails |
|---|---|---|
| 🪞 **Miroir caméra** | ✅ 100% | Caméra temps réel, détection morphologie, affichage plein écran |
| 📅 **Agenda / Calendrier** | ✅ 100% | Agenda cloud Supabase lié au compte actif |
| 🌦️ **Météo** | ✅ 100% | API OpenWeatherMap réelle + géolocalisation automatique |
| 🤖 **Morphologie IA** | ✅ 100% | Google ML Kit — détection de pose + classification morphologique |
| 👔 **Suggestions de tenues** | ✅ 100% | Filtrées par contexte + ranking hybride (ML + LLM) |
| 👤 **Profil utilisateur** | ✅ 100% | Local + sync Supabase (profil, avatar, préférences) |
| ⭐ **Favoris & feedback** | ✅ 100% | Favoris synchronisés + télémétrie de feedback |
| 🗣️ **Synthèse vocale** | ✅ 100% | FlutterTTS en français pour les recommandations |
| 📱 **UI responsive** | ✅ 100% | Design glassmorphism, support multi-écran |

---

## 🚀 Démarrage rapide

### Installation

```bash
# Cloner le dépôt et installer les dépendances
git clone https://github.com/josoavj/magicmirror.git
cd magicmirror
flutter pub get

# Vérifier les erreurs (optionnel)
flutter analyze
```

### Exécution

```bash
# Lancer l'app en développement
flutter run

# Lancer sur un appareil spécifique
flutter run -d <device_id>
```

### Build de production

```bash
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
flutter build windows    # Windows
flutter build linux      # Linux
flutter build macos      # macOS
```

---

## ⚙️ Configuration requise

### 1️⃣ Météo — OpenWeatherMap (2 min) ⚡

**Configuration sécurisée via `assets/.env`**

```bash
# 1. Copier le template
cp .env.example assets/.env
```

```bash
# 2. Obtenir une clé API gratuite sur :
#    https://openweathermap.org/api
```

```env
# 3. Renseigner la clé dans assets/.env
OPENWEATHERMAP_API_KEY=votre_cle_ici
```

> ✅ Le fichier `.env` est automatiquement dans `.gitignore` — votre clé ne sera jamais exposée sur GitHub.

Voir [WEATHER_SETUP.md](docs/WEATHER_SETUP.md) pour le guide complet.

### 2️⃣ Backend Supabase (recommandé)

- Renseigner `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `assets/.env`
- Créer les tables `profiles`, `agenda_events` et les politiques RLS

Voir [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) pour le guide complet.

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # Point d'entrée (AuthGate + routes)
├── config/
│   ├── app_config.dart                # Feature flags & configuration
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/                          # Connexion, vérification email, réinitialisation
│   ├── user_profile/                  # Profil utilisateur + synchronisation cloud
│   ├── agenda/                        # Agenda Supabase (CRUD)
│   ├── mirror/                        # Écran miroir / caméra principal
│   ├── weather/                       # Météo + providers / repositories
│   ├── ai_ml/                         # Détection morphologie (ML Kit)
│   ├── outfit_suggestion/             # Suggestions de tenues
│   └── settings/                      # Paramètres app + compte
├── presentation/
│   ├── screens/
│   │   └── about_screen.dart
│   └── widgets/
│       └── glass_container.dart
├── routes/
│   ├── app_routes.dart
│   └── route_names.dart
└── generated/
    └── assets.gen.dart
```

### Structure type d'une feature (exemple : agenda)

```
lib/features/agenda/
├── data/
│   ├── datasources/
│   ├── models/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

### Fichiers clefs

```
lib/features/agenda/data/services/agenda_supabase_service.dart
lib/features/auth/presentation/screens/auth_screen.dart
lib/features/settings/presentation/screens/account_settings_screen.dart
lib/features/user_profile/presentation/providers/user_profile_provider.dart
lib/features/weather/data/services/weather_service.dart
```

---

## 🔐 Dépendances principales

### State management

- `flutter_riverpod: ^3.2.1` — Gestion d'état réactive

### Configuration & secrets

- `flutter_dotenv: ^5.1.0` — Variables d'environnement sécurisées

### Services & API

- `dio: ^5.3.1` — Client HTTP
- `supabase_flutter: ^2.x` — Auth + profil + agenda (mobile & web)
- `geolocator: ^12.0.0` — Géolocalisation GPS

### Caméra & médias

- `camera: ^0.12.0` — Accès caméra
- `camera_linux: ^0.0.8` — Support Linux
- `image: ^4.1.3` — Traitement d'images
- `google_ml_kit: ^0.21.0` — Détection de pose (ML Kit)

### Utilitaires

- `intl: ^0.20.2` — Localisation & internationalisation
- `uuid: ^4.0.0` — Génération d'UUID
- `shared_preferences: ^2.2.2` — Stockage local
- `flutter_tts: ^4.2.5` — Synthèse vocale
- `permission_handler: ^12.0.1` — Gestion des permissions

---

## 🌍 Support des plateformes

| Plateforme | Statut | Caméra | Météo | Agenda | Notes |
|---|---|---|---|---|---|
| 📱 **Android** | ✅ | ✅ | ✅ | ✅ | Support complet |
| 🍎 **iOS** | ✅ | ✅ | ✅ | ✅ | Support complet |
| 🖥️ **macOS** | ✅ | ✅ | ✅ | ✅ | Support complet |
| 💻 **Windows** | ⚠️ | ⚠️ | ✅ | ✅ | Caméra partielle |
| 🐧 **Linux** | ⚠️ | ⚠️ | ✅ | ✅ | Caméra partielle |
| 🌐 **Web** | ❌ | ❌ | ✅ | ✅ | Caméra non supportée |

Voir [CAMERA_SUPPORT.md](docs/CAMERA_SUPPORT.md) pour les détails par plateforme.

---

## 📚 Documentation

| Fichier | Description |
|---|---|
| [SETUP.md](docs/SETUP.md) | Configuration complète pour la production |
| [WEATHER_SETUP.md](docs/WEATHER_SETUP.md) | Configuration météo OpenWeatherMap |
| [GETTING_STARTED.md](docs/GETTING_STARTED.md) | Guide de démarrage rapide |
| [CAMERA_SUPPORT.md](docs/CAMERA_SUPPORT.md) | Support caméra par plateforme |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture de l'application |
| [OUTFIT_ML_PIPELINE.md](docs/OUTFIT_ML_PIPELINE.md) | Pipeline ML (LightGBM) |
| [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) | Schéma et policies Supabase |
| [LOGGING.md](docs/LOGGING.md) | Logging et diagnostic |
| [CHANGELOG.md](CHANGELOG.md) | Historique des changements |

---

## 🔧 Configuration avancée

### Feature flags

Voir [`lib/config/app_config.dart`](lib/config/app_config.dart) :

```dart
static const bool enableAIFeatures          = true;
static const bool enableWeatherIntegration  = true;
static const bool enableAgendaSync          = true;
static const bool enableOutfitSuggestions   = true;
```

### Mode développement / production

```dart
static const bool isDevelopment     = true;  // false en production
static const bool enableDebugLogging = true;
```

### Délais et timeouts

```dart
static const Duration networkTimeout = Duration(seconds: 30);
static const Duration cacheExpiry    = Duration(hours: 24);
```

---

## 🧪 Tests & validation

```bash
flutter analyze
flutter test
```

```bash
flutter analyze          # Lint & détection d'erreurs
flutter doctor           # Diagnostics plateforme
flutter pub get          # Vérification des dépendances

flutter test             # Tests unitaires
flutter test --coverage  # Rapport de couverture
```

---

## 🐛 Dépannage

### « Permission denied » sur Android

```bash
flutter clean
flutter pub get
flutter run
# Accepter les permissions au premier lancement
```

### « Camera not initialized »

- Patienter 5 secondes le temps que la caméra se verrouille
- Vérifier les permissions dans les paramètres de l'appareil
- Relancer l'application

### Météo affiche « Non disponible »

- Vérifier la clé API dans `weather_service.dart`
- Vérifier la connexion internet
- Consulter le dépannage dans [WEATHER_SETUP.md](docs/WEATHER_SETUP.md)

### « Agenda non disponible »

- Vérifier `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `.env`
- Exécuter le SQL décrit dans [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)
- Vérifier que l'utilisateur est bien connecté

---


## 👥 Contribution

Les contributions sont les bienvenues !

1. Forker le projet
2. Créer une branche : `git checkout -b feature/amazing-feature`
3. Commiter les changements : `git commit -m 'Add amazing feature'`
4. Pousser la branche : `git push origin feature/amazing-feature`
5. Ouvrir une Pull Request

---

## 📄 Licence

MIT License — voir [LICENSE](LICENSE) pour les détails.

---

## 📞 Support

- **Issues** : [GitHub Issues](https://github.com/josoavj/magicmirror/issues)
- **Discussions** : [GitHub Discussions](https://github.com/josoavj/magicmirror/discussions)
- **E-mail** : support@magicmirror.app

---

<p align="center">Made by <a href="https://github.com/josoavj">@josoavj</a></p>

---

### Liens utiles

- 🌐 [Dépôt GitHub](https://github.com/josoavj/magicmirror)
- 📖 [Documentation Flutter](https://flutter.dev)
- 🤖 [Google ML Kit](https://developers.google.com/ml-kit)
- 📡 [API OpenWeatherMap](https://openweathermap.org/api)
- 🗄️ [Documentation Supabase](https://supabase.com/docs)