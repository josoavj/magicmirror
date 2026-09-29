import 'package:flutter/material.dart';
import 'package:magicmirror/core/constants/app_constants.dart';

class AboutHeader extends StatelessWidget {
  final bool isEnglish;

  const AboutHeader({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 124,
          height: 124,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.withValues(alpha: 0.8),
                Colors.purpleAccent.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/magicmirrorlogo.png',
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Magic Mirror',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'v${AppConstants.appVersion}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AboutCard extends StatelessWidget {
  final bool isEnglish;

  const AboutCard({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish ? 'About The App' : 'À propos de l\'application',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? 'Magic Mirror is a complete smart app that turns your screen into a sophisticated mirror with advanced AI capabilities.'
                  : 'Magic Mirror est une application intelligente complète qui transforme votre écran en miroir sophistiqué avec des capacités d\'intelligence artificielles avancées.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutFeatureList extends StatelessWidget {
  final bool isEnglish;

  const AboutFeatureList({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    final features = [
      {
        'icon': Icons.camera_alt_outlined,
        'title': isEnglish ? 'Smart Mirror' : 'Miroir Intelligent',
        'desc': isEnglish ? 'Real-time camera display' : 'Caméra temps réel',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': isEnglish ? 'Body Type AI' : 'Morphologie AI',
        'desc': isEnglish ? 'Pose detection' : 'Détection de pose',
      },
      {
        'icon': Icons.calendar_month_outlined,
        'title': isEnglish ? 'Agenda & Events' : 'Agenda & Événements',
        'desc': isEnglish
            ? 'Sync with your schedule'
            : 'Synchronisation du planning',
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'title': isEnglish ? 'Weather Forecast' : 'Prévisions Météo',
        'desc': isEnglish ? 'Local weather updates' : 'Météo locale en direct',
      },
      {
        'icon': Icons.checkroom_outlined,
        'title': isEnglish ? 'Outfit Suggestions' : 'Suggestions de Tenue',
        'desc': isEnglish
            ? 'Smart fashion advice'
            : 'Conseils mode intelligents',
      },
      {
        'icon': Icons.security_outlined,
        'title': isEnglish ? 'Privacy First' : 'Confidentialité',
        'desc': isEnglish
            ? 'Your data stays yours'
            : 'Vos données restent privées',
      },
    ];

    return Column(
      children: features
          .map(
            (f) => ListTile(
              leading: Icon(
                f['icon'] as IconData,
                color: Colors.blueAccent,
                size: 28,
              ),
              title: Text(
                f['title'] as String,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                f['desc'] as String,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          )
          .toList(),
    );
  }
}
