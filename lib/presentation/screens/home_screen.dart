import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_suggestion_providers.dart';
import 'package:magicmirror/presentation/widgets/home_tile.dart';
import 'package:magicmirror/routes/route_names.dart';

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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
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
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: isMobile ? 12 : 20,
                      mainAxisSpacing: isMobile ? 12 : 20,
                      children: [
                        HomeTile(
                          icon: Icons.auto_awesome_mosaic,
                          label: isEnglish ? 'Mirror' : 'Miroir',
                          color: Colors.blueAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.mirror),
                        ),
                        HomeTile(
                          icon: Icons.calendar_today_rounded,
                          label: isEnglish ? 'Agenda' : 'Agenda',
                          color: Colors.orangeAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.agenda),
                        ),
                        HomeTile(
                          icon: Icons.person_outline_rounded,
                          label: isEnglish ? 'Profile' : 'Profil',
                          color: Colors.tealAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.profile),
                        ),
                        HomeTile(
                          icon: Icons.checkroom_rounded,
                          label: isEnglish ? 'Outfits' : 'Tenues',
                          color: Colors.deepPurpleAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.outfitSuggestion),
                        ),
                        HomeTile(
                          icon: Icons.favorite_rounded,
                          label: isEnglish ? 'Favorites' : 'Favoris',
                          color: Colors.pinkAccent,
                          badgeCount: favoritesCount,
                          onTap: () => Navigator.pushNamed(context, RouteNames.outfitFavorites),
                        ),
                        HomeTile(
                          icon: Icons.settings_rounded,
                          label: isEnglish ? 'Settings' : 'Réglages',
                          color: Colors.grey,
                          onTap: () => Navigator.pushNamed(context, RouteNames.settings),
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
