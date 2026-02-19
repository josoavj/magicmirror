import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'config/app_config.dart';
import 'routes/app_routes.dart';
import 'features/mirror/presentation/screens/mirror_screen.dart';
import 'features/agenda/presentation/screens/agenda_screen.dart';
import 'features/outfit_suggestion/presentation/screens/outfit_suggestion_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: AppConfig.enableDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: AppConfig.defaultLocale,
      debugShowCheckedModeBanner: AppConfig.isDevelopment,
      routes: {
        '/': (context) => const _HomeScreen(),
        '/mirror': (context) => const MirrorScreen(),
        //'/agenda': (context) => const AgendaScreen(),
        '/outfit-suggestion': (context) => const OutfitSuggestionScreen(),
      },
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Magic Mirror'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue sur Magic Mirror',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildMenuButton(
              context,
              'Miroir',
              Icons.camera,
              AppColors.primary,
              () => Navigator.pushNamed(context, '/mirror'),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Agenda',
              Icons.calendar_today,
              AppColors.secondary,
              () => Navigator.pushNamed(context, '/agenda'),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Suggestions de Tenue',
              Icons.checkroom,
              AppColors.accent,
              () => Navigator.pushNamed(context, '/outfit-suggestion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
