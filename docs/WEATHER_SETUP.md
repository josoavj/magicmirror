# 🌦️ Configuration Météo - OpenWeatherMap API

## Vue d'ensemble

L'app Magic Mirror est maintenant **100% fonctionnelle avec une météo réelle** grâce à l'intégration de l'API OpenWeatherMap.

### Fonctionnalités météo intégrées :
- ✅ **Géolocalisation automatique** avec geolocator
- ✅ **Données météo en temps réel** depuis OpenWeatherMap
- ✅ **Affichage détaillé** : température, humidité, vent, description
- ✅ **Icônes météo** officielles OpenWeatherMap
- ✅ **Fallback intelligent** sur Paris si la localisation échoue
- ✅ **Prévisions** 5 jours supportées (optionnel)

---

## Configuration rapide (3 étapes)

### 1️⃣ Obtenir une clé API gratuite

1. Visiter : https://openweathermap.org/api
2. S'inscrire (gratuit)
3. Aller à "API keys" dans le dashboard
4. Copier la clé par défaut (ou créer une nouvelle)

### 2️⃣ Configurer la clé API

Remplacer dans [`lib/features/weather/data/services/weather_service.dart`](lib/features/weather/data/services/weather_service.dart) (ligne 6) :

```dart
static const String _apiKey = 'VOTRE_CLE_API'; // ⬅️ Remplacer par votre clé
```

**Exemple** :
```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

### 3️⃣ Tester

Lancer l'app et vérifier que la météo s'affiche dans le widget en haut à droite du miroir !

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
