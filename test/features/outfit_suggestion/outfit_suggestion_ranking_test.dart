import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/agenda/data/services/agenda_supabase_service.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/screens/outfit_suggestion_screen.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/weather/data/models/weather_model.dart';
import 'package:magicmirror/features/weather/data/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAgendaSupabaseService extends AgendaSupabaseService {
  _FakeAgendaSupabaseService(this._eventsByDay);

  final Map<String, List<AgendaEvent>> _eventsByDay;

  String _dayKey(DateTime day) => '${day.year}-${day.month}-${day.day}';

  @override
  Future<List<AgendaEvent>> fetchEventsForDay(DateTime day) async {
    return _eventsByDay[_dayKey(day)] ?? const <AgendaEvent>[];
  }
}

class _FakeWeatherService extends WeatherService {
  _FakeWeatherService({required this.current, required this.forecast});

  final WeatherResponse? current;
  final ForecastResponse? forecast;

  @override
  Future<WeatherResponse?> getCurrentWeather() async => current;

  @override
  Future<ForecastResponse?> getForecast(
    double latitude,
    double longitude,
  ) async {
    return forecast;
  }
}

WeatherResponse _weather({
  required double temp,
  required String main,
  String description = 'test weather',
}) {
  return WeatherResponse(
    cityName: 'Ato aminay',
    temperature: temp,
    feelsLike: temp,
    humidity: 70,
    windSpeed: 6,
    description: description,
    main: main,
    icon: '01d',
    pressure: 1000,
    visibility: 10,
  );
}

ForecastResponse _forecastForTomorrow({
  required double temp,
  required String main,
  String description = 'forecast weather',
}) {
  final now = DateTime.now();
  final tomorrowNoon = DateTime(now.year, now.month, now.day + 1, 12);
  return ForecastResponse(
    city: 'Ato aminay',
    forecasts: [
      ForecastItem(
        dateTime: tomorrowNoon,
        temperature: temp,
        description: description,
        main: main,
        icon: '01d',
        windSpeed: 5,
        humidity: 65,
      ),
    ],
  );
}

AgendaEvent _event({
  required String id,
  required String title,
  required String eventType,
  required DateTime start,
  required DateTime end,
}) {
  return AgendaEvent(
    id: id,
    userId: 'u1',
    title: title,
    eventType: eventType,
    startTime: start,
    endTime: end,
  );
}

Future<void> _pumpOutfitScreen(
  WidgetTester tester, {
  required UserProfile profile,
  required bool strictWeatherMode,
  required WeatherResponse weather,
  required List<AgendaEvent> todayEvents,
}) async {
  SharedPreferences.setMockInitialValues({
    'profile.userId': profile.userId,
    'profile.displayName': profile.displayName,
    'profile.avatarUrl': profile.avatarUrl,
    'profile.gender': profile.gender,
    'profile.age': profile.age,
    'profile.birthDate': profile.birthDate?.toIso8601String() ?? '',
    'profile.morphology': profile.morphology,
    'profile.preferredStyles': profile.preferredStyles,
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final key = '${today.year}-${today.month}-${today.day}';
  final agendaService = _FakeAgendaSupabaseService({key: todayEvents});
  final weatherService = _FakeWeatherService(
    current: weather,
    forecast: _forecastForTomorrow(
      temp: weather.temperature,
      main: weather.main,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        agendaSupabaseServiceProvider.overrideWith((ref) => agendaService),
        outfitWeatherServiceProvider.overrideWith((ref) => weatherService),
      ],
      child: const MaterialApp(home: OutfitSuggestionScreen()),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));

  // Wait a bit for async weather bundle resolution before assertions.
  for (var i = 0; i < 8; i++) {
    if (find.textContaining('Meteo:').evaluate().isNotEmpty ||
        find.textContaining('Weather:').evaluate().isNotEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  if (!strictWeatherMode) {
    final switchFinder = find.byType(Switch);
    if (switchFinder.evaluate().isNotEmpty) {
      await tester.tap(switchFinder.first);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'test.test.test',
      );
    }
  });

  testWidgets(
    'strict weather off keeps streetwear candidate in rainy context',
    (tester) async {
      final profile = UserProfile.defaults().copyWith(
        morphology: 'Epaules tres marquees',
        preferredStyles: const ['Streetwear'],
      );

      await _pumpOutfitScreen(
        tester,
        profile: profile,
        strictWeatherMode: false,
        weather: _weather(temp: 22, main: 'Rain', description: 'light rain'),
        todayEvents: const <AgendaEvent>[],
      );

      expect(find.text('Street Dynamics'), findsWidgets);
    },
  );

  testWidgets('strict weather mode is enabled by default', (tester) async {
    final profile = UserProfile.defaults().copyWith(
      morphology: 'Epaules tres marquees',
      preferredStyles: const ['Streetwear'],
    );

    await _pumpOutfitScreen(
      tester,
      profile: profile,
      strictWeatherMode: true,
      weather: _weather(temp: 22, main: 'Rain', description: 'light rain'),
      todayEvents: const <AgendaEvent>[],
    );

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);
  });

  testWidgets('work event prioritizes business/elegant suggestions', (
    tester,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    final end = DateTime(now.year, now.month, now.day, 10);

    await _pumpOutfitScreen(
      tester,
      profile: UserProfile.defaults().copyWith(
        preferredStyles: const ['Casual'],
        morphology: 'Hanches et epaules equilibrees',
      ),
      strictWeatherMode: true,
      weather: _weather(temp: 24, main: 'Clear', description: 'clear sky'),
      todayEvents: [
        _event(
          id: 'w1',
          title: 'Reunion client',
          eventType: 'Work',
          start: start,
          end: end,
        ),
      ],
    );

    expect(find.text('Business Smart'), findsWidgets);
    expect(find.text('Compatible avec votre planning pro'), findsWidgets);
  });
}
