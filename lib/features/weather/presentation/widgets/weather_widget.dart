import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/core/utils/responsive_helper.dart';
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
      observedAt: DateTime.now(),
      isFallback: true,
    );
  }
});

/// Widget affichant la météo actuelle
class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  String _freshnessLabel(WeatherResponse weather) {
    final minutes = weather.minutesSinceObservation;
    if (minutes == null) {
      return weather.isFallback ? 'Source: fallback local' : 'Source: API';
    }
    final source = weather.isFallback ? 'fallback local' : 'API';
    if (minutes < 1) {
      return 'Mise a jour: a l\'instant ($source)';
    }
    if (minutes < 60) {
      return 'Mise a jour: il y a $minutes min ($source)';
    }
    final hours = (minutes / 60).floor();
    return 'Mise a jour: il y a $hours h ($source)';
  }

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

    // Calcul responsive de la largeur - adapté pour ne pas déborder sur petit écran
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidgetWidth = ResponsiveHelper.isMobile(context)
        ? (screenWidth * 0.85).clamp(200.0, 290.0)
        : 280.0;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: maxWidgetWidth,
        child: weatherAsync.when(
          data: (weather) {
            if (weather == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Météo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: ResponsiveHelper.resp(
                        context,
                        mobile: 12,
                        tablet: 14,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Non disponible',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: ResponsiveHelper.resp(
                        context,
                        mobile: 11,
                        tablet: 12,
                      ),
                    ),
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: ResponsiveHelper.resp(
                              context,
                              mobile: 11,
                              tablet: 12,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _freshnessLabel(weather),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: ResponsiveHelper.resp(
                              context,
                              mobile: 10,
                              tablet: 11,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temperature.toStringAsFixed(1)}°',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.resp(
                                  context,
                                  mobile: 28,
                                  tablet: 36,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                _getWeatherEmoji(weather.description),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.resp(
                                    context,
                                    mobile: 24,
                                    tablet: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Image.network(
                      weather.iconUrl,
                      width: ResponsiveHelper.resp(
                        context,
                        mobile: 60,
                        tablet: 80,
                      ),
                      height: ResponsiveHelper.resp(
                        context,
                        mobile: 60,
                        tablet: 80,
                      ),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          _getWeatherEmoji(weather.description),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.resp(
                              context,
                              mobile: 48,
                              tablet: 60,
                            ),
                          ),
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
                      fontSize: ResponsiveHelper.resp(
                        context,
                        mobile: 11,
                        tablet: 13,
                      ),
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
                size: ResponsiveHelper.resp(context, mobile: 24, tablet: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Erreur météo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: ResponsiveHelper.resp(
                    context,
                    mobile: 11,
                    tablet: 12,
                  ),
                ),
              ),
            ],
          ),
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
            fontSize: ResponsiveHelper.resp(context, mobile: 11, tablet: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveHelper.resp(context, mobile: 11, tablet: 12),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
