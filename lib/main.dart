import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/core/services/cache_service.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/routes/app_routes.dart';
import 'package:magicmirror/features/auth/presentation/widgets/auth_gate.dart';
import 'core/theme/app_theme.dart';

bool _isSupabaseReady = false;

void main() async {
  // Initialiser Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de locale pour la formatage des dates
  // Cela résout l'erreur LocaleDataException sur Android
  await initializeDateFormatting();

  // Charger les variables d'environnement depuis .env
  await dotenv.load(fileName: "assets/.env");

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _isSupabaseReady = true;
  }

  // Initialiser le logger
  await logger.initialize();

  // Afficher la configuration au démarrage
  await AppConfig.printStartupInfo();

  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == 'AppLifecycleState.detached') {
      await _cleanupOnExit();
    }
    return null;
  });

  runApp(const ProviderScope(child: MagicMirrorApp()));
}

/// Nettoie les ressources avant exit
Future<void> _cleanupOnExit() async {
  try {
    logger.info('Nettoyage ressources avant exit...', tag: 'Main');

    // Vider le cache
    cacheService.clear();
    logger.info('Cache vidé', tag: 'Main');

    // Fermer les logs
    await logger.dispose();
  } catch (e) {
    debugPrint('Erreur cleanup: $e');
  }
}

class MagicMirrorApp extends ConsumerWidget {
  const MagicMirrorApp({super.key});

  Locale _parseLocale(String rawLocale) {
    final parts = rawLocale.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return const Locale('fr', 'FR');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    const supportedLocales = [Locale('fr', 'FR'), Locale('en', 'US')];

    final requestedLocale = _parseLocale(settings.locale);
    final effectiveLocale =
        supportedLocales.any(
          (locale) =>
              locale.languageCode == requestedLocale.languageCode &&
              locale.countryCode == requestedLocale.countryCode,
        )
        ? requestedLocale
        : const Locale('fr', 'FR');

    return MaterialApp(
      title: 'Magic Mirror',
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.getTheme(settings.darkMode),
      home: AuthGate(isSupabaseReady: _isSupabaseReady),
      routes: AppRoutes.getRoutes(),
    );
  }
}
