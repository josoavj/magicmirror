import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';
import 'package:magicmirror/core/utils/platform_helper.dart';

/// Déterminer le type de plateforme
enum PlatformType { android, ios, macos, windows, linux, web, unknown }

enum CameraProfile { auto, low, medium, high }

CameraProfile _cameraProfileFromConfig() {
  final raw = AppConfig.cameraProfile.trim().toLowerCase();
  switch (raw) {
    case 'low': return CameraProfile.low;
    case 'medium': return CameraProfile.medium;
    case 'high': return CameraProfile.high;
    default: return CameraProfile.auto;
  }
}

CameraProfile _cameraProfileFromSettings(String? rawProfile) {
  if (rawProfile == null || rawProfile.isEmpty) return _cameraProfileFromConfig();
  switch (rawProfile.trim().toLowerCase()) {
    case 'low': return CameraProfile.low;
    case 'medium': return CameraProfile.medium;
    case 'high': return CameraProfile.high;
    case 'auto': return CameraProfile.auto;
    default: return _cameraProfileFromConfig();
  }
}

PlatformType _getPlatformType() {
  if (PlatformHelper.isWeb) return PlatformType.web;
  if (PlatformHelper.isAndroid) return PlatformType.android;
  if (PlatformHelper.isIOS) return PlatformType.ios;
  if (PlatformHelper.isMacOS) return PlatformType.macos;
  if (PlatformHelper.isWindows) return PlatformType.windows;
  if (PlatformHelper.isLinux) return PlatformType.linux;
  return PlatformType.unknown;
}

ResolutionPreset _getResolutionForPlatform(PlatformType platform, CameraProfile profile) {
  if (profile == CameraProfile.low) return ResolutionPreset.low;
  if (profile == CameraProfile.medium) return ResolutionPreset.medium;
  if (profile == CameraProfile.high) return ResolutionPreset.high;
  
  switch (platform) {
    case PlatformType.android: return ResolutionPreset.medium;
    case PlatformType.ios:
    case PlatformType.macos: return ResolutionPreset.high;
    case PlatformType.web: return ResolutionPreset.max; // Web scales better
    default: return ResolutionPreset.medium;
  }
}

Duration _getTimeoutForPlatform(PlatformType platform) {
  switch (platform) {
    case PlatformType.linux: return const Duration(seconds: 10);
    case PlatformType.windows: return const Duration(seconds: 8);
    case PlatformType.web: return const Duration(seconds: 15); // Browser might take longer
    default: return const Duration(seconds: 5);
  }
}

List<ImageFormatGroup> _getImageFormatFallbacks(PlatformType platform) {
  switch (platform) {
    case PlatformType.android: return const [ImageFormatGroup.nv21, ImageFormatGroup.yuv420, ImageFormatGroup.unknown];
    case PlatformType.ios: return const [ImageFormatGroup.bgra8888, ImageFormatGroup.unknown];
    default: return const [ImageFormatGroup.unknown];
  }
}

final platformTypeProvider = Provider<PlatformType>((ref) => _getPlatformType());

final isCameraSupportedProvider = Provider<bool>((ref) {
  return true; // Assume true, let initialization fail if not
});

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  final platform = ref.watch(platformTypeProvider);
  try {
    if (platform == PlatformType.linux) await Future.delayed(const Duration(milliseconds: 500));
    final timeout = _getTimeoutForPlatform(platform);
    final cameras = await availableCameras().timeout(timeout);
    return cameras;
  } on TimeoutException catch (e) {
    logger.error('Timeout récupération caméras', tag: 'CameraProvider', error: e);
    return [];
  } catch (e) {
    logger.error('Erreur availableCameras', tag: 'CameraProvider', error: e);
    return [];
  }
});

final frontCameraProvider = FutureProvider<CameraDescription?>((ref) async {
  final camerasAsync = ref.watch(availableCamerasProvider);
  return camerasAsync.when(
    data: (cameras) {
      if (cameras.isEmpty) return null;
      try {
        return cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } catch (e) {
        return cameras.isNotEmpty ? cameras.first : null;
      }
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});

final cameraControllerProvider = FutureProvider.family<CameraController?, CameraDescription>((ref, camera) async {
  final platform = ref.watch(platformTypeProvider);
  final cameraProfile = ref.watch(appSettingsProvider.select((s) => s.cameraProfile));
  final profile = _cameraProfileFromSettings(cameraProfile);
  final resolutionPreset = _getResolutionForPlatform(platform, profile);
  final timeout = _getTimeoutForPlatform(platform);
  final formatFallbacks = _getImageFormatFallbacks(platform);

  final resolutionCandidates = <ResolutionPreset>{
    resolutionPreset,
    if (resolutionPreset != ResolutionPreset.low) ResolutionPreset.low,
  }.toList();

  for (final resolution in resolutionCandidates) {
    for (final format in formatFallbacks) {
      final controller = CameraController(
        camera,
        resolution,
        enableAudio: false,
        imageFormatGroup: format,
      );

      try {
        await controller.initialize().timeout(timeout);
        ref.onDispose(() => controller.dispose());
        return controller;
      } catch (e) {
        logger.warning('Init failed (res=${resolution.name}, format=${format.name}): $e');
        try { await controller.dispose(); } catch (_) {}
      }
    }
  }
  return null;
});

final isRecordingProvider = StateProvider<bool>((ref) => false);
