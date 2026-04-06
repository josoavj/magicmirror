import 'package:flutter/material.dart';
import 'package:magicmirror/core/theme/app_colors.dart';
import 'package:magicmirror/features/weather/presentation/widgets/weather_widget.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Météo',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const GlassContainer(
                    padding: EdgeInsets.all(18),
                    child: WeatherWidget(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
