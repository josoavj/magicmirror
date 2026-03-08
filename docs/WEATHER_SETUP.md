# 🌦️ Configuration Météo - OpenWeatherMap API

## Vue d'ensemble

L'app Magic Mirror est **100% fonctionnelle avec une météo réelle** grâce à l'intégration sécurisée de l'API OpenWeatherMap.

### Fonctionnalités météo intégrées:
- ✅ **Géolocalisation automatique** avec geolocator
- ✅ **Données météo en temps réel** depuis OpenWeatherMap
- ✅ **Affichage détaillé**: température, humidité, vent, description
- ✅ **Icônes météo** officielles OpenWeatherMap
- ✅ **Fallback intelligent** sur Paris si la localisation échoue
- ✅ **Prévisions** 5 jours supportées (optionnel)
- ✅ **Clé API sécurisée** avec flutter_dotenv (jamais exposée)

---

## 🚀 Configuration rapide (5 min)

### Étape 1️⃣: Créer un compte OpenWeatherMap

1. Ouvrir: **https://openweathermap.org/api**
2. En haut à droite, cliquer sur **"Sign Up"**
3. Remplir le formulaire:
   - **Email** (valide)
   - **Mot de passe** (8+ caractères)
   - **Username** (unique)
4. Cocher les conditions → **"Create"**

✅ Email de confirmation envoyé

---

### Étape 2️⃣: Vérifier ton email

1. Ouvrir ton email
2. Cliquer sur le lien de confirmation
3. Tu es automatiquement redirigé vers OpenWeatherMap

✅ Compte activé!

---

### Étape 3️⃣: Obtenir ta clé API

Après connexion, aller à: **https://home.openweathermap.org/api_keys**

Tu verras une clé par défaut nommée **"Default"**:
```
abc123def456ghi789jkl0mnopqrst
```

**Cliquer sur la clé pour la copier** → Tu l'as en presse-papiers!

---

### Étape 4️⃣: Configurer `.env`

1. À la racine du projet (`/home/username/Projets/magicmirror/`), ouvrir le fichier **`.env`**

2. Remplacer la ligne:
```env
OPENWEATHERMAP_API_KEY=demo
```

Par (colle ta clé):
```env
OPENWEATHERMAP_API_KEY=your_actual_api_key_here_1234567890ab
```

3. **Sauvegarde** (Ctrl+S)

✅ Clé configurée!

---

### Étape 5️⃣: Nettoyer et relancer

```bash
# Arrêter l'app (Ctrl+C dans le terminal)

# Nettoyer les fichiers en cache
flutter clean

# Relancer l'app
flutter run
```

✅ Météo affichée!

---

## ✅ Vérifier que ça marche

Une fois l'app lancée:

1. Aller sur l'écran **"Miroir"** ou **"Accueil"**
2. Tu devrais voir en haut à droite:
   ```
   🌡️ 18°C
   Nuageux
   Paris, FR
   ```

**Tu vois les données météo?** → ✅ Succès!

---

## 🧪 Tester ta clé API manuellement

Pour vérifier que ta clé est correcte AVANT de configurer l'app:

1. Ouvrir dans le navigateur (remplace `YOUR_KEY` par ta clé):
```
https://api.openweathermap.org/data/2.5/weather?q=Paris&units=metric&appid=YOUR_KEY
```

**Si succès**, tu verras:
```json
{
  "coord": {"lon": 2.3488, "lat": 48.8534},
  "weather": [{"id": 801, "main": "Clouds", ...}],
  "main": {"temp": 18.45, "feels_like": 17.0, ...},
  "name": "Paris"
}
```

**Si erreur 401**:
```json
{"cod": "401", "message": "Invalid API key"}
```
→ Vérifier que tu as bien copié la **TOUTE** la clé (pas d'espaces avant/après)

---

## ⚠️ Troubleshooting

### **"Météo non disponible" dans l'app**

**Cause 1: Clé API incorrecte ou non chargée**
- ✅ Vérifier le fichier `.env`:
  ```bash
  cat .env
  ```
  Doit afficher:
  ```
  OPENWEATHERMAP_API_KEY=votre_vraie_cle
  ```
- ✅ Vérifier qu'il y a **pas d'espaces** avant/après la clé
- ✅ `flutter clean` + `flutter run`

**Cause 2: Problème de synchronisation du compte**
- ✅ Attendre 5-10 min après création du compte
- ✅ Tester la clé dans le navigateur (voir section "Tester ta clé API")

**Cause 3: Pas de connexion internet**
- ✅ Vérifier que l'appareil a internet
- ✅ Vérifier permissions internet sur Android/iOS

**Cause 4: Rate limit dépassé**
- ✅ OpenWeatherMap gratuit = 60 appels/minute
- ✅ Si erreur "429", attendre quelques minutes

---

### **"Permission denied" localization**

L'app va automatiquement:
1. Demander la permission de géolocalisation
2. Si refusée → utilise **Paris** par défaut
3. Affiche la météo de Paris

✅ Pas d'erreur, juste une localisation par défaut

---

### **La clé API fuite sur GitHub? 🚨**

**NON, c'est sécurisé!** Voici pourquoi:

- ✅ Le fichier **`.env`** est dans **`.gitignore`**
- ✅ Ton fichier `.env` local ne sera **jamais** committé
- ✅ Seul **`.env.example`** est sur GitHub (sans vraie clé)

Vérifier:
```bash
# Ceci affiche "EXCLUDED"? → OK!
git check-ignore .env

# Ceci ne devrait PAS afficher .env
git status
```

---

## 🔐 Architecture de sécurité

### Fichiers importants:

| Fichier | Contenu | Commité? | Sécurité |
|---------|---------|----------|----------|
| **`.env.example`** | Template (demo key) | ✅ OUI | Public |
| **`.env`** | Vraie clé | ❌ NON | Private (gitignore) |
| **`main.dart`** | Charge `.env` | ✅ OUI | Pas sensible |
| **`weather_service.dart`** | Lit depuis dotenv | ✅ OUI | Pas hardcoded |

### Comment ça marche?

1. **Au développement** (localement):
   ```env
   # Dans .env (local)
   OPENWEATHERMAP_API_KEY=ma_vraie_cle_secrète_1234
   ```
   → App charge la vraie clé ✅

2. **Sur GitHub** (public):
   ```env
   # Dans .env.example (template)
   OPENWEATHERMAP_API_KEY=your_api_key_here
   ```
   → Template pour les autres ✅

3. **En production** (serveur/CI):
   ```bash
   # Variable d'environnement du système
   export OPENWEATHERMAP_API_KEY=production_key_5678
   flutter run
   ```
   → App charge depuis l'env système ✅

---

## 📊 Limites du plan GRATUIT

| Limite | Valeur | Suffisant? |
|--------|--------|-----------|
| **Appels/minute** | 60 | ✅ Oui |
| **Appels/mois** | 1,000,000 | ✅ Oui |
| **Données actuelles** | ✅ | ✅ Oui |
| **Prévisions 5 jours** | ✅ | ✅ Oui |
| **Historique** | ❌ Non | N/A |
| **Coût** | $0/mois | ✅ Gratuit! |

**Conclusion:** Le plan gratuit est **plus que suffisant** pour une app personnelle! 🎉

---

## 🛠️ Développement avancé

### Voir les logs de chargement

Pour déboguer si la clé se charge correctement:

Ajouter dans `lib/features/weather/data/services/weather_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  static String get _apiKey {
    final key = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? 'demo';
    debugPrint('🔑 API Key: ${key.substring(0, 5)}...'); // Debug log
    return key;
  }
  // ...
}
```

Au lancement, tu verras dans la console:
```
🔑 API Key: a1b2c...
```

✅ Clé correctement chargée!

---

### Utiliser dans un autre widget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/weather/presentation/widgets/weather_widget.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    
    return weatherAsync.when(
      data: (weather) {
        if (weather == null) return Text('Météo indisponible');
        
        return Column(
          children: [
            Text('🌡️ ${weather.temperature}°C'),
            Text('💧 Humidité: ${weather.humidity}%'),
            Text('💨 Vent: ${weather.windSpeed} m/s'),
            Text('📍 ${weather.cityName}'),
          ],
        );
      },
      loading: () => Text('Chargement météo...'),
      error: (err, st) => Text('Erreur météo: $err'),
    );
  }
}
```

---

### Obtenir la météo d'une ville spécifique

```dart
import '../features/weather/data/services/weather_service.dart';

class MyClass {
  final service = WeatherService();

  Future<void> getWeatherByCity() async {
    final paris = await service.getWeatherByCity('Paris');
    print('Paris: ${paris?.temperature}°C');
    
    final london = await service.getWeatherByCity('London');
    print('London: ${london?.temperature}°C');
  }
}
```

---

### Obtenir les prévisions 5 jours

```dart
Future<void> getForecastData() async {
  final service = WeatherService();
  
  // Prévisions des 5 prochains jours
  final forecast = await service.getForecast(48.8566, 2.3522);
  
  if (forecast != null) {
    // Prévisions pour les 24 prochaines heures
    final next24h = forecast.getNext24Hours();
    print('24h: ${next24h.length} prévisions');
    
    // Données quotidiennes
    final daily = forecast.getDaily();
    print('5J: ${daily.length} jours');
  }
}
```

---

## 📚 Documentation additionnelle

### OpenWeatherMap
- [📖 API Reference](https://openweathermap.org/api)
- [🗺️ List des villes](https://openweathermap.org/find)
- [💰 Pricing](https://openweathermap.org/price)
- [🐛 Support](https://openweathermap.org/faq)

### Flutter & Dépendances
- [🎯 flutter_dotenv](https://pub.dev/packages/flutter_dotenv)
- [🗺️ geolocator](https://pub.dev/packages/geolocator)
- [📡 dio](https://pub.dev/packages/dio)

---

## ❓ Questions fréquentes

**Q: Je dois partager ma clé API?**
A: Non! Garde ta clé secrète. Elle est dans `.env` (gitignore) donc jamais exposée.

**Q: Ça coûte cher?**
A: Gratuit! Le plan gratuit = 1M appels/mois (plus que suffisant).

**Q: Comment changer de ville?**
A: L'app utilise la géolocalisation auto, ou fallback Paris. À personnaliser dans `weather_service.dart`.

**Q: Ça marche offline?**
A: Non, besoin d'internet. Mais le cache garde les données 5 min.

**Q: Je peux utiliser une autre API météo?**
A: Oui, remplacer dans `weather_service.dart`. Même pattern pour flutter_dotenv.

---

## 📋 Checklist finale

Avant de considérer que c'est fini:

- [ ] Compte OpenWeatherMap créé
- [ ] Email vérifié
- [ ] Clé API obtenue
- [ ] Clé testée dans le navigateur
- [ ] `.env` configuré avec la clé
- [ ] `.env` sauvegardé
- [ ] `flutter clean` exécuté
- [ ] `flutter run` lancé
- [ ] Météo s'affiche dans l'app
- [ ] Pas de message d'erreur

✅ **Si tout est coché → Tu es prêt!** 🎉

---

## 🆘 Besoin d'aide?

Si tu es bloqué:

1. **Vérifier les logs**:
   ```bash
   flutter run -v
   ```
   Chercher les erreurs liées à "weather" ou "API"

2. **Consulter le troubleshooting** ci-dessus

3. **Tester la clé API** en navigateur (voir section "Tester ta clé API manuellement")

4. **Ouvrir une issue**: https://github.com/josoavj/magicmirror/issues

---

**Made with ❤️ for Magic Mirror**

---

## Permissions requises

L'app demande automatiquement les permissions suivantes :

### Android
- `android.permission.INTERNET` - Pour les appels API
- `android.permission.ACCESS_FINE_LOCATION` - Pour la géolocalisation
- `android.permission.ACCESS_COARSE_LOCATION` - Alternative si fine n'est pas disponible

**Fichier** : [`android/app/src/main/AndroidManifest.xml`](../../../android/app/src/main/AndroidManifest.xml)

### iOS
- `NSLocationWhenInUseUsageDescription` - Pour accéder à la position
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Pour accès toujours

**Fichier** : [`ios/Runner/Info.plist`](../../../ios/Runner/Info.plist)

---

## Architecture

### Services

**`WeatherService`** - [`lib/features/weather/data/services/weather_service.dart`](lib/features/weather/data/services/weather_service.dart)
- Gère les appels API OpenWeatherMap
- Gère la géolocalisation via Geolocator
- Fournit des fallbacks intelligents

**Méthodes publiques** :
```dart
// Récupérer la météo actuelle (avec géolocalisation auto)
Future<WeatherResponse?> getCurrentWeather()

// Météo par coordonnées spécifiques
Future<WeatherResponse?> getCurrentWeatherByCoordinates(double lat, double lon)

// Météo par nom de ville
Future<WeatherResponse?> getWeatherByCity(String cityName)

// Prévisions 5 jours
Future<ForecastResponse?> getForecast(double lat, double lon)
```

### Modèles

**`WeatherResponse`** - Données météo actuelles
```dart
WeatherResponse(
  cityName: 'Paris',
  temperature: 18.5,
  feelsLike: 17.0,
  humidity: 65,
  windSpeed: 12.0,
  description: 'Nuageux',
  main: 'Clouds',
  icon: '04d',
  pressure: 1013,
  visibility: 10.0,
)
```

**`ForecastResponse`** - Prévisions futurs
```dart
ForecastResponse(
  city: 'Paris',
  forecasts: [
    ForecastItem(...), // Heure par heure
    ForecastItem(...),
    // ...
  ],
)
```

### Provider Riverpod

**`currentWeatherProvider`** - [`lib/features/weather/presentation/widgets/weather_widget.dart`](lib/features/weather/presentation/widgets/weather_widget.dart)

```dart
final currentWeatherProvider = FutureProvider<WeatherResponse?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return await service.getCurrentWeather();
});
```

### Widget

**`WeatherWidget`** - Affichage optimisé avec :
- ✅ Animation de chargement
- ✅ Gestion d'erreur gracieuse
- ✅ Emojis météo correspondant aux conditions
- ✅ Affichage des détails (température ressentie, humidité, vent)
- ✅ Icônes officielles OpenWeatherMap

---

## Exemples d'utilisation

### Utiliser dans un autre widget

```dart
import '../features/weather/presentation/widgets/weather_widget.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    
    return weatherAsync.when(
      data: (weather) {
        if (weather == null) return Text('Météo indisponible');
        
        return Text('Température: ${weather.temperature}°C');
      },
      loading: () => Text('Chargement...'),
      error: (err, st) => Text('Erreur: $err'),
    );
  }
}
```

### Obtenir la météo d'une ville spécifique

```dart
final weatherService = WeatherService();
final parisWeather = await weatherService.getWeatherByCity('Paris');
final marseilleWeather = await weatherService.getWeatherByCity('Marseille');
```

### Obtenir les prévisions

```dart
final weatherService = WeatherService();
final forecast = await weatherService.getForecast(48.8566, 2.3522);
final next24h = forecast?.getNext24Hours() ?? [];
final nextDays = forecast?.getDaily() ?? [];
```

---

## Comportement en cas d'erreur

### Si la géolocalisation échoue
- Utilise **Paris (48.8566, 2.3522)** par défaut ✅
- Affiche un message "Localisation refusée" dans les logs 📝

### Si l'API OpenWeatherMap est indisponible
- Récupère 2s et affiche un widget "Non disponible" ⏱️
- Fallback sur données simulées pour développement 🔄

### Si la permission de localisation est refusée
- Utilise toujours le fallback Paris 🗺️
- Ne bloque jamais l'app 🚫❌

---

## Plan OpenWeatherMap

### Plan Gratuit (inclus)
- ✅ Météo actuelle (5 min de mise en cache)
- ✅ Prévisions 5 jours (3h d'intervalle)
- ✅ Appels illimités
- ✅ 60 appels/minute

### Pour passer au plan payant
Visiter : https://openweathermap.org/price

---

## Variables d'environnement (optionnel)

Pour éviter de committer la clé API, utiliser des fichiers `.env` :

1. Ajouter `flutter_dotenv: ^5.0.2` aux dépendances
2. Créer `.env` (à la racine) :
   ```
   OPENWEATHERMAP_API_KEY=votre_cle_ici
   ```
3. Charger dans `main.dart` :
   ```dart
   await dotenv.load(fileName: ".env");
   ```
4. Utiliser en service :
   ```dart
   static const String _apiKey = String.fromEnvironment('OPENWEATHERMAP_API_KEY');
   ```

---

## Dépendances ajoutées

```yaml
# Géolocalisation
geolocator: ^12.0.0

# Déjà présentes
dio: ^5.3.1        # Appels HTTP
intl: ^0.20.2      # Formatage dates/heures
flutter_riverpod: ^3.2.1  # State management
```

---

## Prochains développements possibles

- [ ] Cache local de la météo avec `sqflite`
- [ ] Partage d'écran avec prévisions 5 jours
- [ ] Notifications d'alerte météo
- [ ] Suggestions de tenue basées surles conditions météo actuelles

---

## Troubleshooting

### Erreur : "Impossible de récupérer la position"
**Cause** : Permission refusée ou pas de GPS
**Solution** : 
- ✅ Vérifier permissions dans les paramètres du téléphone
- ✅ Attendre 5-10s pour que le GPS se verrouille
- ✅ L'app utilise un fallback sur Paris automatiquement

### Les icônes météo ne s'affichent pas
**Cause** : Pas de connexion internet
**Solution** :
- ✅ Vérifier la connexion WiFi/4G
- ✅ L'app utilise des emojis comme fallback
- ✅ Les emojis s'affichent toujours (☀️ ☁️ 🌧️ etc)

### Erreur "API key not valid"
**Cause** : Clé API incorrecte
**Solution** :
- ✅ Vérifier la clé dans [`weather_service.dart`](lib/features/weather/data/services/weather_service.dart)
- ✅ Attendre 5 min après création de la clé
- ✅ Vérifier que la clé n'est pas expirée

---

## Support

- **Docs OpenWeatherMap** : https://openweathermap.org/api/current-weather-api
- **Docs Geolocator** : https://pub.dev/packages/geolocator
- **Docs Dio** : https://pub.dev/packages/dio

---

**✨ Félicitations ! La météo est maintenant pleinement intégrée ! ✨**
