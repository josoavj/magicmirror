import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/core/services/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _cachePrefixCurrentCoord = 'weather.current.coord';
  static const String _cachePrefixCurrentCity = 'weather.current.city';
  static const String _cachePrefixForecastCoord = 'weather.forecast.coord';
  static const String _prefsCurrentCoordLastKey =
      'weather.cache.last.current.coord';
  static const String _prefsCurrentCityLastKey =
      'weather.cache.last.current.city';
  static const String _prefsForecastCoordLastKey =
      'weather.cache.last.forecast.coord';

  // Charger la clé API depuis .env
  static String get _apiKey => dotenv.env['OPENWEATHERMAP_API_KEY'] ?? 'demo';

  final Dio _dio = Dio();

  WeatherService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  String _coordBucket(double latitude, double longitude) {
    final precision = AppConfig.weatherCoordinatePrecision;
    final lat = latitude.toStringAsFixed(precision);
    final lon = longitude.toStringAsFixed(precision);
    return '$lat,$lon';
  }

  String _normalizeCity(String cityName) {
    return cityName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  String _buildCurrentCoordKey(double latitude, double longitude) {
    return '$_cachePrefixCurrentCoord.${_coordBucket(latitude, longitude)}';
  }

  String _buildCurrentCityKey(String cityName) {
    return '$_cachePrefixCurrentCity.${_normalizeCity(cityName)}';
  }

  String _buildForecastCoordKey(double latitude, double longitude) {
    return '$_cachePrefixForecastCoord.${_coordBucket(latitude, longitude)}';
  }

  Future<void> _invalidatePreviousKeyIfChanged({
    required String trackingKey,
    required String currentCacheKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(trackingKey);
    if (previous != null &&
        previous.isNotEmpty &&
        previous != currentCacheKey) {
      cacheService.invalidate(previous);
      await prefs.remove('${previous}.raw');
      await prefs.remove('${previous}.savedAtMs');
    }
    await prefs.setString(trackingKey, currentCacheKey);
  }

  bool _isFresh(int savedAtMs, Duration ttl) {
    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    final expiresAt = savedAt.add(ttl);
    return DateTime.now().isBefore(expiresAt);
  }

  Map<String, dynamic>? _asJsonMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  Future<void> _saveCachePayload({
    required String cacheKey,
    required Map<String, dynamic> payload,
    required Duration ttl,
  }) async {
    cacheService.set<Map<String, dynamic>>(cacheKey, payload, ttl: ttl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${cacheKey}.raw', jsonEncode(payload));
    await prefs.setInt(
      '${cacheKey}.savedAtMs',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<Map<String, dynamic>?> _readCachePayload(
    String cacheKey, {
    required Duration ttl,
    bool allowStaleFallback = false,
  }) async {
    final inMemory = cacheService.get<Map<String, dynamic>>(cacheKey);
    if (inMemory != null) {
      return inMemory;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${cacheKey}.raw');
    final savedAtMs = prefs.getInt('${cacheKey}.savedAtMs');
    if (raw == null || raw.isEmpty || savedAtMs == null) {
      return null;
    }

    final fresh = _isFresh(savedAtMs, ttl);
    final staleAllowed =
        allowStaleFallback &&
        _isFresh(savedAtMs, AppConfig.weatherStaleFallbackMaxAge);

    if (!fresh && !staleAllowed) {
      await prefs.remove('${cacheKey}.raw');
      await prefs.remove('${cacheKey}.savedAtMs');
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      final payload = _asJsonMap(decoded);
      if (payload == null) {
        return null;
      }

      if (fresh) {
        cacheService.set<Map<String, dynamic>>(cacheKey, payload, ttl: ttl);
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  WeatherResponse _withFallbackFlag(WeatherResponse value) {
    return WeatherResponse(
      cityName: value.cityName,
      temperature: value.temperature,
      feelsLike: value.feelsLike,
      humidity: value.humidity,
      windSpeed: value.windSpeed,
      description: value.description,
      main: value.main,
      icon: value.icon,
      pressure: value.pressure,
      visibility: value.visibility,
      sunrise: value.sunrise,
      sunset: value.sunset,
      observedAt: value.observedAt,
      isFallback: true,
    );
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
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
    final cacheKey = _buildCurrentCoordKey(latitude, longitude);
    await _invalidatePreviousKeyIfChanged(
      trackingKey: _prefsCurrentCoordLastKey,
      currentCacheKey: cacheKey,
    );

    final cached = await _readCachePayload(
      cacheKey,
      ttl: AppConfig.weatherCurrentCacheTtl,
    );
    if (cached != null) {
      return WeatherResponse.fromJson(cached);
    }

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
        final payload = _asJsonMap(data);
        if (payload == null) {
          return null;
        }

        await _saveCachePayload(
          cacheKey: cacheKey,
          payload: payload,
          ttl: AppConfig.weatherCurrentCacheTtl,
        );

        debugPrint('Météo reçue: ${payload['main']['temp']}°C');
        return WeatherResponse.fromJson(payload);
      }
      return null;
    } catch (e) {
      debugPrint(' Erreur météo API: $e');
      final stalePayload = await _readCachePayload(
        cacheKey,
        ttl: AppConfig.weatherCurrentCacheTtl,
        allowStaleFallback: true,
      );
      if (stalePayload != null) {
        final stale = WeatherResponse.fromJson(stalePayload);
        return _withFallbackFlag(stale);
      }
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
    final cacheKey = _buildCurrentCityKey(cityName);
    await _invalidatePreviousKeyIfChanged(
      trackingKey: _prefsCurrentCityLastKey,
      currentCacheKey: cacheKey,
    );

    final cached = await _readCachePayload(
      cacheKey,
      ttl: AppConfig.weatherCurrentCacheTtl,
    );
    if (cached != null) {
      return WeatherResponse.fromJson(cached);
    }

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
        final payload = _asJsonMap(data);
        if (payload == null) {
          return null;
        }

        await _saveCachePayload(
          cacheKey: cacheKey,
          payload: payload,
          ttl: AppConfig.weatherCurrentCacheTtl,
        );

        debugPrint(' Météo reçue: ${payload['main']['temp']}°C');
        return WeatherResponse.fromJson(payload);
      }
      return null;
    } catch (e) {
      debugPrint(' Erreur météo ville API: $e');
      final stalePayload = await _readCachePayload(
        cacheKey,
        ttl: AppConfig.weatherCurrentCacheTtl,
        allowStaleFallback: true,
      );
      if (stalePayload != null) {
        final stale = WeatherResponse.fromJson(stalePayload);
        return _withFallbackFlag(stale);
      }
      return null;
    }
  }

  /// Obtenir la prévision 5 jours
  Future<ForecastResponse?> getForecast(
    double latitude,
    double longitude,
  ) async {
    final cacheKey = _buildForecastCoordKey(latitude, longitude);
    await _invalidatePreviousKeyIfChanged(
      trackingKey: _prefsForecastCoordLastKey,
      currentCacheKey: cacheKey,
    );

    final cached = await _readCachePayload(
      cacheKey,
      ttl: AppConfig.weatherForecastCacheTtl,
    );
    if (cached != null) {
      return ForecastResponse.fromJson(cached);
    }

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
        final payload = _asJsonMap(data);
        if (payload == null) {
          return null;
        }

        await _saveCachePayload(
          cacheKey: cacheKey,
          payload: payload,
          ttl: AppConfig.weatherForecastCacheTtl,
        );

        debugPrint('Prévisions reçues: ${payload['list'].length} items');
        return ForecastResponse.fromJson(payload);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur prévisions API: $e');
      final stalePayload = await _readCachePayload(
        cacheKey,
        ttl: AppConfig.weatherForecastCacheTtl,
        allowStaleFallback: true,
      );
      if (stalePayload != null) {
        return ForecastResponse.fromJson(stalePayload);
      }
      return null;
    }
  }
}
