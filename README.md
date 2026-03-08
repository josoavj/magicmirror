# 🪞 Magic Mirror - App Flutter Complète

---

## 📊 Vue d'ensemble des fonctionnalités

| Fonctionnalité | Status | Détails |
|---|---|---|
| 🪞 **Miroir Caméra** | ✅ 100% | Caméra temps réel, détection morphologie, affichage full-screen |
| 📅 **Agenda/Calendrier** | ✅ 100% | Sync Google Calendar (prod) ou données mockées (dev) |
| 🌦️ **Météo** | ✅ 100% | OpenWeatherMap API réelle + géolocalisation automatique |
| 🤖 **Morphologie AI** | ✅ 100% | Google ML Kit pose detection + classification corps |
| 👔 **Suggestions tenues** | ✅ 100% | Fitrée par morphologie + TTS français intégrée |
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

#### 2️⃣ **Google Calendar (optionnel, pour prod)**
Suivre : [SETUP.md](SETUP.md)
- Configuration OAuth2 Google
- OU utiliser les données mockées (développement)

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # Point d'entrée
├── config/
│   ├── app_config.dart                # Feature flags & configuration
│   └── di_setup.dart                  # Dependency injection
├── core/
│   ├── services/
│   │   ├── connectivity_service.dart
│   │   ├── storage_service.dart
│   │   └── tts_service.dart
│   ├── theme/
│   ├── utils/
│   └── constants/
├── data/
│   ├── datasources/
│   ├── models/
│   ├── repositories/
│   └── services/
│       ├── google_calendar_service.dart
│       ├── mock_calendar_service.dart
│       └── ...
├── features/
│   ├── mirror/                        # Écran miroir principal
│   │   ├── presentation/
│   │   │   ├── screens/mirror_screen.dart
│   │   │   ├── providers/camera_provider.dart
│   │   │   └── widgets/
│   │   └── ...
│   ├── agenda/                        # Gestion calendrier
│   │   ├── presentation/
│   │   │   ├── screens/agenda_screen.dart
│   │   │   ├── providers/agenda_provider.dart
│   │   │   └── widgets/
│   │   └── ...
│   ├── weather/                       # Intégration météo
│   │   ├── data/
│   │   │   ├── services/weather_service.dart
│   │   │   └── models/weather_model.dart
│   │   └── presentation/
│   │       └── widgets/weather_widget.dart
│   ├── ai_ml/                         # Morphologie & ML
│   │   ├── data/
│   │   │   ├── services/morphology_service.dart
│   │   │   └── models/morphology_model.dart
│   │   ├── presentation/
│   │   └── providers/ml_provider.dart
│   └── outfit_suggestion/             # Suggestions tenues
│       ├── data/
│       │   └── models/outfit_model.dart
│       ├── presentation/
│       │   ├── providers/outfit_provider.dart
│       │   └── widgets/outfit_recommendation_widget.dart
│       └── ...
├── presentation/                      # Widgets globaux
│   ├── pages/
│   ├── screens/
│   ├── widgets/
│   │   └── glass_container.dart
│   └── providers/
├── routes/
│   ├── app_routes.dart
│   └── route_names.dart
└── generated/
    └── assets.gen.dart
```

---

## 🔐 Dépendances principales

### State Management
- `flutter_riverpod: ^3.2.1` - Gestion d'état réactive

### Configuration & Secrets
- `flutter_dotenv: ^5.1.0` - Gestion variables d'environnement sécurisée

### Services & API
- `googleapis: ^16.0.0` - Google Calendar API
- `googleapis_auth: ^2.0.0` - Authentification API
- `google_sign_in: ^7.2.0` - Connexion Google
- `dio: ^5.3.1` - Client HTTP
- `geolocator: ^12.0.0` - Géolocalisation GPS

### Caméra & Média
- `camera: ^0.12.0` - Accès caméra
- `camera_linux: ^0.0.8` - Support Linux
- `image: ^4.1.3` - Traitement images
- `google_ml_kit: ^0.21.0` - ML Kit pour pose detection

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

*Voir [CAMERA_SUPPORT.md](CAMERA_SUPPORT.md) pour détails platform-spécifiques*

---

## 📚 Documentation

- [SETUP.md](SETUP.md) - Configuration complète production
- [WEATHER_SETUP.md](WEATHER_SETUP.md) - Configuration météo OpenWeatherMap
- [GETTING_STARTED.md](GETTING_STARTED.md) - Quick start guide
- [CAMERA_SUPPORT.md](CAMERA_SUPPORT.md) - Support caméra par plateforme
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture de l'application
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
static const bool useMockCalendar = true; // false = production
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
- Voir [WEATHER_SETUP.md](WEATHER_SETUP.md) troubleshooting

### "Google Sign-In not available"
**Solution** :
- Configure les dépendances OAuth2 (voir [SETUP.md](SETUP.md))
- Ou utiliser `useMockCalendar = true` pour développement

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
- 🔐 [Google Calendar API](https://developers.google.com/calendar)
