import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/cache_service.dart';
import 'package:magicmirror/core/utils/app_logger.dart';

// Weather Response Model
class WeatherResponse {
  final String city;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final double pressure;
  final double visibility;
  final String icon;
  final String description;

  WeatherResponse({
    required this.city,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.icon,
    required this.description,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      city: json['city'] as String? ?? 'Unknown',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 20.0,
      humidity: json['humidity'] as int? ?? 50,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 5.0,
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1013.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 10.0,
      icon: json['icon'] as String? ?? 'Clear',
      description: json['description'] as String? ?? 'Clear sky',
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'temperature': temperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'pressure': pressure,
    'visibility': visibility,
    'icon': icon,
    'description': description,
  };
}

// Mock weather service
class WeatherService {
  Future<WeatherResponse> getCurrentWeather() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    return WeatherResponse(
      city: 'Antananarivo',
      temperature: 22.5,
      humidity: 65,
      windSpeed: 8.5,
      pressure: 1013.0,
      visibility: 10.0,
      icon: 'Clear',
      description: 'Ciel clair et ensoleillé',
    );
  }
}

// Riverpod Provider
final weatherServiceProvider = Provider((ref) => WeatherService());

final currentWeatherProvider = FutureProvider<WeatherResponse>((ref) async {
  const cacheKey = 'weather_current';

  // Vérifier le cache d'abord
  final cached = cacheService.get<WeatherResponse>(cacheKey);
  if (cached != null) {
    logger.debug('Météo depuis cache', tag: 'WeatherProvider');
    return cached;
  }

  // Récupérer avec timeout
  final weatherService = ref.watch(weatherServiceProvider);
  try {
    final weather = await weatherService.getCurrentWeather().timeout(
      const Duration(seconds: 10),
    );

    // Mettre en cache pour 5 minutes
    cacheService.set(cacheKey, weather, ttl: const Duration(minutes: 5));
    return weather;
  } on TimeoutException catch (e) {
    logger.error('Météo API timeout', tag: 'WeatherProvider', error: e);
    // Retourner données par défaut
    return WeatherResponse(
      city: 'Antananarivo',
      temperature: 25.0,
      humidity: 70,
      windSpeed: 5.0,
      pressure: 1013.0,
      visibility: 10.0,
      icon: 'Unknown',
      description: 'Données indisponibles',
    );
  }
});
