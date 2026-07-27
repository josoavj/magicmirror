import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import 'package:magicmirror/features/ai_ml/data/models/morphology_model.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';
import 'package:magicmirror/features/mirror/presentation/providers/camera_provider.dart';
import 'package:magicmirror/features/mirror/presentation/providers/mirror_ui_state.dart';
import 'package:magicmirror/features/mirror/presentation/providers/permission_provider.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/body_tracking_painter.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/camera_view.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/mirror_camera_controls.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/mirror_clock_card.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/mirror_outfit_badge.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/mirror_overlay.dart';
import 'package:magicmirror/features/mirror/presentation/widgets/mirror_status_badge.dart';
import 'package:magicmirror/features/outfit_suggestion/presentation/providers/outfit_provider.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorScreen extends ConsumerWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(allPermissionsGrantedProvider);

    return permissionsAsync.when(
      data: (granted) => const _MirrorBody(),
      loading:
          () => const Scaffold(
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
  CameraController? _mlController;
  bool _mlStreamStarted = false;
  CameraController? _lastConfiguredController;
  double? _minZoomLevel;
  double? _maxZoomLevel;
  double? _minExposureOffset;
  double? _maxExposureOffset;
  DateTime? _lastOutfitReadyTtsAt;
  ProviderSubscription<MorphologyData?>? _morphologySubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_enterMirrorImmersiveMode());
    _listenOutfitReadyForTts();
  }

  @override
  void dispose() {
    _morphologySubscription?.close();
    unawaited(_restoreSystemBars());
    _stopMlStream();
    super.dispose();
  }

  Future<void> _enterMirrorImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: const [],
    );
  }

  Future<void> _restoreSystemBars() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _listenOutfitReadyForTts() {
    _morphologySubscription = ref.listenManual<MorphologyData?>(
      currentMorphologyProvider,
      (previous, next) {
        if (!mounted || next == null) return;

        final wasReady = previous != null && _isOutfitReadySignal(previous);
        final isReady = _isOutfitReadySignal(next);
        if (!isReady || wasReady) return;

        final now = DateTime.now();
        if (_lastOutfitReadyTtsAt != null &&
            now.difference(_lastOutfitReadyTtsAt!) <
                const Duration(seconds: 45)) {
          return;
        }

        _lastOutfitReadyTtsAt = now;
        _announceOutfitReadyTts(next);
      },
    );
  }

  bool _isOutfitReadySignal(MorphologyData? data) {
    if (data == null) return false;
    final heightEstimate = _tryParseDouble(data.measurements['height_estimate']);
    final poseQuality = _tryParseDouble(data.measurements['pose_quality']);
    return heightEstimate > 0 && poseQuality >= 60 && data.confidence >= 55;
  }

  double _tryParseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(
          value.toString().replaceAll('%', '').replaceAll(',', '.').trim(),
        ) ??
        0;
  }

  Future<void> _announceOutfitReadyTts(MorphologyData morphologyData) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final settings = ref.read(appSettingsProvider);
    final tts = ref.read(ttsServiceProvider);
    final suggestions = ref.read(suggestedOutfitsProvider);
    final isEnglish = settings.ttsLanguage.startsWith('en');
    final includeMorphology = settings.ttsAnnounceMorphology;
    final morphologyMessage =
        includeMorphology
            ? (l10n?.detectedBodyType(morphologyData.bodyType) ??
                (isEnglish
                    ? 'Detected body type: ${morphologyData.bodyType}. '
                    : 'Morphologie détectée: ${morphologyData.bodyType}. '))
            : '';

    if (suggestions.isNotEmpty) {
      final top = suggestions.first;
      await tts.speak(
        l10n?.fullBodyDetectedWithOutfit(
              morphologyMessage,
              top.title,
              top.reason,
            ) ??
            (isEnglish
                ? 'Full body detected. ${morphologyMessage}Recommended outfit: ${top.title}. ${top.reason}'
                : 'Corps complet détecté. ${morphologyMessage}Tenue recommandée: ${top.title}. ${top.reason}'),
        enabled: settings.enableAudioFeedback && settings.ttsEnabled,
        interruptCurrent: settings.ttsInterruptCurrent,
        language: settings.ttsLanguage,
        speechRate: settings.ttsSpeechRate,
        pitch: settings.ttsPitch,
        minRepeatInterval: Duration(seconds: settings.ttsMinRepeatSeconds),
      );
      return;
    }

    await tts.speak(
      l10n?.fullBodyDetectedWithoutOutfit(morphologyMessage) ??
          (isEnglish
              ? 'Full body detected. ${morphologyMessage}Your outfit suggestions are ready.'
              : 'Corps complet détecté. ${morphologyMessage}Vos suggestions de tenues sont prêtes.'),
      enabled: settings.enableAudioFeedback && settings.ttsEnabled,
      interruptCurrent: settings.ttsInterruptCurrent,
      language: settings.ttsLanguage,
      speechRate: settings.ttsSpeechRate,
      pitch: settings.ttsPitch,
      minRepeatInterval: Duration(seconds: settings.ttsMinRepeatSeconds),
    );
  }

  Rect? _extractTrackingRect(MorphologyData? morphologyData) {
    if (morphologyData == null) return null;
    final measurements = morphologyData.measurements;
    final left = _tryParseDouble(measurements['bbox_left_n']);
    final top = _tryParseDouble(measurements['bbox_top_n']);
    final width = _tryParseDouble(measurements['bbox_width_n']);
    final height = _tryParseDouble(measurements['bbox_height_n']);

    if (width <= 0 || height <= 0) return null;

    return Rect.fromLTWH(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      width.clamp(0.05, 1.0),
      height.clamp(0.05, 1.0),
    );
  }

  Future<void> _setZoomLevel(double zoom) async {
    final uiNotifier = ref.read(mirrorUIProvider.notifier);
    uiNotifier.setZoomLevel(zoom);
    try {
      await _lastConfiguredController?.setZoomLevel(zoom);
    } catch (_) {
      uiNotifier.setZoomUnsupported(true);
    }
  }

  Future<void> _setExposureOffset(double offset) async {
    final uiNotifier = ref.read(mirrorUIProvider.notifier);
    uiNotifier.setExposureOffset(offset);
    try {
      await _lastConfiguredController?.setExposureOffset(offset);
    } catch (_) {
      uiNotifier.setExposureUnsupported(true);
    }
  }

  Future<void> _ensureMlStream(
    CameraController controller,
    CameraDescription camera,
  ) async {
    if (!mounted) return;
    if (_mlController == controller && controller.value.isStreamingImages) {
      if (!_mlStreamStarted) setState(() => _mlStreamStarted = true);
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
      if (mounted) setState(() => _mlStreamStarted = true);
    } catch (_) {
      if (mounted) setState(() => _mlStreamStarted = false);
    }
  }

  Future<void> _stopMlStream() async {
    final controller = _mlController;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
    _mlController = null;
    if (mounted && _mlStreamStarted) setState(() => _mlStreamStarted = false);
  }

  Future<void> _configureCamera(CameraController controller) async {
    if (!controller.value.isInitialized) return;
    if (_lastConfiguredController == controller) return;

    _lastConfiguredController = controller;
    final uiNotifier = ref.read(mirrorUIProvider.notifier);
    try {
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = await controller.getMaxZoomLevel();
      _minExposureOffset = await controller.getMinExposureOffset();
      _maxExposureOffset = await controller.getMaxExposureOffset();
    } catch (_) {
      uiNotifier.setZoomUnsupported(true);
      uiNotifier.setExposureUnsupported(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraDescAsync = ref.watch(frontCameraProvider);
    final morphology = ref.watch(currentMorphologyProvider);
    final uiState = ref.watch(mirrorUIProvider);
    final trackingRect = _extractTrackingRect(morphology);

    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraDescAsync.when(
        data: (camera) {
          if (camera == null) {
            return const Center(
              child: Text(
                'Pas de caméra détectée',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final controllerAsync = ref.watch(cameraControllerProvider(camera));
          return Stack(
            fit: StackFit.expand,
            children: [
              controllerAsync.when(
                data: (controller) {
                  if (controller == null) {
                    return const Center(child: Text('Erreur initialisation'));
                  }
                  _configureCamera(controller);
                  if (controller.value.isInitialized) {
                    _ensureMlStream(controller, camera);
                    return CameraView(controller: controller);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Erreur Caméra: $e')),
              ),
              if (trackingRect != null)
                IgnorePointer(
                  child: CustomPaint(
                    painter: BodyTrackingPainter(normalizedRect: trackingRect),
                  ),
                ),
              const MirrorOverlay(),
              if (uiState.showMobileHud)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const MirrorClockCard(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MirrorStatusBadge(
                                  cameraReady: controllerAsync.hasValue,
                                  mlStreamStarted: _mlStreamStarted,
                                ),
                                const SizedBox(height: 8),
                                _buildQuickSettingsButton(),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_isOutfitReadySignal(morphology))
                          const MirrorOutfitBadge(),
                        const Spacer(),
                        MirrorCameraControls(
                          minZoom: _minZoomLevel ?? 1.0,
                          maxZoom: _maxZoomLevel ?? 1.0,
                          minExposure: _minExposureOffset ?? 0.0,
                          maxExposure: _maxExposureOffset ?? 0.0,
                          canControlZoom: !uiState.zoomUnsupported,
                          canControlExposure: !uiState.exposureUnsupported,
                          onZoomChanged: _setZoomLevel,
                          onExposureChanged: _setExposureOffset,
                        ),
                      ],
                    ),
                  ),
                ),
              if (uiState.showResetCameraBadge)
                const Center(
                  child: GlassContainer(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Réglages réinitialisés',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur config: $e')),
      ),
    );
  }

  Widget _buildQuickSettingsButton() {
    return GlassContainer(
      borderRadius: 16,
      blur: 18,
      opacity: 0.12,
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
      ),
    );
  }
}
