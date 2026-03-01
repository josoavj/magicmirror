import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

// Modèle simplifié pour la météo
class WeatherData {
  final double temperature;
  final String condition;
  final String city;

  WeatherData({required this.temperature, required this.condition, required this.city});
}

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  // Simulation d'un appel API météo
  await Future.delayed(const Duration(seconds: 2));
  return WeatherData(temperature: 18.5, condition: 'Nuageux', city: 'Paris');
});

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: weatherAsync.when(
        data: (data) => Column(
          children: [
            const Icon(Icons.cloud, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(
              '${data.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(data.condition, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text(data.city, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        loading: () => const CircularProgressIndicator(color: Colors.white),
        error: (_, __) => const Icon(Icons.error, color: Colors.redAccent),
      ),
    );
  }
}
