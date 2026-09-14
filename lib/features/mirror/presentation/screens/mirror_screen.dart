import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:magicmirror/core/utils/responsive_helper.dart';
import '../../../../presentation/widgets/glass_container.dart';
import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/mirror_overlay.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const _MirrorBody(),
    );
  }
}

class _MirrorBody extends ConsumerStatefulWidget {
  const _MirrorBody();

  @override
  ConsumerState<_MirrorBody> createState() => _MirrorBodyState();
}

class _MirrorBodyState extends ConsumerState<_MirrorBody> {
  Timer? _hudTimer;
  bool _showMobileHud = true;
  DateTime _hudSessionStartedAt = DateTime.now();
  bool _cameraSessionActive = false;

  @override
  void initState() {
    super.initState();
    _syncHudVisibility(force: true);
    _hudTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncHudVisibility();
    });
  }

  void _syncHudVisibility({bool force = false}) {
    final now = DateTime.now();
    final settings = ref.read(appSettingsProvider);
    final cycleSeconds = (settings.mirrorHudCycleMinutes * 60).clamp(1, 3600);
    final visibleSeconds = settings.mirrorHudDisplaySeconds.clamp(
      1,
      cycleSeconds,
    );

    final initialElapsed = now.difference(_hudSessionStartedAt).inSeconds;
    final shouldShow = initialElapsed < visibleSeconds
        ? true
        : (now.millisecondsSinceEpoch ~/ 1000 % cycleSeconds) < visibleSeconds;

    if (force || shouldShow != _showMobileHud) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showMobileHud = shouldShow;
      });
    }
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frontCameraAsync = ref.watch(frontCameraProvider);
    final morphology = ref.watch(currentMorphologyProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: frontCameraAsync.when(
        data: (camera) {
          if (camera == null) {
            return _buildMirrorLayout(context, null, morphology);
          }

          final controllerAsync = ref.watch(cameraControllerProvider(camera));
          return controllerAsync.when(
            data: (controller) =>
                _buildMirrorLayout(context, controller, morphology),
            loading: () => _buildMirrorLayout(context, null, morphology),
            error: (error, stackTrace) =>
                _buildMirrorLayout(context, null, morphology),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _buildMirrorLayout(context, null, morphology),
      ),
    );
  }

  Widget _buildMirrorLayout(
    BuildContext context,
    dynamic controller,
    dynamic morphology,
  ) {
    final cameraReady = controller != null && controller.value.isInitialized;
    if (cameraReady && !_cameraSessionActive) {
      _cameraSessionActive = true;
      _hudSessionStartedAt = DateTime.now();
      _showMobileHud = true;
    } else if (!cameraReady && _cameraSessionActive) {
      _cameraSessionActive = false;
    }

    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobileHudWidth = (screenWidth * 0.66).clamp(220.0, 320.0);
    final topInset = ResponsiveHelper.resp(context, mobile: 16, tablet: 24);
    final rightInset = ResponsiveHelper.resp(context, mobile: 12, tablet: 24);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Flux Caméra (Background)
        if (cameraReady)
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1.1,
                0,
                0,
                0,
                10,
                0,
                1.1,
                0,
                0,
                10,
                0,
                0,
                1.1,
                0,
                10,
                0,
                0,
                0,
                1.1,
                0,
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

        if (isMobile)
          Positioned(
            top: 14,
            left: 12,
            width: mobileHudWidth,
            child: AnimatedOpacity(
              opacity: _showMobileHud ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showMobileHud,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClockCard(context),
                    const SizedBox(height: 12),
                    const WeatherWidget(),
                    const SizedBox(height: 10),
                    const AgendaHUDWidget(),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Horloge & Date (Haut Centre)
          Positioned(
            top: ResponsiveHelper.resp(context, mobile: 20, tablet: 50),
            left: 0,
            right: 0,
            child: Center(child: _buildClockCard(context)),
          ),

          // Agenda (Haut Gauche)
          Positioned(
            top: ResponsiveHelper.resp(context, mobile: 20, tablet: 50),
            left: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
            width: 280,
            child: const AgendaHUDWidget(),
          ),
        ],

        // Accès rapide paramètres (fréquences HUD + caméra)
        Positioned(
          top: topInset,
          right: rightInset,
          child: _buildQuickSettingsButton(context),
        ),

        // Replacer météo sous le bouton sur grand écran pour éviter le chevauchement
        if (!isMobile)
          Positioned(
            top: topInset + 72,
            right: rightInset,
            child: const WeatherWidget(),
          ),

        // 4. Recommandations Tenues (Bas)
        Positioned(
          bottom: ResponsiveHelper.resp(context, mobile: 20, tablet: 50),
          left: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
          right: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
          child: const OutfitRecommendationWidget(),
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

  Widget _buildClockCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: TextStyle(
              fontSize: ResponsiveHelper.resp(context, mobile: 56, tablet: 80),
              fontWeight: FontWeight.w200,
              color: Colors.white,
            ),
          ),
          Text(
            DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
            style: TextStyle(
              fontSize: ResponsiveHelper.resp(context, mobile: 14, tablet: 20),
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsButton(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 18,
      opacity: 0.12,
      padding: EdgeInsets.zero,
      child: IconButton(
        tooltip: 'Paramètres caméra et HUD',
        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    );
  }
}
