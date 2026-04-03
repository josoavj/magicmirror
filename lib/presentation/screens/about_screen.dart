import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../widgets/glass_container.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'About' : 'A propos'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Logo & Titre
                  _buildHeader(isEnglish),

                  const SizedBox(height: 32),

                  // Description Générale
                  _buildAboutCard(isEnglish),

                  const SizedBox(height: 24),

                  // Fonctionnalités
                  _buildFeaturesSection(isEnglish),

                  const SizedBox(height: 24),

                  // Informations Techniques
                  _buildTechnicalInfo(isEnglish),

                  const SizedBox(height: 24),

                  // Développeur
                  _buildDeveloperSection(isEnglish),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEnglish) {
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
          'v1.0.0 - Beta',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(bool isEnglish) {
    return GlassContainer(
      borderRadius: 24,
      blur: 30,
      opacity: 0.08,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'About The App' : 'A propos de l\'application',
            style: TextStyle(
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
                : 'Magic Mirror est une application intelligente complete qui transforme votre ecran en miroir sophistique avec des capacites d\'intelligence artificielle avancees.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isEnglish
                ? 'It combines cutting-edge technology, clean design, and practical features for an exceptional user experience.'
                : 'Combinant technologie de pointe, design epure et fonctionnalites pratiques pour une experience utilisateur exceptionnelle.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isEnglish) {
    final features = [
      {
        'icon': '🪞',
        'title': isEnglish ? 'Smart Mirror' : 'Miroir Intelligent',
        'description': isEnglish
            ? 'Real-time camera with full-screen display'
            : 'Camera temps reel avec affichage plein ecran',
      },
      {
        'icon': '🤖',
        'title': isEnglish ? 'Body Type AI' : 'Morphologie AI',
        'description': isEnglish
            ? 'Pose detection and body type classification'
            : 'Detection de pose et classification de morphologie',
      },
      {
        'icon': '👔',
        'title': isEnglish ? 'Outfit Suggestions' : 'Suggestions Tenue',
        'description': isEnglish
            ? 'Personalized recommendations by body type'
            : 'Recommandations personnalisees par morphologie',
      },
      {
        'icon': '📅',
        'title': isEnglish ? 'Calendar Sync' : 'Synchronisation Calendrier',
        'description': isEnglish
            ? 'Supabase cloud agenda linked to active account'
            : 'Agenda cloud Supabase lie au compte actif',
      },
      {
        'icon': '🌦️',
        'title': isEnglish ? 'Live Weather' : 'Meteo en Temps Reel',
        'description': isEnglish
            ? 'OpenWeatherMap API with geolocation'
            : 'API OpenWeatherMap avec geolocalisation',
      },
      {
        'icon': '🗣️',
        'title': isEnglish ? 'Text To Speech' : 'Synthese Vocale',
        'description': isEnglish
            ? 'TTS support for spoken guidance'
            : 'Synthese vocale pour tous les contenus',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Features' : 'Fonctionnalites',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              borderRadius: 16,
              blur: 20,
              opacity: 0.06,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    feature['icon'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['description'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalInfo(bool isEnglish) {
    final techStack = [
      {'title': 'Framework', 'value': 'Flutter 3.1.0+'},
      {'title': isEnglish ? 'Language' : 'Langage', 'value': 'Dart 3.1.0+'},
      {'title': isEnglish ? 'State' : 'Etat', 'value': 'Riverpod 3.2.1'},
      {'title': 'ML', 'value': 'Google ML Kit 0.21.0'},
      {'title': 'API', 'value': 'OpenWeatherMap + Supabase'},
      {'title': isEnglish ? 'Status' : 'Statut', 'value': '✅ Stable'},
    ];

    return GlassContainer(
      borderRadius: 24,
      blur: 30,
      opacity: 0.08,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'Technical Stack' : 'Stack Technique',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...techStack.asMap().entries.map((entry) {
            final isLast = entry.key == techStack.length - 1;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.value['title'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      entry.value['value'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(bool isEnglish) {
    return GlassContainer(
      borderRadius: 24,
      blur: 30,
      opacity: 0.08,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish ? 'About The Developer' : 'A propos du developpeur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.8),
                      Colors.cyanAccent.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text('👨‍💻', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Developed by',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@josoavj',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Antananarivo, Madagascar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            isEnglish
                ? 'Passionate about Flutter and creating innovative user experiences.'
                : 'Passionne par Flutter et la creation d\'experiences utilisateur innovantes.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSocialButton(
                isEnglish ? 'GitHub Profile' : 'Profil GitHub',
                Icons.code,
                Colors.grey,
                'https://github.com/josoavj',
              ),
              _buildSocialButton(
                isEnglish ? 'MagicMirror Repo' : 'Depot MagicMirror',
                Icons.source,
                Colors.lightBlueAccent,
                'https://github.com/josoavj/magicmirror',
              ),
              _buildSocialButton(
                'Portfolio',
                Icons.language,
                Colors.amber,
                'https://josoavj-portfolio.vercel.app/',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color color,
    String url,
  ) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    final openedExternal = await url_launcher.launchUrl(
      url,
      mode: url_launcher.LaunchMode.externalApplication,
    );

    if (openedExternal) {
      return;
    }

    // Fallback utile sur certains appareils Android où la résolution
    // d'app externe échoue mais le navigateur intégré fonctionne.
    final openedInApp = await url_launcher.launchUrl(
      url,
      mode: url_launcher.LaunchMode.inAppBrowserView,
    );

    if (!openedInApp) {
      debugPrint('Could not launch $url');
    }
  }
}
