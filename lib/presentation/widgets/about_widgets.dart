import 'package:flutter/material.dart';
import 'package:magicmirror/core/constants/app_constants.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

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
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Magic Mirror',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
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
    return GlassContainer(
      borderRadius: 24,
      blur: 30,
      opacity: 0.08,
      padding: const EdgeInsets.all(24),
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
                : 'Magic Mirror est une application intelligente complète qui transforme votre écran en miroir sophistiqué avec des capacités d\'intelligence artificielle avancées.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
        'icon': '🪞',
        'title': isEnglish ? 'Smart Mirror' : 'Miroir Intelligent',
        'desc': isEnglish ? 'Real-time camera display' : 'Caméra temps réel',
      },
      {
        'icon': '🤖',
        'title': isEnglish ? 'Body Type AI' : 'Morphologie AI',
        'desc': isEnglish ? 'Pose detection' : 'Détection de pose',
      },
    ];

    return Column(
      children:
          features
              .map(
                (f) => ListTile(
                  leading: Text(f['icon']!, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    f['title']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    f['desc']!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
              .toList(),
    );
  }
}
