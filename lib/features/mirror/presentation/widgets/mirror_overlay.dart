import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class MirrorOverlay extends StatelessWidget {
  final String? morphologyType;
  final double? confidence;
  final Map<String, dynamic>? measurements;
  final bool compact;
  final bool mlSupported;

  const MirrorOverlay({
    super.key,
    this.morphologyType,
    this.confidence,
    this.measurements,
    this.compact = false,
    this.mlSupported = true,
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
        if (compact && morphologyType == null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: infoPadding,
            decoration: BoxDecoration(
              color: AppColors.mirrorOverlay,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Text(
              mlSupported
                  ? 'Placez-vous en entier dans le cadre pour lancer la détection.'
                  : 'La détection de morphologie n’est pas disponible sur cette plateforme.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
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
                    'Confiance: ${confidence!.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: confidenceSize,
                    ),
                  ),
              ],
            ),
          ),

        if (measurements != null && measurements!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: compact ? 6 : 10),
            child: Container(
              padding: infoPadding,
              decoration: BoxDecoration(
                color: AppColors.mirrorOverlay,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (_measurement('height_ratio', asPercent: true)
                      case final ratio?)
                    _measurementLabel('Corps dans le cadre', '$ratio%'),
                  if (_measurement('pose_quality') case final quality?)
                    _measurementLabel('Position', '$quality%'),
                  if (_measurement('symmetry_score') case final symmetry?)
                    _measurementLabel('Symétrie', '$symmetry%'),
                ],
              ),
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

  String? _measurement(String key, {bool asPercent = false}) {
    final value = measurements?[key];
    if (value == null) return null;
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(
            value.toString().replaceAll('%', '').replaceAll(',', '.'),
          );
    if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
    return (asPercent ? parsed * 100 : parsed).toStringAsFixed(0);
  }

  Widget _measurementLabel(String label, String value) => Text(
    '$label : $value',
    style: const TextStyle(color: Colors.white70, fontSize: 11),
  );
}
