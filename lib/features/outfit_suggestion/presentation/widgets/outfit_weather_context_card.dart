import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/domain/entities/outfit.dart';

class OutfitWeatherContextCard extends StatelessWidget {
  const OutfitWeatherContextCard({super.key, required this.weatherAsync});

  final AsyncValue<OutfitWeatherBundle> weatherAsync;

  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: weatherAsync.when(
        loading: () => Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              _tr(context, 'Chargement météo…', 'Loading weather…'),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        error: (error, stack) => Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tr(
                  context,
                  'Météo indisponible : les suggestions restent basées sur votre profil et votre agenda.',
                  'Weather unavailable: suggestions still use your profile and calendar.',
                ),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        data: (bundle) {
          final current = bundle.currentWeather;
          final forecast = bundle.tomorrowForecast;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_cloudy_outlined,
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tr(context, 'Contexte météo', 'Weather context'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                current == null
                    ? _tr(
                        context,
                        'Météo actuelle indisponible',
                        'Current weather unavailable',
                      )
                    : '${_tr(context, 'Aujourd’hui', 'Today')} · ${current.cityName} · ${current.description} · ${current.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                forecast == null
                    ? _tr(
                        context,
                        'Prévision de demain indisponible',
                        'Tomorrow’s forecast unavailable',
                      )
                    : '${_tr(context, 'Demain', 'Tomorrow')} · ${forecast.description} · ${forecast.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(color: Colors.white70),
              ),
              if (current?.isFallback == true)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _tr(
                      context,
                      'Données météo de secours utilisées.',
                      'Fallback weather data is being used.',
                    ),
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
