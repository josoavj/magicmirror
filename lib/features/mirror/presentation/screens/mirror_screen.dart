import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../presentation/widgets/glass_container.dart';
import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/mirror_overlay.dart';
import '../widgets/permission_request_widget.dart';
import '../../../weather/presentation/widgets/weather_widget.dart';
import '../../../outfit_suggestion/presentation/widgets/outfit_recommendation_widget.dart';
import '../../../ai_ml/presentation/providers/ml_provider.dart';
import '../../../agenda/presentation/widgets/agenda_hud_widget.dart';

class MirrorScreen extends ConsumerWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(allPermissionsGrantedProvider);

    return permissionsAsync.when(
      data: (granted) => const _MirrorBody(),
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _MirrorBody(),
    );
  }
}

class _MirrorBody extends ConsumerWidget {
  const _MirrorBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frontCameraAsync = ref.watch(frontCameraProvider);
    final morphology = ref.watch(currentMorphologyProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: frontCameraAsync.when(
        data: (camera) {
          if (camera == null) return _buildMirrorLayout(context, null, morphology);
          
          final controllerAsync = ref.watch(cameraControllerProvider(camera));
          return controllerAsync.when(
            data: (controller) => _buildMirrorLayout(context, controller, morphology),
            loading: () => _buildMirrorLayout(context, null, morphology),
            error: (_, __) => _buildMirrorLayout(context, null, morphology),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildMirrorLayout(context, null, morphology),
      ),
    );
  }

  Widget _buildMirrorLayout(BuildContext context, dynamic controller, dynamic morphology) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Flux Caméra (Background)
        if (controller != null && controller.value.isInitialized)
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1.1, 0, 0, 0, 10,
                0, 1.1, 0, 0, 10,
                0, 0, 1.1, 0, 10,
                0, 0, 0, 1.1, 0,
              ]),
              child: CameraView(controller: controller),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Color(0xFF1a1a2e), Colors.black],
              ),
            ),
          ),

        // 1. Horloge & Date (Haut Centre)
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(DateTime.now()),
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200, color: Colors.white),
                  ),
                  Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
                    style: TextStyle(fontSize: 20, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Météo (Haut Droite)
        const Positioned(top: 50, right: 30, child: WeatherWidget()),

        // 3. AGENDA (Haut Gauche) - NOUVEAU
        const Positioned(
          top: 50,
          left: 30,
          width: 250,
          child: AgendaHUDWidget(),
        ),

        // 4. Recommandations Tenues (Bas)
        const Positioned(
          bottom: 50,
          left: 30,
          right: 30,
          child: OutfitRecommendationWidget(),
        ),

        // Overlay Morphologie
        if (morphology != null)
          MirrorOverlay(
            morphologyType: morphology.bodyType,
            confidence: morphology.confidence,
            measurements: morphology.measurements,
          ),
      ],
    );
  }
}
