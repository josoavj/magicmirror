import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/screens/outfit_suggestion_screen.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:magicmirror/routes/route_names.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesCount = ref.watch(outfitPr).length;
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
                          onTap: () => Navigator.pushNamed(context, RouteNames.mirror),
                        ),
                        _HomeTile(
                          icon: Icons.calendar_today_rounded,
                          label: isEnglish ? 'Agenda' : 'Agenda',
                          color: Colors.orangeAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.agenda),
                        ),
                        _HomeTile(
                          icon: Icons.person_outline_rounded,
                          label: isEnglish ? 'Profile' : 'Profil',
                          color: Colors.tealAccent,
                          onTap: () => Navigator.pushNamed(context, RouteNames.profile),
                        ),
                        _HomeTile(
                          icon: Icons.checkroom_rounded,
                          label: isEnglish ? 'Outfits' : 'Tenues',
                          color: Colors.deepPurpleAccent,
                          onTap: () => Navigator.pushNamed(
                            context,
                            RouteNames.outfitSuggestion,
                          ),
                        ),
                        _HomeTile(
                          icon: Icons.favorite_rounded,
                          label: isEnglish ? 'Favorites' : 'Favoris',
                          color: Colors.pinkAccent,
                          badgeCount: favoritesCount,
                          onTap: () =>
                              Navigator.pushNamed(context, RouteNames.outfitFavorites),
                        ),
                        _HomeTile(
                          icon: Icons.settings_rounded,
                          label: isEnglish ? 'Settings' : 'Réglages',
                          color: Colors.grey,
                          onTap: () =>
                              Navigator.pushNamed(context, RouteNames.settings),
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
