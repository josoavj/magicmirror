import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/camera_view.dart';
import '../widgets/mirror_overlay.dart';
import '../widgets/permission_request_widget.dart';
import '../../../../core/constants/colors.dart';

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  String? _detectedMorphology;
  double? _confidence;

  @override
  Widget build(BuildContext context) {
    // Check if all required permissions are granted
    final allPermissionsGranted = ref.watch(allPermissionsGrantedProvider);

    return allPermissionsGranted.when(
      data: (granted) {
        if (!granted) {
          return PermissionRequestWidget(
            title: 'Permission Caméra Requise',
            message:
                'L\'application a besoin d\'accéder à votre caméra pour fonctionner correctement.',
            permissionType: 'camera',
            child: const SizedBox(),
          );
        }

        return _buildMirrorContent();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $error'))),
    );
  }

  Widget _buildMirrorContent() {
    final frontCamera = ref.watch(frontCameraProvider);
    final isRecording = ref.watch(isRecordingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Miroir Intelligent'), elevation: 0),
      body: frontCamera.when(
        data: (camera) {
          if (camera == null) {
            return const Center(
              child: Text('Aucune caméra frontale disponible'),
            );
          }

          final cameraController = ref.watch(cameraControllerProvider(camera));

          return cameraController.when(
            data: (controller) {
              return Stack(
                children: [
                  // Camera View
                  CameraView(
                    controller: controller,
                    onCapturePressed: () async {
                      // Simulate morphology detection
                      setState(() {
                        _detectedMorphology = 'Sablier';
                        _confidence = 0.92;
                      });

                      // Take picture
                      try {
                        final image = await controller.takePicture();
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Photo capturée: ${image.path}'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                      }
                    },
                  ),

                  // Mirror Overlay
                  MirrorOverlay(
                    morphologyType: _detectedMorphology,
                    confidence: _confidence,
                  ),

                  // Bottom Controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Record Button
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: isRecording
                                ? AppColors.error
                                : AppColors.secondary,
                            onPressed: () {
                              ref.read(isRecordingProvider.notifier).state =
                                  !isRecording;

                              if (isRecording) {
                                controller.stopVideoRecording();
                              } else {
                                controller.startVideoRecording();
                              }
                            },
                            child: Icon(
                              isRecording ? Icons.stop : Icons.circle,
                              color: Colors.white,
                            ),
                          ),

                          // Settings Button
                          FloatingActionButton(
                            mini: true,
                            backgroundColor: AppColors.accent,
                            onPressed: () {
                              // Navigate to settings
                            },
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
