import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ml_provider.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/core/utils/platform_helper.dart';

/// Widget pour afficher l'aperçu caméra avec traitement ML en temps réel
class CameraPreviewWidget extends ConsumerStatefulWidget {
  const CameraPreviewWidget({super.key});

  @override
  ConsumerState<CameraPreviewWidget> createState() =>
      _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends ConsumerState<CameraPreviewWidget> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        logger.warning('Aucune caméra disponible', tag: 'CameraPreviewWidget');
        return;
      }

      // Utilise la première caméra (frontale pour Magic Mirror)
      final camera = cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            PlatformHelper.isAndroid
                ? ImageFormatGroup.yuv420
                : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      if (!mounted) return;

      // Sur le Web, on ne démarre pas le stream d'images car google_ml_kit n'est pas supporté
      if (!PlatformHelper.isWeb) {
        final processor = ref.read(mlFrameProcessorProvider(camera));
        await _controller!.startImageStream((CameraImage image) {
          processor.processCameraFrame(image);
        });
      }

      setState(() => _isInitialized = true);

      logger.info(
        'Caméra initialisée et flux démarré',
        tag: 'CameraPreviewWidget',
      );
    } catch (e) {
      logger.error(
        'Erreur initialisation caméra',
        tag: 'CameraPreviewWidget',
        error: e,
      );
    }
  }

  @override
  void dispose() {
    try {
      if (!PlatformHelper.isWeb) {
        _controller?.stopImageStream();
      }
    } catch (_) {}
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        !_isInitialized ||
        !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_controller!);
  }
}
