import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:magicmirror/core/utils/responsive_helper.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import '../../../../presentation/widgets/glass_container.dart';
import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/mirror_overlay.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../weather/presentation/widgets/weather_widget.dart';
import '../../../outfit_suggestion/presentation/widgets/outfit_recommendation_widget.dart';
import '../../../outfit_suggestion/presentation/providers/outfit_provider.dart';
import '../../../ai_ml/presentation/providers/ml_provider.dart';
import '../../../ai_ml/data/models/morphology_model.dart';
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
  ProviderSubscription<MorphologyData?>? _morphologySubscription;
  DateTime? _lastOutfitReadyTtsAt;
  CameraController? _mlController;
  bool _mlStreamStarted = false;

  @override
  void initState() {
    super.initState();
    _syncHudVisibility(force: true);
    _listenOutfitReadyForTts();
    _hudTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncHudVisibility();
    });
  }

  void _listenOutfitReadyForTts() {
    _morphologySubscription = ref.listenManual<MorphologyData?>(
      currentMorphologyProvider,
      (previous, next) {
        if (!mounted || next == null) {
          return;
        }

        final wasReady = previous != null && _isOutfitReadySignal(previous);
        final isReady = _isOutfitReadySignal(next);
        if (!isReady || wasReady) {
          return;
        }

        final now = DateTime.now();
        if (_lastOutfitReadyTtsAt != null &&
            now.difference(_lastOutfitReadyTtsAt!) <
                const Duration(seconds: 45)) {
          return;
        }

        _lastOutfitReadyTtsAt = now;
        _announceOutfitReadyTts();
      },
    );
  }

  Future<void> _announceOutfitReadyTts() async {
    final tts = ref.read(ttsServiceProvider);
    final suggestions = ref.read(suggestedOutfitsProvider);
    if (suggestions.isNotEmpty) {
      final top = suggestions.first;
      await tts.speak(
        'Corps complet detecte. Tenue recommandee: ${top.title}. ${top.reason}',
      );
      return;
    }

    await tts.speak(
      'Corps complet detecte. Vos suggestions de tenues sont pretes.',
    );
  }

  bool _isOutfitReadySignal(MorphologyData data) {
    final heightEstimate = _tryParseDouble(
      data.measurements['height_estimate'],
    );
    final poseQuality = _tryParseDouble(data.measurements['pose_quality']);
    return heightEstimate > 0 && poseQuality >= 60 && data.confidence >= 55;
  }

  double _tryParseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(
          value.toString().replaceAll('%', '').replaceAll(',', '.').trim(),
        ) ??
        0;
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
    _morphologySubscription?.close();
    _stopMlStream();
    super.dispose();
  }

  Future<void> _ensureMlStream(
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (!mounted) {
      return;
    }

    if (_mlController == controller && controller.value.isStreamingImages) {
      if (!_mlStreamStarted) {
        setState(() {
          _mlStreamStarted = true;
        });
      }
      return;
    }

    if (_mlController != null && _mlController != controller) {
      await _stopMlStream();
    }

    try {
      final processor = ref.read(mlFrameProcessorProvider(camera));
      await controller.startImageStream((CameraImage image) {
        unawaited(processor.processCameraFrame(image));
      });
      _mlController = controller;
      if (mounted) {
        setState(() {
          _mlStreamStarted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mlStreamStarted = false;
        });
      }
    }
  }

  Future<void> _stopMlStream() async {
    final controller = _mlController;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {
        // Le controller peut deja etre en cours de dispose; pas bloquant.
      }
    }
    _mlController = null;
    if (mounted && _mlStreamStarted) {
      setState(() {
        _mlStreamStarted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final frontCameraAsync = ref.watch(frontCameraProvider);
    final morphology = ref.watch(currentMorphologyProvider);
    final isMlProcessing = ref.watch(isMlProcessingProvider);
    final mlRuntimeError = ref.watch(mlRuntimeErrorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: frontCameraAsync.when(
        data: (camera) {
          if (camera == null) {
            return _buildMirrorLayout(
              context,
              null,
              morphology,
              isMlProcessing: isMlProcessing,
              mlRuntimeError: mlRuntimeError,
            );
          }

          final controllerAsync = ref.watch(cameraControllerProvider(camera));
          return controllerAsync.when(
            data: (controller) {
              if (controller != null) {
                unawaited(_ensureMlStream(controller, camera));
              } else {
                unawaited(_stopMlStream());
              }
              return _buildMirrorLayout(
                context,
                controller,
                morphology,
                isMlProcessing: isMlProcessing,
                mlRuntimeError: mlRuntimeError,
              );
            },
            loading: () => _buildMirrorLayout(
              context,
              null,
              morphology,
              isMlProcessing: isMlProcessing,
              mlRuntimeError: mlRuntimeError,
            ),
            error: (error, stackTrace) => _buildMirrorLayout(
              context,
              null,
              morphology,
              isMlProcessing: isMlProcessing,
              mlRuntimeError: mlRuntimeError,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildMirrorLayout(
          context,
          null,
          morphology,
          isMlProcessing: isMlProcessing,
          mlRuntimeError: mlRuntimeError,
        ),
      ),
    );
  }

  Widget _buildMirrorLayout(
    BuildContext context,
    dynamic controller,
    dynamic morphology, {
    required bool isMlProcessing,
    required String? mlRuntimeError,
  }) {
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
    final morphologyData = morphology is MorphologyData ? morphology : null;
    final showOutfitReadyBadge =
        morphologyData != null && _isOutfitReadySignal(morphologyData);

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

        Positioned(
          top: topInset + 4,
          right: rightInset + 58,
          child: _buildRuntimeStatusBadge(
            cameraReady: cameraReady,
            isMlProcessing: isMlProcessing,
          ),
        ),

        if (mlRuntimeError != null)
          Positioned(
            top: topInset + 38,
            right: rightInset + 58,
            child: _buildMlErrorBadge(mlRuntimeError),
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
          child: const OutfitRecommendationWidget(enableTts: false),
        ),

        if (showOutfitReadyBadge)
          Positioned(
            bottom: ResponsiveHelper.resp(context, mobile: 108, tablet: 142),
            left: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
            right: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
            child: _buildOutfitReadyBadge(context),
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

  Widget _buildOutfitReadyBadge(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/outfit-suggestion'),
        child: GlassContainer(
          borderRadius: 18,
          blur: 18,
          opacity: 0.18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
              SizedBox(width: 8),
              Text(
                'Corps complet detecte - Tenues pretes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuntimeStatusBadge({
    required bool cameraReady,
    required bool isMlProcessing,
  }) {
    final statusText = !cameraReady
        ? 'Camera inactive'
        : isMlProcessing
        ? 'IA en analyse'
        : _mlStreamStarted
        ? 'IA active'
        : 'IA en attente';
    final statusColor = !cameraReady
        ? Colors.redAccent
        : isMlProcessing
        ? const Color(0xFF22C55E)
        : _mlStreamStarted
        ? const Color(0xFF38BDF8)
        : Colors.amberAccent;

    return GlassContainer(
      borderRadius: 14,
      blur: 16,
      opacity: 0.14,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMlErrorBadge(String message) {
    return GlassContainer(
      borderRadius: 12,
      blur: 14,
      opacity: 0.18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 15),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
