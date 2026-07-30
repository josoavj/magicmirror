import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';

class MirrorUIState {
  final bool showMobileHud;
  final bool showCameraControls;
  final bool showExposureControl;
  final bool showResetCameraBadge;
  final double currentZoomLevel;
  final double currentExposureOffset;
  final bool zoomUnsupported;
  final bool exposureUnsupported;
  final bool flashUnsupported;

  const MirrorUIState({
    this.showMobileHud = true,
    this.showCameraControls = false,
    this.showExposureControl = false,
    this.showResetCameraBadge = false,
    this.currentZoomLevel = 1.0,
    this.currentExposureOffset = 0.0,
    this.zoomUnsupported = false,
    this.exposureUnsupported = false,
    this.flashUnsupported = false,
  });

  MirrorUIState copyWith({
    bool? showMobileHud,
    bool? showCameraControls,
    bool? showExposureControl,
    bool? showResetCameraBadge,
    double? currentZoomLevel,
    double? currentExposureOffset,
    bool? zoomUnsupported,
    bool? exposureUnsupported,
    bool? flashUnsupported,
  }) {
    return MirrorUIState(
      showMobileHud: showMobileHud ?? this.showMobileHud,
      showCameraControls: showCameraControls ?? this.showCameraControls,
      showExposureControl: showExposureControl ?? this.showExposureControl,
      showResetCameraBadge: showResetCameraBadge ?? this.showResetCameraBadge,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
      currentExposureOffset:
          currentExposureOffset ?? this.currentExposureOffset,
      zoomUnsupported: zoomUnsupported ?? this.zoomUnsupported,
      exposureUnsupported: exposureUnsupported ?? this.exposureUnsupported,
      flashUnsupported: flashUnsupported ?? this.flashUnsupported,
    );
  }
}

final mirrorUIProvider =
    StateNotifierProvider<MirrorUINotifier, MirrorUIState>((ref) {
      return MirrorUINotifier(ref);
    });

class MirrorUINotifier extends StateNotifier<MirrorUIState> {
  final Ref _ref;
  Timer? _hudTimer;
  Timer? _cameraControlsTimer;
  Timer? _resetCameraBadgeTimer;
  final DateTime _hudSessionStartedAt = DateTime.now();

  MirrorUINotifier(this._ref) : super(const MirrorUIState()) {
    _startHudTimer();
  }

  void _startHudTimer() {
    _hudTimer?.cancel();
    _hudTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _syncHudVisibility();
    });
    _syncHudVisibility(force: true);
  }

  void _syncHudVisibility({bool force = false}) {
    final now = DateTime.now();
    final settings = _ref.read(appSettingsProvider);
    final cycleSeconds = (settings.mirrorHudCycleMinutes * 60).clamp(1, 3600);
    final visibleSeconds = settings.mirrorHudDisplaySeconds.clamp(
      1,
      cycleSeconds,
    );

    final initialElapsed = now.difference(_hudSessionStartedAt).inSeconds;
    final shouldShow =
        initialElapsed < visibleSeconds
            ? true
            : (now.millisecondsSinceEpoch ~/ 1000 % cycleSeconds) <
                visibleSeconds;

    if (force || shouldShow != state.showMobileHud) {
      state = state.copyWith(showMobileHud: shouldShow);
    }
  }

  void showCameraControlsTemporarily({bool withExposure = false}) {
    state = state.copyWith(
      showCameraControls: true,
      showExposureControl: withExposure,
    );
    _cameraControlsTimer?.cancel();
    _cameraControlsTimer = Timer(const Duration(seconds: 4), () {
      state = state.copyWith(
        showCameraControls: false,
        showExposureControl: false,
      );
    });
  }

  void showResetFeedbackBadge() {
    state = state.copyWith(showResetCameraBadge: true);
    _resetCameraBadgeTimer?.cancel();
    _resetCameraBadgeTimer = Timer(const Duration(milliseconds: 1200), () {
      state = state.copyWith(showResetCameraBadge: false);
    });
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(currentZoomLevel: zoom);
  }

  void setExposureOffset(double offset) {
    state = state.copyWith(currentExposureOffset: offset);
  }

  void setZoomUnsupported(bool value) {
    state = state.copyWith(zoomUnsupported: value);
  }

  void setExposureUnsupported(bool value) {
    state = state.copyWith(exposureUnsupported: value);
  }

  void setFlashUnsupported(bool value) {
    state = state.copyWith(flashUnsupported: value);
  }

  void hideCameraControls() {
    state = state.copyWith(showCameraControls: false, showExposureControl: false);
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    _cameraControlsTimer?.cancel();
    _resetCameraBadgeTimer?.cancel();
    super.dispose();
  }
}
