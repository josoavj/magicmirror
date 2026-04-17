import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/app_logger.dart';
import 'core/services/cache_service.dart';
import 'features/mirror/presentation/screens/mirror_screen.dart';
import 'features/agenda/presentation/screens/agenda_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/screens/account_settings_screen.dart';
import 'features/settings/presentation/screens/outfit_insights_settings_screen.dart';
import 'features/outfit_suggestion/presentation/screens/outfit_suggestion_screen.dart';
import 'features/weather/presentation/screens/weather_screen.dart';
import 'features/user_profile/presentation/screens/user_profile_screen.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/auth/presentation/screens/verify_email_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'presentation/screens/about_screen.dart';
import 'presentation/widgets/glass_container.dart';
import 'config/app_config.dart';

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

    final baseTheme = ThemeData(
      brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Magic Mirror',
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'Lexend'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: 'Lexend',
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: AppColors.glassBorder.withValues(
                alpha: AppColors.glassBorderOpacity,
              ),
              width: 1.1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/mirror': (context) => const MirrorScreen(),
        '/agenda': (context) => const AgendaScreen(),
        '/weather': (context) => const WeatherScreen(),
        '/outfit-suggestion': (context) => const OutfitSuggestionScreen(),
        '/outfit-favorites': (context) =>
            const OutfitSuggestionScreen(initialShowFavorites: true),
        '/profile': (context) => const UserProfileScreen(),
        '/account-settings': (context) => const AccountSettingsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/settings/outfit-insights': (context) =>
            const OutfitInsightsSettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_isSupabaseReady) {
      final l10n = Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      );
      return Scaffold(
        body: Center(
          child: Text(
            l10n?.supabaseNotConfigured ??
                'Supabase non configure dans assets/.env',
          ),
        ),
      );
    }

    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final event = snapshot.data?.event;
        final session = snapshot.data?.session;
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }
        if (session == null) {
          return const AuthScreen();
        }

        final confirmed = session.user.emailConfirmedAt != null;
        if (!confirmed) {
          return const VerifyEmailScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesCount = ref.watch(outfitFavoritesProvider).length;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
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
                          label: isEnglish ? 'Mirror' : 'Miroir',
                          color: Colors.blueAccent,
                          onTap: () => Navigator.pushNamed(context, '/mirror'),
                        ),
                        _HomeTile(
                          icon: Icons.calendar_today_rounded,
                          label: isEnglish ? 'Agenda' : 'Agenda',
                          color: Colors.orangeAccent,
                          onTap: () => Navigator.pushNamed(context, '/agenda'),
                        ),
                        _HomeTile(
                          icon: Icons.person_outline_rounded,
                          label: isEnglish ? 'Profile' : 'Profil',
                          color: Colors.tealAccent,
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                        ),
                        _HomeTile(
                          icon: Icons.checkroom_rounded,
                          label: isEnglish ? 'Outfits' : 'Tenues',
                          color: Colors.deepPurpleAccent,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/outfit-suggestion',
                          ),
                        ),
                        _HomeTile(
                          icon: Icons.favorite_rounded,
                          label: isEnglish ? 'Favorites' : 'Favoris',
                          color: Colors.pinkAccent,
                          badgeCount: favoritesCount,
                          onTap: () =>
                              Navigator.pushNamed(context, '/outfit-favorites'),
                        ),
                        _HomeTile(
                          icon: Icons.settings_rounded,
                          label: isEnglish ? 'Settings' : 'Réglages',
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
  final int badgeCount;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
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
              if (badgeCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
