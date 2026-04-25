# Configuration météo — OpenWeatherMap API

Intégration de l'API OpenWeatherMap dans Magic Mirror avec géolocalisation automatique et gestion sécurisée des clés.

---

## Fonctionnalités

| Fonctionnalité | Statut |
|----------------|--------|
| Géolocalisation automatique | ✅ |
| Données météo en temps réel | ✅ |
| Température, humidité, vent, description | ✅ |
| Icônes officielles OpenWeatherMap | ✅ |
| Fallback sur Paris si localisation échoue | ✅ |
| Prévisions 5 jours (optionnel) | ✅ |
| Clé API sécurisée via `flutter_dotenv` | ✅ |

---

## Configuration rapide

### Étape 1 — Créer un compte OpenWeatherMap

1. Aller sur [https://openweathermap.org/api](https://openweathermap.org/api)
2. Cliquer sur **Sign Up** en haut à droite
3. Remplir le formulaire (email valide, mot de passe 8+ caractères, username unique)
4. Accepter les conditions, puis cliquer sur **Create**
5. Confirmer l'email reçu en cliquant sur le lien de confirmation

### Étape 2 — Obtenir la clé API

1. Se connecter, puis aller sur [https://home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys)
2. Copier la clé nommée **Default** :

```
abc123def456ghi789jkl0mnopqrst
```

> **Note :** La clé peut prendre 5 à 10 minutes pour être activée après la création du compte.

### Étape 3 — Configurer `.env`

À la racine du projet, ouvrir le fichier `.env` et remplacer :

```env
# Avant
OPENWEATHERMAP_API_KEY=demo

# Après (coller la vraie clé)
OPENWEATHERMAP_API_KEY=your_actual_api_key_here_1234567890ab
```

> Vérifier qu'il n'y a **pas d'espace** avant ou après la clé.

### Étape 4 — Vérifier la clé en navigateur

Avant de relancer l'app, tester la clé directement (remplacer `YOUR_KEY`) :

```
https://api.openweathermap.org/data/2.5/weather?q=Paris&units=metric&appid=YOUR_KEY
```

Réponse attendue si la clé est valide :

```json
{
  "coord": { "lon": 2.3488, "lat": 48.8534 },
  "weather": [{ "id": 801, "main": "Clouds" }],
  "main": { "temp": 18.45, "feels_like": 17.0 },
  "name": "Paris"
}
```

Réponse en cas d'erreur :

```json
{ "cod": "401", "message": "Invalid API key" }
```

### Étape 5 — Relancer l'app

```bash
# Arrêter l'app (Ctrl+C), puis :
flutter clean
flutter run
```

Une fois lancée, l'écran d'accueil doit afficher les données météo en haut à droite.

---

## Dépendances

```yaml
geolocator: ^12.0.0       # Géolocalisation
dio: ^5.3.1               # Appels HTTP
intl: ^0.20.2             # Formatage dates
flutter_riverpod: ^3.2.1  # State management
flutter_dotenv: ^5.0.2    # Gestion des variables d'environnement
```

---

## Architecture

### Services

**`WeatherService`** — `lib/features/weather/data/services/weather_service.dart`

Gère les appels API, la géolocalisation et les fallbacks.

```dart
// Météo actuelle (géolocalisation automatique)
Future<WeatherResponse?> getCurrentWeather()

// Météo par coordonnées
Future<WeatherResponse?> getCurrentWeatherByCoordinates(double lat, double lon)

// Météo par nom de ville
Future<WeatherResponse?> getWeatherByCity(String cityName)

// Prévisions 5 jours
Future<ForecastResponse?> getForecast(double lat, double lon)
```

### Modèles

**`WeatherResponse`** — données météo actuelles :

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

**`ForecastResponse`** — prévisions futures :

```dart
ForecastResponse(
  city: 'Paris',
  forecasts: [
    ForecastItem(...), // heure par heure
    // ...
  ],
)
```

### Provider Riverpod

```dart
final currentWeatherProvider = FutureProvider<WeatherResponse?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return await service.getCurrentWeather();
});
```

---

## Utilisation dans le code

### Afficher la météo dans un widget

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
            Text('${weather.temperature}°C'),
            Text('Humidité: ${weather.humidity}%'),
            Text('Vent: ${weather.windSpeed} m/s'),
            Text(weather.cityName),
          ],
        );
      },
      loading: () => Text('Chargement météo...'),
      error: (err, st) => Text('Erreur: $err'),
    );
  }
}
```

### Météo par ville

```dart
final service = WeatherService();
final paris = await service.getWeatherByCity('Paris');
final london = await service.getWeatherByCity('London');
```

### Prévisions 5 jours

```dart
final service = WeatherService();
final forecast = await service.getForecast(48.8566, 2.3522);

final next24h = forecast?.getNext24Hours() ?? [];
final daily = forecast?.getDaily() ?? [];
```

### Debug — afficher les premières lettres de la clé API

```dart
static String get _apiKey {
  final key = dotenv.env['OPENWEATHERMAP_API_KEY'] ?? 'demo';
  debugPrint('API Key: ${key.substring(0, 5)}...');
  return key;
}
```

---

## Sécurité — gestion de la clé API

La clé API n'est jamais exposée dans le code source.

| Fichier | Contenu | Commité sur Git | Accès |
|--------|---------|-----------------|-------|
| `.env` | Vraie clé | ❌ Non (gitignore) | Local uniquement |
| `.env.example` | Template sans clé | ✅ Oui | Public |
| `weather_service.dart` | Lit depuis dotenv | ✅ Oui | Pas de clé en dur |
| `main.dart` | Charge `.env` | ✅ Oui | Pas sensible |

Vérifier que le fichier `.env` est bien ignoré par Git :

```bash
git check-ignore .env   # Doit retourner ".env"
git status              # Ne doit PAS afficher .env
```

### Utilisation selon l'environnement

```env
# .env — développement local
OPENWEATHERMAP_API_KEY=ma_vraie_cle_secrete_1234
```

```bash
# Production — variable système
export OPENWEATHERMAP_API_KEY=production_key_5678
flutter run
```

---

## Plan gratuit OpenWeatherMap

| Limite | Valeur |
|--------|--------|
| Appels par minute | 60 |
| Appels par mois | 1 000 000 |
| Météo actuelle | ✅ |
| Prévisions 5 jours | ✅ |
| Historique | ❌ |
| Coût | 0 $/mois |

---

## Permissions requises

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Accès à la position pour afficher la météo locale</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Accès permanent à la position</string>
```

---

## Comportement en cas d'erreur

| Situation | Comportement |
|-----------|--------------|
| Géolocalisation refusée | Fallback sur Paris (48.8566, 2.3522) |
| API indisponible | Retry après 2s, puis widget "Non disponible" |
| Pas de connexion internet | Affichage des emojis météo en fallback |
| Permission GPS refusée | Fallback Paris, l'app ne se bloque pas |

---

## Troubleshooting

### "Météo non disponible" dans l'app

1. Vérifier le contenu du fichier `.env` :
   ```bash
   cat .env
   # Doit afficher : OPENWEATHERMAP_API_KEY=votre_vraie_cle
   ```
2. S'assurer qu'il n'y a pas d'espace avant ou après la clé
3. Attendre 5 à 10 minutes si le compte vient d'être créé
4. Tester la clé directement dans le navigateur (voir étape 4)
5. Relancer avec `flutter clean && flutter run`

### Erreur 401 — "Invalid API key"

- La clé a été copiée incomplètement → revérifier sur [home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys)
- La clé n'est pas encore activée → attendre 5 à 10 minutes

### Erreur 429 — rate limit dépassé

Le plan gratuit est limité à 60 appels/minute. Attendre quelques minutes avant de relancer.

### "Permission denied" — géolocalisation

L'app bascule automatiquement sur Paris. Aucune erreur bloquante.

### Les icônes météo ne s'affichent pas

Vérifier la connexion internet. L'app utilise des emojis (☀️ ☁️ 🌧️) en fallback automatique.

### Déboguer avec les logs détaillés

```bash
flutter run -v
# Chercher les lignes contenant "weather" ou "API"
```

---

## Checklist de mise en route

- [ ] Compte OpenWeatherMap créé
- [ ] Email confirmé
- [ ] Clé API copiée depuis le dashboard
- [ ] Clé testée dans le navigateur
- [ ] `.env` configuré avec la vraie clé
- [ ] `flutter clean` exécuté
- [ ] `flutter run` lancé
- [ ] Météo affichée dans l'app
- [ ] Aucun message d'erreur dans la console

---

## Prochains développements

- [ ] Cache local avec `sqflite`
- [ ] Écran dédié aux prévisions 5 jours
- [ ] Notifications d'alerte météo
- [ ] Suggestions de tenue selon les conditions

---

## Références

| Ressource | Lien |
|-----------|------|
| API OpenWeatherMap | [openweathermap.org/api](https://openweathermap.org/api) |
| Dashboard clés API | [home.openweathermap.org/api_keys](https://home.openweathermap.org/api_keys) |
| Tarifs | [openweathermap.org/price](https://openweathermap.org/price) |
| flutter_dotenv | [pub.dev/packages/flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| geolocator | [pub.dev/packages/geolocator](https://pub.dev/packages/geolocator) |
| dio | [pub.dev/packages/dio](https://pub.dev/packages/dio) |
| Issues GitHub | [github.com/josoavj/magicmirror/issues](https://github.com/josoavj/magicmirror/issues) |