import 'package:intl/intl.dart';

/// Modèle pour les données météo locales (legacy)
class WeatherData {
  final String condition; // Ensoleillé, Nuageux, Pluvieux, etc.
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final DateTime timestamp;

  WeatherData({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.timestamp,
  });
}

/// Modèle pour la réponse météo actuelle d'OpenWeatherMap
class WeatherResponse {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String main;
  final String icon;
  final int pressure;
  final double visibility;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? observedAt;
  final bool isFallback;

  WeatherResponse({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.main,
    required this.icon,
    required this.pressure,
    required this.visibility,
    this.sunrise,
    this.sunset,
    this.observedAt,
    this.isFallback = false,
  });

  /// Créer à partir du JSON d'OpenWeatherMap
  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      cityName: json['name'] ?? 'Inconnue',
      temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']['feels_like'] as num?)?.toDouble() ?? 0.0,
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] ?? 'Inconnue',
      main: json['weather'][0]['main'] ?? 'Unknown',
      icon: json['weather'][0]['icon'] ?? '01d',
      pressure: json['main']['pressure'] ?? 0,
      visibility: ((json['visibility'] ?? 10000) / 1000).toDouble(),
      sunrise: json['sys']['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sys']['sunrise'] * 1000)
          : null,
      sunset: json['sys']['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sys']['sunset'] * 1000)
          : null,
      observedAt: json['dt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000)
          : DateTime.now(),
    );
  }

  /// Obtenir l'URL de l'icône météo
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@4x.png';

  /// Vérifier si c'est du mauvais temps
  bool get isBadWeather =>
      main.toLowerCase().contains('rain') ||
      main.toLowerCase().contains('thunderstorm') ||
      main.toLowerCase().contains('snow');

  /// Format pour l'affichage
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';

  /// Format heure lever/coucher
  String? get formattedSunrise =>
      sunrise != null ? DateFormat('HH:mm').format(sunrise!) : null;

  String? get formattedSunset =>
      sunset != null ? DateFormat('HH:mm').format(sunset!) : null;

  int? get minutesSinceObservation {
    if (observedAt == null) {
      return null;
    }
    return DateTime.now().difference(observedAt!).inMinutes;
  }
}

/// Modèle pour une prévision unique
class ForecastItem {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String main;
  final String icon;
  final double windSpeed;
  final int humidity;

  ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.main,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      dateTime: DateTime.parse(json['dt_txt']),
      temperature: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      description: json['weather'][0]['description'] ?? 'Inconnue',
      main: json['weather'][0]['main'] ?? 'Unknown',
      icon: json['weather'][0]['icon'] ?? '01d',
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      humidity: json['main']['humidity'] ?? 0,
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get formattedTime => DateFormat('HH:mm').format(dateTime);

  String get formattedDate => DateFormat('E d MMM', 'fr_FR').format(dateTime);
}

/// Modèle pour la réponse prévisions d'OpenWeatherMap
class ForecastResponse {
  final String city;
  final List<ForecastItem> forecasts;

  ForecastResponse({required this.city, required this.forecasts});

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    final List<ForecastItem> forecasts = [];
    for (var item in json['list']) {
      forecasts.add(ForecastItem.fromJson(item));
    }

    return ForecastResponse(
      city: json['city']['name'] ?? 'Inconnue',
      forecasts: forecasts,
    );
  }

  /// Obtenir les 24h prochaines de prévisions
  List<ForecastItem> getNext24Hours() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    return forecasts
        .where((f) => f.dateTime.isAfter(now) && f.dateTime.isBefore(tomorrow))
        .toList();
  }

  /// Obtenir les 5 prochains jours (groupés par jour)
  List<ForecastItem> getDaily() {
    final dailyForecasts = <String, ForecastItem>{};
    for (var forecast in forecasts) {
      final dateKey =
          '${forecast.dateTime.year}-${forecast.dateTime.month}-${forecast.dateTime.day}';
      if (!dailyForecasts.containsKey(dateKey)) {
        dailyForecasts[dateKey] = forecast;
      }
    }
    return dailyForecasts.values.toList();
  }
}
