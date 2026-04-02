import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class MirrorOverlay extends StatelessWidget {
  final String? morphologyType;
  final double? confidence;
  final Map<String, dynamic>? measurements;
  final bool compact;

  const MirrorOverlay({
    super.key,
    this.morphologyType,
    this.confidence,
    this.measurements,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final infoPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
        : const EdgeInsets.all(AppDimensions.paddingMedium);
    final titleSize = compact ? 13.0 : 16.0;
    final confidenceSize = compact ? 11.0 : 14.0;
    final spacing = compact ? 8.0 : 16.0;
    final frameHeight = compact
        ? AppDimensions.cameraFrameHeight * 0.46
        : AppDimensions.cameraFrameHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morphology Info
        if (morphologyType != null)
          Container(
            padding: infoPadding,
            decoration: BoxDecoration(
              color: AppColors.mirrorOverlay,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morphologie: $morphologyType',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (confidence != null)
                  Text(
                    'Confiance: ${(confidence! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: confidenceSize,
                    ),
                  ),
              ],
            ),
          ),

        if (!compact) ...[
          // Measurement Grid Guide
          SizedBox(height: spacing),
          Container(
            width: double.infinity,
            height: frameHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.cameraFrame.withValues(alpha: 0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ],
    );
  }
}
