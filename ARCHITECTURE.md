# 🏗️ Architecture - LevelMind

## Vue d'ensemble architecture

LevelMind suit une architecture **Clean Architecture** avec **Riverpod** pour la gestion d'état.

```
┌─────────────────────────────────────────────────┐
│         Presentation Layer (UI/Widgets)         │
│  - Screens, Pages, Widgets                      │
│  - Providers (Riverpod)                         │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│       Domain Layer (Business Logic)             │
│  - Models                                       │
│  - Repositories (interfaces)                    │
│  - UseCases                                     │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│        Data Layer (API/Cache/Storage)           │
│  - DataSources (API, Local)                     │
│  - Repositories (implementations)               │
│  - Models (DTOs)                                │
│  - Services                                     │
└─────────────────────────────────────────────────┘
```

---

## Structure des dossiers

```
lib/
├── main.dart                    # Entry point
├── config/
│   ├── app_config.dart         # Feature flags & settings
│   ├── di_setup.dart           # Dependency injection
│   └── theme_config.dart       # App theme
│
├── core/                        # Shared utilities
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── error_codes.dart
│   ├── services/
│   │   ├── cache_service.dart  # TTL-based caching
│   │   ├── connectivity_service.dart
│   │   ├── storage_service.dart
│   │   └── tts_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_data.dart
│   └── utils/
│       ├── app_logger.dart
│       ├── extensions.dart
│       └── validators.dart
│
├── data/                        # Data layer
│   ├── datasources/
│   │   ├── local/
│   │   │   └── local_datasource.dart
│   │   └── remote/
│   │       └── remote_datasource.dart
│   ├── models/
│   │   ├── weather_model.dart
│   │   ├── agenda_model.dart
│   │   └── morphology_model.dart
│   ├── repositories/
│   │   ├── weather_repository.dart
│   │   ├── agenda_repository.dart
│   │   └── morphology_repository.dart
│   └── services/
│       ├── weather_service.dart
│       ├── google_calendar_service.dart
│       ├── mock_calendar_service.dart
│       ├── morphology_service.dart
│       └── frame_processor.dart
│
├── features/                    # Feature modules
│   ├── mirror/                  # Main mirror screen
│   │   ├── data/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── mirror_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── camera_preview_widget.dart
│   │   │   │   └── ml_overlay_widget.dart
│   │   │   └── providers/
│   │   │       └── camera_provider.dart
│   │   └── domain/
│   │
│   ├── agenda/                  # Calendar/Events
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── agenda_screen.dart
│   │   │   ├── widgets/
│   │   │   │   └── agenda_list_widget.dart
│   │   │   └── providers/
│   │   │       └── agenda_provider.dart
│   │   └── domain/
│   │
│   ├── weather/                 # Weather integration
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   │   └── weather_model.dart
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   │       └── weather_service.dart
│   │   ├── presentation/
│   │   │   └── widgets/
│   │   │       └── weather_widget.dart
│   │   └── domain/
│   │
│   ├── ai_ml/                   # ML & Morphology
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── services/
│   │   │       ├── morphology_service.dart
│   │   │       └── frame_processor.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── ai_ml_screen.dart
│   │   │   └── widgets/
│   │   └── domain/
│   │
│   └── outfit_suggestion/       # Suggestions
│       ├── data/
│       ├── presentation/
│       │   └── widgets/
│       │       └── outfit_recommendation_widget.dart
│       └── domain/
│
├── presentation/                # Global UI components
│   ├── pages/
│   │   ├── main_page.dart
│   │   └── splash_page.dart
│   ├── screens/
│   ├── widgets/
│   │   ├── glass_container.dart
│   │   ├── loading_overlay.dart
│   │   └── error_widget.dart
│   └── providers/
│       └── app_provider.dart
│
├── routes/
│   ├── app_routes.dart
│   └── route_names.dart
│
└── generated/
    └── assets.gen.dart         # Generated assets
```

---

## Flux de données (Data Flow)

### Exemple: Affichage de la météo

```
Widget (weather_widget.dart)
    │
    ├─→ watch(currentWeatherProvider)
    │       │
    │       └─→ FutureProvider
    │           │
    │           ├─→ weather_provider.dart
    │           │   │
    │           │   ├─→ WeatherRepository.getWeather()
    │           │   │   │
    │           │   │   └─→ WeatherService.fetchWeather()
    │           │   │       │
    │           │   │       ├─→ CacheService.get() ─→ Cached?
    │           │   │       │                          │ Yes → Return cached
    │           │   │       │                          │ No  → Fetch API
    │           │   │       │
    │           │   │       └─→ Dio HTTP request
    │           │   │           │
    │           │   │           ├─→ CacheService.set()
    │           │   │           └─→ return Weather
    │           │   │
    │           │   └─→ WeatherModel → Domain Model
    │           │
    │           └─→ AsyncValue<Weather>
    │
    └─→ UI renders based on AsyncValue state
        (loading, data, error)
```

---

## State Management (Riverpod)

### Types de Providers utilisés

#### 1. **FutureProvider** - Async operations
```dart
final currentWeatherProvider = FutureProvider<Weather?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getWeather();
});
```

#### 2. **StateNotifierProvider** - Complex state
```dart
final agendaProvider = StateNotifierProvider<AgendaNotifier, List<Event>>((ref) {
  return AgendaNotifier(ref);
});
```

#### 3. **Provider** - Simple values
```dart
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
```

### Lifecycle Hooks

```dart
ref.onDispose(() {
  // Cleanup when provider is no longer used
  controller.dispose();
  timer.cancel();
});

ref.onResume(() {
  // Resume operations
});

ref.onPause(() {
  // Pause operations
});
```

---

## Resource Management

### Memory Management
- ✅ **Providers disposal**: All FutureProviders auto-disposed
- ✅ **Streams cleanup**: .distinct() + .asBroadcastStream()
- ✅ **Cache TTL**: Auto-expiration every 5 minutes
- ✅ **Image buffers**: stopImageStream() before dispose

### Performance
- ✅ **API caching**: 90% API reduction for weather
- ✅ **Timeouts**: Platform-specific (5s mobile, 10s desktop)
- ✅ **Auto-refresh**: 30min timer for agenda
- ✅ **Efficient ML**: Kalman filter + dynamic FPS

---

## Error Handling

### Pattern: AsyncValue

```dart
return asyncValue.when(
  data: (data) => WeatherDisplay(data),        // Success
  loading: () => ShimmerLoading(),              // Loading
  error: (error, stack) => ErrorWidget(error),  // Error
);
```

### Retry Logic
```dart
ElevatedButton(
  onPressed: () {
    ref.refresh(currentWeatherProvider);
  },
  child: Text('Retry'),
)
```

---

## Testing Strategy

### Unit Tests
```dart
test('WeatherService returns correct data', () async {
  final service = WeatherService();
  final weather = await service.getWeather();
  expect(weather, isNotNull);
});
```

### Widget Tests
```dart
testWidgets('Weather widget displays temperature', (_async test) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('18°C'), findsOneWidget);
});
```

### Integration Tests
```dart
testWidgets('Full weather flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  // Interact with app
  // Verify results
});
```

---

## Best Practices

### ✅ DO
- Use proper error handling
- Dispose resources properly
- Cache when appropriate
- Use constants instead of magic numbers
- Log important events
- Validate inputs

### ❌ DON'T
- Hardcode API keys
- Use global state
- Forget to dispose providers
- Ignore lifecycle events
- Block main thread
- Make UI logic in services

---

## Dependencies Graph

```
Main
├─ RunApp(MyApp)
│
└─ di_setup.dart
   ├─ cacheService (singleton)
   ├─ connectivityService (singleton)
   ├─ weatherService
   ├─ calendarService
   └─ morphologyService
```

---

Pour plus d'infos:
- [README.md](README.md) - Overview
- [GETTING_STARTED.md](GETTING_STARTED.md) - Quick start
- [SETUP.md](SETUP.md) - Production setup
