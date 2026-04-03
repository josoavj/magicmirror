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
    this.isFlipped = false,
    this.showCaptureButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera Preview
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(isFlipped ? -1.0 : 1.0, 1.0, 1.0),
          child: CameraPreview(controller),
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
