import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
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

class _BodyTrackingFramePainter extends CustomPainter {
  final Rect normalizedRect;

  const _BodyTrackingFramePainter({required this.normalizedRect});

  @override
  void paint(Canvas canvas, Size size) {
    final safeLeft = normalizedRect.left.clamp(0.0, 1.0);
    final safeTop = normalizedRect.top.clamp(0.0, 1.0);
    final safeWidth = normalizedRect.width.clamp(0.05, 1.0);
    final safeHeight = normalizedRect.height.clamp(0.05, 1.0);

    final drawRect = Rect.fromLTWH(
      safeLeft * size.width,
      safeTop * size.height,
      safeWidth * size.width,
      safeHeight * size.height,
    );

    final border = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final glow = Paint()
      ..color = const Color(0x8022C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final rrect = RRect.fromRectAndRadius(drawRect, const Radius.circular(12));
    canvas.drawRRect(rrect, glow);
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(covariant _BodyTrackingFramePainter oldDelegate) {
    return oldDelegate.normalizedRect != normalizedRect;
  }
}

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
  Timer? _cameraControlsTimer;
  Timer? _resetCameraBadgeTimer;
  bool _showMobileHud = true;
  bool _showCameraControls = false;
  bool _showExposureControl = false;
  bool _showResetCameraBadge = false;
  DateTime _hudSessionStartedAt = DateTime.now();
  bool _cameraSessionActive = false;
  ProviderSubscription<MorphologyData?>? _morphologySubscription;
  DateTime? _lastOutfitReadyTtsAt;
  CameraController? _mlController;
  bool _mlStreamStarted = false;
  CameraController? _lastConfiguredController;
  double? _minZoomLevel;
  double? _maxZoomLevel;
  double? _minExposureOffset;
  double? _maxExposureOffset;
  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  double _gestureStartZoom = 1.0;
  DateTime? _lastHapticAt;
  double? _lastAppliedZoom;
  double? _lastAppliedExposure;
  String? _lastAppliedFlashMode;
  bool _zoomUnsupported = false;
  bool _exposureUnsupported = false;
  bool _flashUnsupported = false;

  String? _cameraPreferenceWarning(AppLocalizations? l10n) {
    final unsupported = <String>[];
    if (_zoomUnsupported) unsupported.add(l10n?.unsupportedZoom ?? 'zoom');
    if (_exposureUnsupported) {
      unsupported.add(l10n?.unsupportedExposure ?? 'exposition');
    }
    if (_flashUnsupported) unsupported.add(l10n?.unsupportedFlash ?? 'flash');
    if (unsupported.isEmpty) return null;
    return l10n?.unsupportedSettings(unsupported.join(', ')) ??
        'Réglages non supportés: ${unsupported.join(', ')}';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_enterMirrorImmersiveMode());
    _syncHudVisibility(force: true);
    _listenOutfitReadyForTts();
    _hudTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncHudVisibility();
    });
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
        _announceOutfitReadyTts(next);
      },
    );
  }

  Future<void> _announceOutfitReadyTts(MorphologyData morphologyData) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final settings = ref.read(appSettingsProvider);
    final tts = ref.read(ttsServiceProvider);
    final suggestions = ref.read(suggestedOutfitsProvider);
    final isEnglish = settings.ttsLanguage.startsWith('en');
    final includeMorphology = settings.ttsAnnounceMorphology;
    final morphologyMessage = includeMorphology
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

  Rect? _extractTrackingRect(MorphologyData? morphologyData) {
    if (morphologyData == null) {
      return null;
    }

    final measurements = morphologyData.measurements;
    final left = _tryParseDouble(measurements['bbox_left_n']);
    final top = _tryParseDouble(measurements['bbox_top_n']);
    final width = _tryParseDouble(measurements['bbox_width_n']);
    final height = _tryParseDouble(measurements['bbox_height_n']);

    if (width <= 0 || height <= 0) {
      return null;
    }

    return Rect.fromLTWH(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      width.clamp(0.05, 1.0),
      height.clamp(0.05, 1.0),
    );
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
    _cameraControlsTimer?.cancel();
    _resetCameraBadgeTimer?.cancel();
    _morphologySubscription?.close();
    unawaited(_restoreSystemBars());
    _stopMlStream();
    super.dispose();
  }

  void _showResetFeedbackBadge() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showResetCameraBadge = true;
    });
    _resetCameraBadgeTimer?.cancel();
    _resetCameraBadgeTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showResetCameraBadge = false;
      });
    });
  }

  void _showCameraControlsTemporarily({bool withExposure = false}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _showCameraControls = true;
      if (withExposure) {
        _showExposureControl = true;
      }
    });
    _cameraControlsTimer?.cancel();
    _cameraControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showCameraControls = false;
        _showExposureControl = false;
      });
    });
  }

  Future<void> _setZoomLevel(double rawZoom) async {
    final minZoom = _minZoomLevel ?? 1.0;
    final maxZoom = _maxZoomLevel ?? 1.0;
    final clampedZoom = rawZoom.clamp(minZoom, maxZoom).toDouble();

    if (mounted) {
      setState(() {
        _currentZoomLevel = clampedZoom;
      });
    }

    if (_zoomUnsupported) {
      return;
    }

    try {
      await _lastConfiguredController?.setZoomLevel(clampedZoom);
      _lastAppliedZoom = clampedZoom;
    } catch (_) {
      if (!mounted || _zoomUnsupported) {
        return;
      }
      setState(() {
        _zoomUnsupported = true;
      });
    }
  }

  Future<void> _setExposureOffset(double rawOffset) async {
    final minExposure = _minExposureOffset ?? 0.0;
    final maxExposure = _maxExposureOffset ?? 0.0;
    final clampedOffset = rawOffset.clamp(minExposure, maxExposure).toDouble();

    if (mounted) {
      setState(() {
        _currentExposureOffset = clampedOffset;
      });
    }

    if (_exposureUnsupported) {
      return;
    }

    try {
      await _lastConfiguredController?.setExposureOffset(clampedOffset);
      _lastAppliedExposure = clampedOffset;
    } catch (_) {
      if (!mounted || _exposureUnsupported) {
        return;
      }
      setState(() {
        _exposureUnsupported = true;
      });
    }
  }

  void _lightHaptic({Duration minInterval = const Duration(milliseconds: 80)}) {
    final now = DateTime.now();
    if (_lastHapticAt != null && now.difference(_lastHapticAt!) < minInterval) {
      return;
    }
    _lastHapticAt = now;
    unawaited(HapticFeedback.lightImpact());
  }

  Future<void> _resetCameraAdjustments() async {
    _showCameraControlsTemporarily(withExposure: true);
    _lightHaptic(minInterval: const Duration(milliseconds: 20));
    _showResetFeedbackBadge();
    await _setZoomLevel(1.0);
    await _setExposureOffset(0.0);
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
        // Le contrôleur peut déjà être en cours de dispose; pas bloquant.
      }
    }
    _mlController = null;
    if (mounted && _mlStreamStarted) {
      setState(() {
        _mlStreamStarted = false;
      });
    }
  }

  Future<void> _applyCameraPreferences(
    CameraController controller,
    dynamic settings,
  ) async {
    if (!controller.value.isInitialized) {
      return;
    }

    if (_lastConfiguredController != controller) {
      _lastConfiguredController = controller;
      _lastAppliedZoom = null;
      _lastAppliedExposure = null;
      _lastAppliedFlashMode = null;
      _zoomUnsupported = false;
      _exposureUnsupported = false;
      _flashUnsupported = false;
      try {
        _minZoomLevel = await controller.getMinZoomLevel();
        _maxZoomLevel = await controller.getMaxZoomLevel();
      } catch (_) {
        _minZoomLevel = 1.0;
        _maxZoomLevel = 1.0;
      }
      try {
        _minExposureOffset = await controller.getMinExposureOffset();
        _maxExposureOffset = await controller.getMaxExposureOffset();
      } catch (_) {
        _minExposureOffset = 0.0;
        _maxExposureOffset = 0.0;
      }

      _currentZoomLevel = _currentZoomLevel.clamp(
        _minZoomLevel ?? 1.0,
        _maxZoomLevel ?? 1.0,
      );
      _currentExposureOffset = _currentExposureOffset.clamp(
        _minExposureOffset ?? 0.0,
        _maxExposureOffset ?? 0.0,
      );
    }

    final minZoom = _minZoomLevel ?? 1.0;
    final maxZoom = _maxZoomLevel ?? 1.0;
    final targetZoom = _currentZoomLevel.clamp(minZoom, maxZoom).toDouble();
    if (_lastAppliedZoom == null ||
        (_lastAppliedZoom! - targetZoom).abs() > 0.01) {
      try {
        await controller.setZoomLevel(targetZoom);
        _lastAppliedZoom = targetZoom;
        if (_zoomUnsupported && mounted) {
          setState(() {
            _zoomUnsupported = false;
          });
        }
      } catch (_) {
        if (!_zoomUnsupported && mounted) {
          setState(() {
            _zoomUnsupported = true;
          });
        }
      }
    }

    final minExposure = _minExposureOffset ?? 0.0;
    final maxExposure = _maxExposureOffset ?? 0.0;
    final targetExposure = _currentExposureOffset
        .clamp(minExposure, maxExposure)
        .toDouble();
    if (_lastAppliedExposure == null ||
        (_lastAppliedExposure! - targetExposure).abs() > 0.01) {
      try {
        await controller.setExposureOffset(targetExposure);
        _lastAppliedExposure = targetExposure;
        if (_exposureUnsupported && mounted) {
          setState(() {
            _exposureUnsupported = false;
          });
        }
      } catch (_) {
        if (!_exposureUnsupported && mounted) {
          setState(() {
            _exposureUnsupported = true;
          });
        }
      }
    }

    final targetFlashMode = settings.cameraFlashMode as String;
    if (_lastAppliedFlashMode != targetFlashMode) {
      try {
        final flashMode = switch (targetFlashMode) {
          'auto' => FlashMode.auto,
          'always' => FlashMode.always,
          'torch' => FlashMode.torch,
          _ => FlashMode.off,
        };
        await controller.setFlashMode(flashMode);
        _lastAppliedFlashMode = targetFlashMode;
        if (_flashUnsupported && mounted) {
          setState(() {
            _flashUnsupported = false;
          });
        }
      } catch (_) {
        if (!_flashUnsupported && mounted) {
          setState(() {
            _flashUnsupported = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frontCameraAsync = ref.watch(frontCameraProvider);
    final morphology = ref.watch(currentMorphologyProvider);
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
              mlRuntimeError: mlRuntimeError,
            );
          }

          final controllerAsync = ref.watch(cameraControllerProvider(camera));
          return controllerAsync.when(
            data: (controller) {
              if (controller != null) {
                unawaited(_ensureMlStream(controller, camera));
                final settings = ref.read(appSettingsProvider);
                final needsPreferenceUpdate =
                    _lastConfiguredController != controller ||
                    _lastAppliedFlashMode != settings.cameraFlashMode;
                if (needsPreferenceUpdate) {
                  unawaited(_applyCameraPreferences(controller, settings));
                }
              } else {
                unawaited(_stopMlStream());
              }
              return _buildMirrorLayout(
                context,
                controller,
                morphology,
                mlRuntimeError: mlRuntimeError,
              );
            },
            loading: () => _buildMirrorLayout(
              context,
              null,
              morphology,
              mlRuntimeError: mlRuntimeError,
            ),
            error: (error, stackTrace) => _buildMirrorLayout(
              context,
              null,
              morphology,
              mlRuntimeError: mlRuntimeError,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildMirrorLayout(
          context,
          null,
          morphology,
          mlRuntimeError: mlRuntimeError,
        ),
      ),
    );
  }

  Widget _buildMirrorLayout(
    BuildContext context,
    dynamic controller,
    dynamic morphology, {
    required String? mlRuntimeError,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final cameraPreferenceWarning = _cameraPreferenceWarning(l10n);
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
    final appSettings = ref.watch(appSettingsProvider);
    final morphologyData = morphology is MorphologyData ? morphology : null;
    final showOutfitReadyBadge =
        morphologyData != null && _isOutfitReadySignal(morphologyData);
    final morphologyOverlayTop = topInset + 56;
    final trackingRect = _extractTrackingRect(morphologyData);

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
              child: CameraView(
                controller: controller,
                isFlipped: appSettings.cameraFlipped,
                showCaptureButton: false,
              ),
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

        if (trackingRect != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BodyTrackingFramePainter(
                  normalizedRect: trackingRect,
                ),
              ),
            ),
          ),

        if (cameraReady)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: (_) {
                _gestureStartZoom = _currentZoomLevel;
                _showCameraControlsTemporarily();
                _lightHaptic(minInterval: const Duration(milliseconds: 160));
              },
              onScaleUpdate: (details) {
                final targetZoom = _gestureStartZoom * details.scale;
                unawaited(_setZoomLevel(targetZoom));
              },
              onDoubleTap: () {
                unawaited(_resetCameraAdjustments());
              },
            ),
          ),

        // Overlay morphologie compact sous le bouton paramètres
        if (morphology != null)
          Positioned(
            top: morphologyOverlayTop,
            right: rightInset,
            child: SizedBox(
              width: ResponsiveHelper.resp(context, mobile: 220, tablet: 260),
              child: Transform.scale(
                scale: 0.9,
                alignment: Alignment.topRight,
                child: MirrorOverlay(
                  morphologyType: morphology.bodyType,
                  confidence: morphology.confidence,
                  measurements: morphology.measurements,
                  compact: true,
                ),
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
                    const SizedBox(height: 10),
                    const OutfitRecommendationWidget(enableTts: false),
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
            width: 320,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AgendaHUDWidget(),
                SizedBox(height: 12),
                OutfitRecommendationWidget(enableTts: false),
              ],
            ),
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
          child: _buildRuntimeStatusBadge(cameraReady: cameraReady),
        ),

        if (mlRuntimeError != null)
          Positioned(
            top: topInset + 38,
            right: rightInset + 58,
            child: _buildMlErrorBadge(mlRuntimeError),
          ),

        if (cameraPreferenceWarning != null)
          Positioned(
            top: topInset + 72,
            right: rightInset + 58,
            child: _buildCameraPreferenceWarningBadge(cameraPreferenceWarning),
          ),

        if (cameraReady)
          Positioned(
            right: rightInset,
            bottom: ResponsiveHelper.resp(context, mobile: 24, tablet: 36),
            child: _buildCameraControls(),
          ),

        // Replacer météo sous le bouton sur grand écran pour éviter le chevauchement
        if (!isMobile)
          Positioned(
            top: cameraPreferenceWarning != null
                ? topInset + 106
                : topInset + 72,
            right: rightInset,
            child: const WeatherWidget(),
          ),

        if (showOutfitReadyBadge)
          Positioned(
            bottom: ResponsiveHelper.resp(context, mobile: 108, tablet: 142),
            left: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
            right: ResponsiveHelper.resp(context, mobile: 15, tablet: 30),
            child: _buildOutfitReadyBadge(context),
          ),
      ],
    );
  }

  Widget _buildCameraControls() {
    final minZoom = _minZoomLevel ?? 1.0;
    final maxZoom = _maxZoomLevel ?? 1.0;
    final minExposure = _minExposureOffset ?? 0.0;
    final maxExposure = _maxExposureOffset ?? 0.0;
    final zoomPresets = <double>[
      0.5,
      1.0,
      2.0,
      3.0,
      4.0,
    ].where((value) => value >= minZoom && value <= maxZoom).toList();

    final canControlZoom = !_zoomUnsupported && maxZoom > minZoom + 0.01;
    final canControlExposure =
        !_exposureUnsupported && maxExposure > minExposure + 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSlide(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          offset: _showResetCameraBadge ? Offset.zero : const Offset(0.15, 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showResetCameraBadge ? 1 : 0,
            child: IgnorePointer(
              ignoring: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  borderRadius: 14,
                  blur: 16,
                  opacity: 0.2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF38BDF8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.cameraResetBadge ??
                            'Reset camera',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSlide(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          offset: _showCameraControls ? Offset.zero : const Offset(0.2, 0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showCameraControls ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_showCameraControls,
              child: GlassContainer(
                borderRadius: 18,
                blur: 16,
                opacity: 0.2,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final preset in zoomPresets)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: canControlZoom
                              ? () {
                                  _lightHaptic(
                                    minInterval: const Duration(
                                      milliseconds: 40,
                                    ),
                                  );
                                  _showCameraControlsTemporarily();
                                  unawaited(_setZoomLevel(preset));
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: (_currentZoomLevel - preset).abs() < 0.08
                                  ? const Color(
                                      0xFF38BDF8,
                                    ).withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Text(
                              '${preset.toStringAsFixed(preset < 1 ? 1 : 0)}x',
                              style: TextStyle(
                                color: canControlZoom
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _showExposureControl
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GlassContainer(
                        borderRadius: 16,
                        blur: 18,
                        opacity: 0.2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SizedBox(
                            width: 140,
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                activeTrackColor: const Color(0xFFF59E0B),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: const Color(0xFFFBBF24),
                                overlayColor: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: _currentExposureOffset,
                                min: minExposure,
                                max: maxExposure,
                                onChanged: canControlExposure
                                    ? (value) {
                                        _lightHaptic(
                                          minInterval: const Duration(
                                            milliseconds: 120,
                                          ),
                                        );
                                        _showCameraControlsTemporarily(
                                          withExposure: true,
                                        );
                                        unawaited(_setExposureOffset(value));
                                      }
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassContainer(
                  borderRadius: 18,
                  blur: 16,
                  opacity: 0.22,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    '${_currentZoomLevel.toStringAsFixed(1)}x',
                    style: TextStyle(
                      color: canControlZoom ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  borderRadius: 16,
                  blur: 16,
                  opacity: 0.24,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    tooltip:
                        Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        )?.cameraControlsTooltip ??
                        'Camera controls',
                    icon: Icon(
                      _showCameraControls
                          ? Icons.tune_rounded
                          : Icons.camera_enhance_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      _lightHaptic(
                        minInterval: const Duration(milliseconds: 40),
                      );
                      if (_showCameraControls) {
                        _cameraControlsTimer?.cancel();
                        setState(() {
                          _showCameraControls = false;
                          _showExposureControl = false;
                        });
                      } else {
                        _showCameraControlsTemporarily();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                GlassContainer(
                  borderRadius: 16,
                  blur: 16,
                  opacity: 0.22,
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    tooltip:
                        Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        )?.cameraExposureTooltip ??
                        'Exposure',
                    icon: Icon(
                      _showExposureControl
                          ? Icons.wb_sunny
                          : Icons.wb_sunny_outlined,
                      color: canControlExposure ? Colors.white : Colors.white54,
                      size: 20,
                    ),
                    onPressed: canControlExposure
                        ? () {
                            _lightHaptic(
                              minInterval: const Duration(milliseconds: 40),
                            );
                            _showCameraControlsTemporarily(
                              withExposure: !_showExposureControl,
                            );
                            if (_showExposureControl) {
                              setState(() {
                                _showExposureControl = false;
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
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
            DateFormat(
              'EEEE d MMMM',
              Localizations.localeOf(context).toString(),
            ).format(DateTime.now()),
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
        tooltip:
            Localizations.of<AppLocalizations>(
              context,
              AppLocalizations,
            )?.quickSettingsTooltip ??
            'Camera and HUD settings',
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.outfitReadyBadge ??
                    'Full body detected - Outfits ready',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuntimeStatusBadge({required bool cameraReady}) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final statusText = !cameraReady
        ? (l10n?.runtimeCameraInactive ?? 'Camera inactive')
        : _mlStreamStarted
        ? (l10n?.runtimeAiActive ?? 'AI active')
        : (l10n?.runtimeAiWaiting ?? 'AI waiting');
    final statusColor = !cameraReady
        ? Colors.redAccent
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

  Widget _buildCameraPreferenceWarningBadge(String message) {
    return GlassContainer(
      borderRadius: 12,
      blur: 14,
      opacity: 0.18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amberAccent,
            size: 15,
          ),
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
