<p align="center">
  <img src="https://github.com/josoavj/magicmirror/assets/76913187/5dda5a6a-5e5d-41e6-a818-17b853a7957f" alt="Magic Mirror Logo" width="150"/>
</p>

<h1 align="center">Magic Mirror</h1>

<p align="center">
  <strong>Miroir intelligent avec caméra, météo et suggestions de tenues</strong>
</p>

<p align="center">
  <!-- Badges -->
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.1.0-blue?style=flat-square" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.1.0-blue?style=flat-square" alt="Dart Version">
  <img src="https://img.shields.io/badge/Version-1.0.0--beta.1-orange?style=flat-square" alt="Current Version">
  <img src="https://img.shields.io/badge/Status-Beta-yellow?style=flat-square" alt="Beta Status">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/github/last-commit/josoavj/magicmirror?style=flat-square" alt="Last Commit">
</p>

---

## 📊 Vue d'ensemble des fonctionnalités

| Fonctionnalité | Status | Détails |
|---|---|---|
| 🪞 **Miroir Caméra** | ✅ 100% | Caméra temps réel, détection morphologie, affichage full-screen |
| 📅 **Agenda/Calendrier** | ✅ 100% | Agenda cloud Supabase lie au compte actif |
| 🌦️ **Météo** | ✅ 100% | OpenWeatherMap API réelle + géolocalisation automatique |
| 🤖 **Morphologie AI** | ✅ 100% | Google ML Kit détection de pose + classification corps |
| 👔 **Suggestions tenues** | ✅ 100% | Filtrée par morphologie + TTS français intégrée |
| 🗣️ **Synthèse vocale** | ✅ 100% | FlutterTTS français pour recommandations |
| 📱 **Responsive UI** | ✅ 100% | Glass morphism design, support multi-écran |

---

## 🚀 Démarrage rapide

### Installation
```bash
# Cloner et installer
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

# Lancer sur appareil spécifique
flutter run -d <device_id>

# Build production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
flutter build linux        # Linux
flutter build macos        # macOS
```

---

## ⚙️ Configuration requise

### AVANT de lancer l'app

#### 1️⃣ **Configurer la météo (2 min)** ⚡
**NOUVEAU: Configuration sécurisée avec `.env`**

1. Copier le template d'environnement:
```bash
cp .env.example .env
```

2. Obtenir une clé API gratuite:
- Aller sur: https://openweathermap.org/api
- S'inscrire gratuitement
- Copier votre clé API

3. Remplacer la clé dans `.env`:
```env
OPENWEATHERMAP_API_KEY=votre_cle_ici
```

**⚠️ Important**: Le fichier `.env` est automatiquement dans `.gitignore` - votre clé ne sera jamais exposée sur GitHub! ✅

Voir: [WEATHER_SETUP.md](docs/WEATHER_SETUP.md) pour guide complet

#### 2️⃣ **Backend Supabase (recommandé)**
- Configuration URL + ANON KEY dans `.env`
- Création tables `profiles` + `agenda_events` + policies RLS
- Guide complet: [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # Point d'entree (AuthGate + routes)
├── config/
│   ├── app_config.dart                # Feature flags & configuration
│   └── di_setup.dart                  # Bootstrap des dependances
├── core/
│   ├── constants/
│   ├── services/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/                          # Connexion, vérification email, reset
│   ├── user_profile/                  # Profil utilisateur + sync cloud
│   ├── agenda/                        # Agenda Supabase (CRUD)
│   ├── mirror/                        # Écran miroir/caméra principal
│   ├── weather/                       # Météo + providers/repositories
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

### Exemple de structure feature (agenda)

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

### Extraits de fichiers importants

```
lib/features/agenda/data/services/agenda_supabase_service.dart
lib/features/auth/presentation/screens/auth_screen.dart
lib/features/settings/presentation/screens/account_settings_screen.dart
lib/features/user_profile/presentation/providers/user_profile_provider.dart
lib/features/weather/data/services/weather_service.dart
```

---

## 🔐 Dépendances principales

### State Management
- `flutter_riverpod: ^3.2.1` - Gestion d'état réactive

### Configuration & Secrets
- `flutter_dotenv: ^5.1.0` - Gestion variables d'environnement sécurisée

### Services & API
- `dio: ^5.3.1` - Client HTTP
- `supabase_flutter: ^2.x` - Backend Auth + Profil + Agenda (mobile + web)
- `geolocator: ^12.0.0` - Géolocalisation GPS

### Caméra & Média
- `camera: ^0.12.0` - Accès caméra
- `camera_linux: ^0.0.8` - Support Linux
- `image: ^4.1.3` - Traitement images
- `google_ml_kit: ^0.21.0` - ML Kit pour détection de pose

### Utils
- `intl: ^0.20.2` - Localisation & internationalization
- `uuid: ^4.0.0` - Génération UUIDs
- `shared_preferences: ^2.2.2` - Stockage local
- `flutter_tts: ^4.2.5` - Synthèse vocale
- `permission_handler: ^12.0.1` - Gestion permissions

---

## 🌍 Support plateforme

| Plateforme | Status | Caméra | Météo | Agenda | Notes |
|---|---|---|---|---|---|
| 📱 **Android** | ✅ | ✅ | ✅ | ✅ | Full support |
| 🍎 **iOS** | ✅ | ✅ | ✅ | ✅ | Full support |
| 🖥️ **macOS** | ✅ | ✅ | ✅ | ✅ | Full support |
| 💻 **Windows** | ⚠️ | ⚠️ | ✅ | ✅ | Caméra partielle |
| 🐧 **Linux** | ⚠️ | ⚠️ | ✅ | ✅ | Caméra partielle |
| 🌐 **Web** | ❌ | ❌ | ✅ | ✅ | Pas de caméra |

*Voir [CAMERA_SUPPORT.md](docs/CAMERA_SUPPORT.md) pour détails platform-spécifiques*

---

## 📚 Documentation

- [SETUP.md](docs/SETUP.md) - Configuration complète production
- [WEATHER_SETUP.md](docs/WEATHER_SETUP.md) - Configuration météo OpenWeatherMap
- [GETTING_STARTED.md](docs/GETTING_STARTED.md) - Quick start guide
- [CAMERA_SUPPORT.md](docs/CAMERA_SUPPORT.md) - Support caméra par plateforme
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Architecture de l'application
- [CHANGELOG.md](CHANGELOG.md) - Historique des changements

---

## 🔧 Configuration avancée

### Feature Flags
Voir [`lib/config/app_config.dart`](lib/config/app_config.dart) :
```dart
static const bool enableAIFeatures = true;
static const bool enableWeatherIntegration = true;
static const bool enableAgendaSync = true;
static const bool enableOutfitSuggestions = true;
```

### Mode développement vs production
```dart
static const bool isDevelopment = true;  // true = dev, false = prod
static const bool enableDebugLogging = true;
```

### Délais et timeouts
```dart
static const Duration networkTimeout = Duration(seconds: 30);
static const Duration cacheExpiry = Duration(hours: 24);
```

---

## 🧪 Tests & Validation

### Vérifier la compilation
```bash
flutter analyze          # Lint & errors
flutter doctor          # Diagnostics plateforme
flutter pub get         # Dépendances
```

### Lancer les tests
```bash
flutter test            # Tests unitaires
flutter test --coverage # Coverage report
```

---

## 🐛 Troubleshooting

### "Permission denied" sur Android
**Solution** :
```bash
flutter clean
flutter pub get
flutter run
# Accepter les permissions au premier lancement
```

### Erreur "Camera not initialized"
**Solution** :
- Attendre 5 sec pour que la caméra se verrouille
- Vérifier permissions dans paramètres
- Relancer l'app

### Météo affiche "Non disponible"
**Solution** :
- Vérifier la clé API dans `weather_service.dart`
- Vérifier la connexion internet
- Voir [WEATHER_SETUP.md](docs/WEATHER_SETUP.md) troubleshooting

### "Agenda non disponible"
**Solution** :
- Verifier `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `.env`
- Executer le SQL de [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)
- Verifier que l'utilisateur est bien connecte

---

## 📈 Prochaines étapes

### Court terme (Phase 1)
- [ ] Tests unitaires & intégration
- [ ] Optimisation performance caméra
- [ ] Caching offline pour météo

### Moyen terme (Phase 2)
- [ ] Widget system (horloge, météo, agenda modulaires)
- [ ] Support multi-écransNon native
- [ ] Intégration Spotify/Deezer
- [ ] Anti-vol reconnaissance faciale

### Long terme (Phase 3)
- [ ] Intelligence artificielle améliorée
- [ ] Intégration maison intelligente (MQTT/IoT)
- [ ] App Cloud synchronisation
- [ ] Version web full-featured

---

## 👥 Contribution

Les contributions sont bienvenues ! 

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit changements (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

---

## 📄 Licence

MIT License - voir [LICENSE](LICENSE) pour détails

---

## 📞 Support

- **Issues** : [GitHub Issues](https://github.com/josoavj/magicmirror/issues)
- **Discussions** : [GitHub Discussions](https://github.com/josoavj/magicmirror/discussions)
- **Email** : support@magicmirror.app

---

**Made with ❤️ by [@josoavj](https://github.com/josoavj)**

---

### Quick Links
- 🌐 [GitHub Repository](https://github.com/josoavj/magicmirror)
- 📖 [Flutter Documentation](https://flutter.dev)
- 🤖 [Google ML Kit](https://developers.google.com/ml-kit)
- 📡 [OpenWeatherMap API](https://openweathermap.org/api)
- 🗄️ [Supabase Docs](https://supabase.com/docs)
