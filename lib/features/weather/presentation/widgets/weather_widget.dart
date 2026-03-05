import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import '../../../weather/data/services/weather_service.dart';
import '../../../weather/data/models/weather_model.dart';

/// Provider pour le service météo
final weatherServiceProvider = Provider<WeatherService>(
  (ref) => WeatherService(),
);

/// Provider pour la météo actuelle
final currentWeatherProvider = FutureProvider<WeatherResponse?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  try {
    return await service.getCurrentWeather();
  } catch (e) {
    logger.error('Erreur météo', tag: 'WeatherWidget', error: e);
    // Fallback sur données simulées si l'API échoue
    return WeatherResponse(
      cityName: 'Antananarivo',
      temperature: 22.5,
      feelsLike: 23.0,
      humidity: 75,
      windSpeed: 8.0,
      description: 'Partiellement nuageux',
      main: 'Clouds',
      icon: '02d',
      pressure: 1015,
      visibility: 10.0,
    );
  }
});

/// Widget affichant la météo actuelle
class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  /// Obtenir l'emoji de la météo
  String _getWeatherEmoji(String condition) {
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('clear') || lowerCondition.contains('sunny')) {
      return '☀️';
    } else if (lowerCondition.contains('cloud')) {
      return '☁️';
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('drizzle')) {
      return '🌧️';
    } else if (lowerCondition.contains('thunder')) {
      return '⛈️';
    } else if (lowerCondition.contains('snow')) {
      return '❄️';
    } else if (lowerCondition.contains('mist') ||
        lowerCondition.contains('fog')) {
      return '🌫️';
    }
    return '🌤️';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      width: 280,
      child: weatherAsync.when(
        data: (weather) {
          if (weather == null) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Météo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Non disponible',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.cityName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature.toStringAsFixed(1)}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _getWeatherEmoji(weather.description),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Image.network(
                    weather.iconUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        _getWeatherEmoji(weather.description),
                        style: const TextStyle(fontSize: 60),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              Column(
                children: [
                  _WeatherDetailRow(
                    'Ressenti',
                    '${weather.feelsLike.toStringAsFixed(1)}°C',
                  ),
                  const SizedBox(height: 8),
                  _WeatherDetailRow('Humidité', '${weather.humidity}%'),
                  const SizedBox(height: 8),
                  _WeatherDetailRow(
                    'Vent',
                    '${weather.windSpeed.toStringAsFixed(1)} m/s',
                  ),
                ],
              ),
              if (weather.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  weather.description.replaceFirstMapped(
                    RegExp(r'^.'),
                    (match) => match.group(0)!.toUpperCase(),
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              'Chargement...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        error: (error, stack) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              color: Colors.white.withValues(alpha: 0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Erreur météo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget affichant un détail météo
class _WeatherDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherDetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
