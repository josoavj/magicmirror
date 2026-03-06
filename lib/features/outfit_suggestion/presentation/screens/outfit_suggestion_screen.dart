import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../presentation/widgets/glass_container.dart';

class OutfitSuggestionScreen extends ConsumerWidget {
  const OutfitSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Suggestions de Tenue'),
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
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Recommandations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggestions personnalisées basées sur vos préférences',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Outfit Cards
                ..._buildOutfitCards(),

                const SizedBox(height: 24),

                // Méteo actuelle
                _buildWeatherSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOutfitCards() {
    final outfits = [
      {
        'title': 'Casual Moderne',
        'description': 'Jeans + T-shirt léger',
        'icon': Icons.checkroom,
        'color': 0xFF3B82F6,
      },
      {
        'title': 'Élégant',
        'description': 'Chemise + Pantalon chino',
        'icon': Icons.style,
        'color': 0xFF8B5CF6,
      },
      {
        'title': 'Sport',
        'description': 'Legging + Hoodie',
        'icon': Icons.sports,
        'color': 0xFF10B981,
      },
      {
        'title': 'Décontracté',
        'description': 'Sweat + Jogging',
        'icon': Icons.dashboard,
        'color': 0xFFEC4899,
      },
    ];

    return outfits.map((outfit) => _buildOutfitCard(outfit)).toList();
  }

  Widget _buildOutfitCard(Map<String, dynamic> outfit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 20,
        blur: 25,
        opacity: 0.1,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(outfit['color'] as int),
                    Color(outfit['color'] as int).withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  outfit['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outfit['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outfit['description'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return GlassContainer(
      borderRadius: 20,
      blur: 25,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conditions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.cloud_queue,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherStat('Temp', '22°C'),
              _buildWeatherStat('Humidité', '65%'),
              _buildWeatherStat('Vent', '12 km/h'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
