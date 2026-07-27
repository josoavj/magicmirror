import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/mirror/presentation/providers/mirror_ui_state.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorCameraControls extends ConsumerWidget {
  final double minZoom;
  final double maxZoom;
  final double minExposure;
  final double maxExposure;
  final bool canControlZoom;
  final bool canControlExposure;
  final Function(double) onZoomChanged;
  final Function(double) onExposureChanged;

  const MirrorCameraControls({
    super.key,
    required this.minZoom,
    required this.maxZoom,
    required this.minExposure,
    required this.maxExposure,
    required this.canControlZoom,
    required this.canControlExposure,
    required this.onZoomChanged,
    required this.onExposureChanged,
  });

  void _lightHaptic(
    DateTime? lastHapticAt, {
    Duration minInterval = const Duration(milliseconds: 80),
  }) {
    final now = DateTime.now();
    if (lastHapticAt != null && now.difference(lastHapticAt) < minInterval) {
      return;
    }
    unawaited(HapticFeedback.lightImpact());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(mirrorUIProvider);
    final uiNotifier = ref.read(mirrorUIProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child:
              !uiState.showCameraControls
                  ? const SizedBox.shrink()
                  : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      borderRadius: 18,
                      blur: 18,
                      opacity: 0.18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final preset in [1.0, 1.5, 2.0, 3.0])
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: GestureDetector(
                                onTap:
                                    canControlZoom
                                        ? () {
                                          _lightHaptic(null);
                                          uiNotifier
                                              .showCameraControlsTemporarily();
                                          onZoomChanged(preset);
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
                                    color:
                                        (uiState.currentZoomLevel - preset)
                                                    .abs() <
                                                0.08
                                            ? const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.28)
                                            : Colors.white.withValues(
                                              alpha: 0.08,
                                            ),
                                  ),
                                  child: Text(
                                    '${preset.toStringAsFixed(preset < 1 ? 1 : 0)}x',
                                    style: TextStyle(
                                      color:
                                          canControlZoom
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
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child:
                  uiState.showExposureControl
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
                                  value: uiState.currentExposureOffset,
                                  min: minExposure,
                                  max: maxExposure,
                                  onChanged:
                                      canControlExposure
                                          ? (value) {
                                            _lightHaptic(
                                              null,
                                              minInterval: const Duration(
                                                milliseconds: 120,
                                              ),
                                            );
                                            uiNotifier
                                                .showCameraControlsTemporarily(
                                                  withExposure: true,
                                                );
                                            onExposureChanged(value);
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
                    '${uiState.currentZoomLevel.toStringAsFixed(1)}x',
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
                      uiState.showCameraControls
                          ? Icons.tune_rounded
                          : Icons.camera_enhance_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      _lightHaptic(null,
                          minInterval: const Duration(milliseconds: 40));
                      if (uiState.showCameraControls) {
                        uiNotifier.hideCameraControls();
                      } else {
                        uiNotifier.showCameraControlsTemporarily();
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
                      uiState.showExposureControl
                          ? Icons.wb_sunny
                          : Icons.wb_sunny_outlined,
                      color: canControlExposure ? Colors.white : Colors.white54,
                      size: 20,
                    ),
                    onPressed: canControlExposure
                        ? () {
                            _lightHaptic(null, minInterval: const Duration(milliseconds: 40));
                            uiNotifier.showCameraControlsTemporarily(
                              withExposure: !uiState.showExposureControl,
                            );
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
}
