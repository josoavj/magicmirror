/// Repository pour les opérations météo
abstract class WeatherRepository {
  Future<dynamic> getCurrentWeather(double latitude, double longitude);
  Future<dynamic> getForecast(double latitude, double longitude);
}
