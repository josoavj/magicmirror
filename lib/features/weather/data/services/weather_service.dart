import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey =
      'demo'; // ⚠️ À remplacer par vous clé OpenWeatherMap gratuite

  final Dio _dio = Dio();

  WeatherService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Obtenir les permissions de localisation
  Future<bool> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Erreur permission localisation: $e');
      return false;
    }
  }

  /// Obtenir la position actuelle
  Future<Position?> _getCurrentPosition() async {
    try {
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        debugPrint('Permission localisation refusée - Fallback Antananarivo');
        // Fallback sur Antananarivo, Madagascar par défaut
        return Position(
          latitude: -18.8792,
          longitude: 47.5079,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return position;
    } catch (e) {
      debugPrint('Erreur récupération position: $e - Fallback Antananarivo');
      // Fallback sur Antananarivo, Madagascar
      return Position(
        latitude: -18.8792,
        longitude: 47.5079,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  /// Obtenir la météo actuelle par latitude/longitude
  Future<WeatherResponse?> getCurrentWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🌡️ Récupération météo pour ($latitude, $longitude)...');

      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('Météo reçue: ${data['main']['temp']}°C');
        return WeatherResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint(' Erreur météo API: $e');
      return null;
    }
  }

  /// Obtenir la météo actuelle (avec géolocalisation automatique)
  Future<WeatherResponse?> getCurrentWeather() async {
    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      return await getCurrentWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('Erreur getCurrentWeather: $e');
      return null;
    }
  }

  /// Obtenir la météo d'une ville par nom
  Future<WeatherResponse?> getWeatherByCity(String cityName) async {
    try {
      debugPrint('🌡️ Récupération météo pour $cityName...');

      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint(' Météo reçue: ${data['main']['temp']}°C');
        return WeatherResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint(' Erreur météo ville API: $e');
      return null;
    }
  }

  /// Obtenir la prévision 5 jours
  Future<ForecastResponse?> getForecast(
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('🌡️ Récupération prévisions...');

      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('Prévisions reçues: ${data['list'].length} items');
        return ForecastResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur prévisions API: $e');
      return null;
    }
  }
}
