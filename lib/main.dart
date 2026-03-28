import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/utils/app_logger.dart';
import 'core/services/cache_service.dart';
import 'features/mirror/presentation/screens/mirror_screen.dart';
import 'features/agenda/presentation/screens/agenda_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'presentation/screens/about_screen.dart';
import 'presentation/widgets/glass_container.dart';
import 'data/services/google_calendar_service.dart';
import 'config/app_config.dart';

void main() async {
  // Initialiser Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de locale pour la formatage des dates
  // Cela résout l'erreur LocaleDataException sur Android
  await initializeDateFormatting('fr_FR', null);

  // Charger les variables d'environnement depuis .env
  await dotenv.load(fileName: "assets/.env");

  // Initialiser le logger
  await logger.initialize();

  // Afficher la configuration au démarrage
  await AppConfig.printStartupInfo();

  // Initialiser les services de base
  final googleCalendarService = GoogleCalendarService();
  await googleCalendarService.initialize(
    clientId: dotenv.env['GOOGLE_CLIENT_ID']?.trim().isEmpty == true
        ? null
        : dotenv.env['GOOGLE_CLIENT_ID']?.trim(),
    serverClientId:
        dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim().isEmpty == true
        ? null
        : dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim(),
  );

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

    final baseTheme = ThemeData(
      brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Magic Mirror iOS 26',
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.lexendTextTheme(baseTheme.textTheme),
        primaryTextTheme: GoogleFonts.lexendTextTheme(
          baseTheme.primaryTextTheme,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        '/mirror': (context) => const MirrorScreen(),
        '/agenda': (context) => const AgendaScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final horizontalPadding = isMobile ? 20.0 : 28.0;
    final gridMaxWidth = isMobile ? 340.0 : 420.0;

    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan Mesh Gradient (Simulé par dégradé complexe)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF334155),
                ],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: isMobile ? 260 : 380,
              height: isMobile ? 260 : 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyan.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -120,
            child: Container(
              width: isMobile ? 300 : 460,
              height: isMobile ? 300 : 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigoAccent.withValues(alpha: 0.14),
              ),
            ),
          ),
          // HUD Home
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: gridMaxWidth),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Magic Mirror',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 40),
                    // Grille de contrôle 2x2 fixe
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: isMobile ? 12 : 20,
                      mainAxisSpacing: isMobile ? 12 : 20,
                      children: [
                        _HomeTile(
                          icon: Icons.auto_awesome_mosaic,
                          label: 'Miroir',
                          color: Colors.blueAccent,
                          onTap: () => Navigator.pushNamed(context, '/mirror'),
                        ),
                        _HomeTile(
                          icon: Icons.calendar_today_rounded,
                          label: 'Agenda',
                          color: Colors.orangeAccent,
                          onTap: () => Navigator.pushNamed(context, '/agenda'),
                        ),
                        _HomeTile(
                          icon: Icons.checkroom_rounded,
                          label: 'Tenues',
                          color: Colors.purpleAccent,
                          onTap: () {},
                        ),
                        _HomeTile(
                          icon: Icons.settings_rounded,
                          label: 'Réglages',
                          color: Colors.grey,
                          onTap: () =>
                              Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final iconBubbleSize = isMobile ? 52.0 : 62.0;
    final iconSize = isMobile ? 28.0 : 34.0;
    final labelFontSize = isMobile ? 14.0 : 17.0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 30,
        blur: 34,
        opacity: 0.11,
        tintColor: color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 10 : 12,
          ),
          child: Column(
            children: [
              const Spacer(flex: 4),
              Container(
                width: iconBubbleSize,
                height: iconBubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: isMobile ? 10 : 14),
              SizedBox(
                height: isMobile ? 34 : 42,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: const StrutStyle(height: 1.15),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
