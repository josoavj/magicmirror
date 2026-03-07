import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'core/utils/app_logger.dart';
import 'core/services/cache_service.dart';
import 'features/mirror/presentation/screens/mirror_screen.dart';
import 'features/agenda/presentation/screens/agenda_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'data/services/google_calendar_service.dart';
import 'config/app_config.dart';

void main() async {
  // Initialiser Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le logger
  await logger.initialize();

  // Afficher la configuration au démarrage
  await AppConfig.printStartupInfo();

  // Initialiser les services de base
  final googleCalendarService = GoogleCalendarService();
  await googleCalendarService.initialize();

  // BUG FIX #7: Exit hook pour cleanup ressources
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
    logger.info('🧹 Nettoyage ressources avant exit...', tag: 'Main');

    // Vider le cache
    cacheService.clear();
    logger.info('✅ Cache vidé', tag: 'Main');

    // Fermer les logs
    await logger.dispose();
  } catch (e) {
    debugPrint('❌ Erreur cleanup: $e');
  }
}

class MagicMirrorApp extends StatelessWidget {
  const MagicMirrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magic Mirror iOS 26',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'SF Pro Display', // Simulation police iOS
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/mirror': (context) => const MirrorScreen(),
        '/agenda': (context) => const AgendaScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // HUD Home
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Magic Mirror',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 48),
                // Grille de contrôle iOS Style
                Wrap(
                  spacing: 24,
                  runSpacing: 24,
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
                      label: 'Garde-robe',
                      color: Colors.purpleAccent,
                      onTap: () {},
                    ),
                    _HomeTile(
                      icon: Icons.settings_rounded,
                      label: 'Reglages',
                      color: Colors.grey,
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ],
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 48),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
