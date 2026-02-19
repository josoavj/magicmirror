import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class MirrorOverlay extends StatelessWidget {
  final String? morphologyType;
  final double? confidence;
  final Map<String, dynamic>? measurements;

  const MirrorOverlay({
    super.key,
    this.morphologyType,
    this.confidence,
    this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Morphology Info
          if (morphologyType != null)
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.mirrorOverlay,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Morphologie: $morphologyType',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (confidence != null)
                    Text(
                      'Confiance: ${(confidence! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

          // Measurement Grid Guide
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: AppDimensions.cameraFrameHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.cameraFrame.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

