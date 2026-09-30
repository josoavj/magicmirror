import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/services/tts_service.dart';
import 'package:magicmirror/features/ai_ml/data/models/morphology_model.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/l10n/app_localizations.dart';

class MirrorReadinessAnnouncer {
  MirrorReadinessAnnouncer({
    required this.ref,
    required this.context,
    required this.isMounted,
  });

  final WidgetRef ref;
  final BuildContext context;
  final bool Function() isMounted;
  ProviderSubscription<MorphologyData?>? _subscription;
  DateTime? _lastAnnouncementAt;

  void start() {
    _subscription = ref.listenManual<MorphologyData?>(
      currentMorphologyProvider,
      (previous, next) {
        if (!isMounted() || next == null) return;

        final wasReady = isReady(previous);
        if (!isReady(next) || wasReady) return;

        final now = DateTime.now();
        if (_lastAnnouncementAt != null &&
            now.difference(_lastAnnouncementAt!) <
                const Duration(seconds: 45)) {
          return;
        }

        _lastAnnouncementAt = now;
        _announceOutfitReady(next);
      },
    );
  }

  bool isReady(MorphologyData? data) {
    if (data == null) return false;
    final frameRatio = parseDouble(data.measurements['height_ratio']);
    final poseQuality = parseDouble(data.measurements['pose_quality']);
    return frameRatio >= 0.55 && poseQuality >= 60 && data.confidence >= 55;
  }

  Rect? extractTrackingRect(MorphologyData? data) {
    if (data == null) return null;
    final measurements = data.measurements;
    final left = parseDouble(measurements['bbox_left_n']);
    final top = parseDouble(measurements['bbox_top_n']);
    final width = parseDouble(measurements['bbox_width_n']);
    final height = parseDouble(measurements['bbox_height_n']);
    if (width <= 0 || height <= 0) return null;

    return Rect.fromLTWH(
      left.clamp(0.0, 1.0),
      top.clamp(0.0, 1.0),
      width.clamp(0.05, 1.0),
      height.clamp(0.05, 1.0),
    );
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(
          value.toString().replaceAll('%', '').replaceAll(',', '.').trim(),
        ) ??
        0;
  }

  Future<void> _announceOutfitReady(MorphologyData morphologyData) async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final settings = ref.read(appSettingsProvider);
    final tts = ref.read(ttsServiceProvider);
    final isEnglish = settings.ttsLanguage.startsWith('en');
    final morphologyMessage = settings.ttsAnnounceMorphology
        ? (l10n?.detectedBodyType(morphologyData.bodyType) ??
              (isEnglish
                  ? 'Detected body type: ${morphologyData.bodyType}. '
                  : 'Morphologie détectée: ${morphologyData.bodyType}. '))
        : '';

    await tts.speak(
      l10n?.fullBodyDetectedWithoutOutfit(morphologyMessage) ??
          (isEnglish
              ? 'Full body detected. ${morphologyMessage}Your outfit suggestions are ready.'
              : 'Corps complet détecté. ${morphologyMessage}Vos suggestions de tenues sont prêtes.'),
      enabled: settings.enableAudioFeedback && settings.ttsEnabled,
      interruptCurrent: settings.ttsInterruptCurrent,
      language: settings.ttsLanguage,
      speechRate: settings.ttsSpeechRate,
      pitch: settings.ttsPitch,
      minRepeatInterval: Duration(seconds: settings.ttsMinRepeatSeconds),
    );
  }

  void dispose() => _subscription?.close();
}
