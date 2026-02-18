/// Modèle pour les données météo
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
