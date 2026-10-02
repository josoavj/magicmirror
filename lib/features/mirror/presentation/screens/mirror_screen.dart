import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:magicmirror/features/mirror/presentation/widgets/permission_request_widget.dart';
import 'package:magicmirror/features/mirror/presentation/services/mirror_readiness_announcer.dart';
import 'package:magicmirror/core/utils/platform_helper.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorScreen extends ConsumerWidget {
  const MirrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync = ref.watch(allPermissionsGrantedProvider);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return permissionsAsync.when(
      data: (granted) => granted
          ? const _MirrorBody()
          : Scaffold(
              backgroundColor: Colors.black,
              body: PermissionRequestWidget(
                title: isEnglish
                    ? 'Camera permission required'
                    : 'Permission caméra requise',
                message: isEnglish
                    ? 'Allow camera access to use the mirror.'
                    : 'Autorisez l’accès à la caméra pour utiliser le miroir.',
                permissionType: 'camera',
                child: const SizedBox.shrink(),
              ),
            ),
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEnglish
                    ? 'Camera permission status could not be checked.'
                    : 'Impossible de vérifier la permission caméra.',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(allPermissionsGrantedProvider),
                icon: const Icon(Icons.refresh),
                label: Text(isEnglish ? 'Retry' : 'Réessayer'),
              ),
            ],
          ),
        ),
      ),
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
  bool _mlStreamStarting = false;
  CameraController? _lastConfiguredController;
  double? _minZoomLevel;
  double? _maxZoomLevel;
  double? _minExposureOffset;
  double? _maxExposureOffset;
  late final MirrorReadinessAnnouncer _readinessAnnouncer;

  String _tr(String french, String english) =>
      Localizations.localeOf(context).languageCode == 'en' ? english : french;

  @override
  void initState() {
    super.initState();
    _readinessAnnouncer = MirrorReadinessAnnouncer(
      ref: ref,
      context: context,
      isMounted: () => mounted,
    )..start();
    unawaited(_enterMirrorImmersiveMode());
  }

  @override
  void dispose() {
    _readinessAnnouncer.dispose();
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
    if (PlatformHelper.isWeb) {
      if (_mlStreamStarted && mounted) {
        setState(() => _mlStreamStarted = false);
      }
      return;
    }
    if (_mlStreamStarting) return;
    if (_mlController == controller && controller.value.isStreamingImages) {
      if (!_mlStreamStarted) setState(() => _mlStreamStarted = true);
      return;
    }

    _mlStreamStarting = true;
    try {
      if (_mlController != null && _mlController != controller) {
        await _stopMlStream();
      }
      final processor = ref.read(mlFrameProcessorProvider(camera));
      await controller.startImageStream((CameraImage image) {
        unawaited(processor.processCameraFrame(image));
      });
      _mlController = controller;
      if (mounted) setState(() => _mlStreamStarted = true);
    } catch (_) {
      if (mounted) setState(() => _mlStreamStarted = false);
    } finally {
      _mlStreamStarting = false;
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
    final trackingRect = _readinessAnnouncer.extractTrackingRect(morphology);

    return Scaffold(
      backgroundColor: Colors.black,
      body: cameraDescAsync.when(
        data: (camera) {
          if (camera == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off, color: Colors.white70, size: 44),
                  SizedBox(height: 12),
                  Text(
                    _tr(
                      'Aucune caméra n’a été détectée.',
                      'No camera was detected.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  _RetryCameraButton(),
                ],
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
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                            size: 44,
                          ),
                          SizedBox(height: 12),
                          Text(
                            _tr(
                              'La caméra n’a pas pu démarrer. Vérifiez son accès et réessayez.',
                              'The camera could not start. Check camera access and try again.',
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          _RetryCameraButton(camera: camera),
                        ],
                      ),
                    );
                  }
                  _configureCamera(controller);
                  if (controller.value.isInitialized) {
                    _ensureMlStream(controller, camera);
                    return CameraView(
                      controller: controller,
                      showCaptureButton: false,
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userFacingError(
                          context,
                          e,
                          frenchFallback:
                              'La caméra n’a pas pu démarrer. Vérifiez son accès et réessayez.',
                          englishFallback:
                              'The camera could not start. Check camera access and try again.',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      _RetryCameraButton(camera: camera),
                    ],
                  ),
                ),
              ),
              if (trackingRect != null)
                IgnorePointer(
                  child: CustomPaint(
                    painter: BodyTrackingPainter(normalizedRect: trackingRect),
                  ),
                ),
              MirrorOverlay(
                compact: true,
                mlSupported: !PlatformHelper.isWeb,
                morphologyType: morphology?.bodyType,
                confidence: morphology?.confidence,
                measurements: morphology?.measurements,
              ),
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
                                  cameraReady: controllerAsync.maybeWhen(
                                    data: (controller) =>
                                        controller?.value.isInitialized ??
                                        false,
                                    orElse: () => false,
                                  ),
                                  mlStreamStarted: _mlStreamStarted,
                                  mlSupported: !PlatformHelper.isWeb,
                                ),
                                const SizedBox(height: 8),
                                _buildQuickSettingsButton(),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_readinessAnnouncer.isReady(morphology))
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
        error: (e, s) => Center(
          child: Text(
            _tr(
              'Les réglages de la caméra n’ont pas pu être chargés.',
              'Camera settings could not be loaded.',
            ),
          ),
        ),
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

class _RetryCameraButton extends ConsumerWidget {
  final CameraDescription? camera;

  const _RetryCameraButton({this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: () {
      ref.invalidate(availableCamerasProvider);
      ref.invalidate(frontCameraProvider);
      if (camera != null) ref.invalidate(cameraControllerProvider(camera!));
    },
    icon: const Icon(Icons.refresh),
    label: const Text('Réessayer'),
  );
}
