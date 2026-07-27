import 'package:flutter/material.dart';
import 'package:magicmirror/l10n/app_localizations.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorStatusBadge extends StatelessWidget {
  final bool cameraReady;
  final bool mlStreamStarted;

  const MirrorStatusBadge({
    super.key,
    required this.cameraReady,
    required this.mlStreamStarted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final statusText =
        !cameraReady
            ? (l10n?.runtimeCameraInactive ?? 'Camera inactive')
            : mlStreamStarted
            ? (l10n?.runtimeAiActive ?? 'AI active')
            : (l10n?.runtimeAiWaiting ?? 'AI waiting');
    final statusColor =
        !cameraReady
            ? Colors.redAccent
            : mlStreamStarted
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
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
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
}
