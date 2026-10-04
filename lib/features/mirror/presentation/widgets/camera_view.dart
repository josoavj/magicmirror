import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraView extends StatelessWidget {
  final CameraController controller;
  final VoidCallback? onCapturePressed;
  final bool isFlipped;
  final bool showCaptureButton;

  const CameraView({
    super.key,
    required this.controller,
    this.onCapturePressed,
    this.isFlipped = true,
    this.showCaptureButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview - Centré et plein écran sans déformation
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            if (screenWidth <= 0 || screenHeight <= 0) {
              return const SizedBox.shrink();
            }

            double cameraAspectRatio = controller.value.aspectRatio;
            final isPortrait =
                MediaQuery.of(context).orientation == Orientation.portrait;

            // Correction du ratio d'aspect selon l'orientation
            if (isPortrait && cameraAspectRatio > 1) {
              cameraAspectRatio = 1 / cameraAspectRatio;
            } else if (!isPortrait && cameraAspectRatio < 1) {
              cameraAspectRatio = 1 / cameraAspectRatio;
            }

            final screenAspectRatio = screenWidth / screenHeight;

            // Calcul du facteur d'échelle pour remplir l'écran sans étirer/déformer
            double scale = screenAspectRatio > cameraAspectRatio
                ? screenAspectRatio / cameraAspectRatio
                : cameraAspectRatio / screenAspectRatio;
            if (scale < 1.0) scale = 1.0;

            return ClipRect(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  (isFlipped ? -1.0 : 1.0) * scale,
                  scale,
                  1.0,
                ),
                child: Center(
                  child: CameraPreview(controller),
                ),
              ),
            );
          },
        ),

        if (showCaptureButton)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCapturePressed,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
