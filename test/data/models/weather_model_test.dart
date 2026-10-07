import 'package:flutter_test/flutter_test.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherResponse', () {
    test('fromJson should return a valid WeatherResponse from valid JSON', () {
      final json = {
        'name': 'Paris',
        'main': {'temp': 25.5, 'feels_like': 26.0, 'humidity': 60, 'pressure': 1013},
        'wind': {'speed': 5.5},
        'weather': [
          {'description': 'ciel dégagé', 'main': 'Clear', 'icon': '01d'}
        ],
        'visibility': 10000,
        'dt': 1627456000,
        'sys': {'sunrise': 1627440000, 'sunset': 1627490000}
      };

      final response = WeatherResponse.fromJson(json);

      expect(response.cityName, 'Paris');
      expect(response.temperature, 25.5);
      expect(response.main, 'Clear');
      expect(response.description, 'ciel dégagé');
      expect(response.humidity, 60);
    });

    test('isBadWeather should return true for rain, thunderstorm, or snow', () {
      final rainy = WeatherResponse(
        cityName: 'City',
        temperature: 20,
        feelsLike: 20,
        humidity: 80,
        windSpeed: 10,
        description: 'rain',
        main: 'Rain',
        icon: '10d',
        pressure: 1010,
        visibility: 5,
      );

      final clear = WeatherResponse(
        cityName: 'City',
        temperature: 25,
        feelsLike: 25,
        humidity: 50,
        windSpeed: 2,
        description: 'clear',
        main: 'Clear',
        icon: '01d',
        pressure: 1015,
        visibility: 10,
      );

      expect(rainy.isBadWeather, isTrue);
      expect(clear.isBadWeather, isFalse);
    });
  });

  group('ForecastItem', () {
    test('fromJson should return a valid ForecastItem', () {
      final json = {
        'dt_txt': '2026-07-28 12:00:00',
        'main': {'temp': 22.0, 'humidity': 55},
        'weather': [
          {'description': 'nuageux', 'main': 'Clouds', 'icon': '04d'}
        ],
        'wind': {'speed': 4.0}
      };

      final item = ForecastItem.fromJson(json);

      expect(item.temperature, 22.0);
      expect(item.main, 'Clouds');
      expect(item.dateTime.year, 2026);
    });
  });
}
