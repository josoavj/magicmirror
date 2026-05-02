import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:magicmirror/core/utils/app_logger.dart';
import 'package:magicmirror/config/app_config.dart';
import 'package:magicmirror/features/settings/presentation/providers/settings_provider.dart';

/// Déterminer le type de plateforme
enum PlatformType { android, ios, macos, windows, linux, web, unknown }

enum CameraProfile { auto, low, medium, high }

CameraProfile _cameraProfileFromConfig() {
  final raw = AppConfig.cameraProfile.trim().toLowerCase();
  switch (raw) {
    case 'low':
      return CameraProfile.low;
    case 'medium':
      return CameraProfile.medium;
    case 'high':
      return CameraProfile.high;
    default:
      return CameraProfile.auto;
  }
}

CameraProfile _cameraProfileFromSettings(String? rawProfile) {
  if (rawProfile == null || rawProfile.isEmpty) {
    return _cameraProfileFromConfig();
  }
  switch (rawProfile.trim().toLowerCase()) {
    case 'low':
      return CameraProfile.low;
    case 'medium':
      return CameraProfile.medium;
    case 'high':
      return CameraProfile.high;
    case 'auto':
      return CameraProfile.auto;
    default:
      return _cameraProfileFromConfig();
  }
}

PlatformType _getPlatformType() {
  if (kIsWeb) return PlatformType.web;
  if (Platform.isAndroid) return PlatformType.android;
  if (Platform.isIOS) return PlatformType.ios;
  if (Platform.isMacOS) return PlatformType.macos;
  if (Platform.isWindows) return PlatformType.windows;
  if (Platform.isLinux) return PlatformType.linux;
  return PlatformType.unknown;
}

/// Obtenir la résolution appropriée par plateforme
ResolutionPreset _getResolutionForPlatform(
  PlatformType platform,
  CameraProfile profile,
) {
  if (profile == CameraProfile.low) {
    return ResolutionPreset.low;
  }
  if (profile == CameraProfile.medium) {
    return ResolutionPreset.medium;
  }
  if (profile == CameraProfile.high) {
    return ResolutionPreset.high;
  }
  switch (platform) {
    case PlatformType.android:
      return ResolutionPreset.medium; // Réduit pression mémoire en stream ML
    case PlatformType.ios:
    case PlatformType.macos:
      return ResolutionPreset.high; // Performance robuste
    case PlatformType.windows:
    case PlatformType.linux:
      return ResolutionPreset.medium; // Performance réduite
    case PlatformType.web:
    case PlatformType.unknown:
      return ResolutionPreset.medium;
  }
}

/// Obtenir le timeout approprié par plateforme
Duration _getTimeoutForPlatform(PlatformType platform) {
  switch (platform) {
    case PlatformType.linux:
      return const Duration(seconds: 10); // Linux est plus lent
    case PlatformType.windows:
      return const Duration(seconds: 8); // Windows peut aussi être lent
    case PlatformType.android:
    case PlatformType.ios:
    case PlatformType.macos:
    case PlatformType.web:
    case PlatformType.unknown:
      return const Duration(seconds: 5); // Défaut
  }
}

List<ImageFormatGroup> _getImageFormatFallbacks(PlatformType platform) {
  switch (platform) {
    case PlatformType.android:
      return const [
        ImageFormatGroup.nv21,
        ImageFormatGroup.yuv420,
        ImageFormatGroup.unknown,
      ];
    case PlatformType.ios:
      return const [ImageFormatGroup.bgra8888, ImageFormatGroup.unknown];
    default:
      return const [ImageFormatGroup.unknown];
  }
}

/// Vérifier si la caméra est supportée sur cette plateforme
bool _isCameraSupported(PlatformType platform) {
  // Web n'est pas supporté par défaut (sans camera_web)
  // Les autres plateformes au moins ont un accès caméra minimal
  return platform != PlatformType.web;
}

/// Provider du type de plateforme
final platformTypeProvider = Provider<PlatformType>(
  (ref) => _getPlatformType(),
);

/// Provider pour vérifier le support caméra
final isCameraSupportedProvider = Provider<bool>((ref) {
  final platform = ref.watch(platformTypeProvider);
  return _isCameraSupported(platform);
});

/// Available Cameras Provider avec timeout par plateforme
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((
  ref,
) async {
  final platform = ref.watch(platformTypeProvider);

  try {
    // Ajouter un délai pour les plateformes qui en ont besoin
    if (platform == PlatformType.linux) {
      logger.debug(
        'Linux detected - attente d\'initialisation...',
        tag: 'CameraProvider',
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Web n'est pas supporté par défaut
    if (!_isCameraSupported(platform)) {
      logger.warning(
        'Camera not supported on ${platform.toString()}',
        tag: 'CameraProvider',
      );
      return [];
    }

    logger.info(
      'Fetching available cameras on ${platform.toString()}...',
      tag: 'CameraProvider',
    );
    final timeout = _getTimeoutForPlatform(platform);
    final cameras = await availableCameras().timeout(timeout);
    logger.info('Found ${cameras.length} camera(s)', tag: 'CameraProvider');

    for (var i = 0; i < cameras.length; i++) {
      logger.debug(
        'Camera $i: ${cameras[i].lensDirection} (${cameras[i].name})',
        tag: 'CameraProvider',
      );
    }

    return cameras;
  } on TimeoutException catch (e) {
    logger.error(
      'Timeout récupération caméras',
      tag: 'CameraProvider',
      error: e,
    );
    return [];
  } catch (e) {
    logger.error('Erreur availableCameras', tag: 'CameraProvider', error: e);
    return [];
  }
});

/// Front Camera Provider
final frontCameraProvider = FutureProvider<CameraDescription?>((ref) async {
  final platform = ref.watch(platformTypeProvider);

  // Web n'est pas supporté
  if (!_isCameraSupported(platform)) {
    return null;
  }

  final camerasAsync = ref.watch(availableCamerasProvider);

  return camerasAsync.when(
    data: (cameras) {
      if (cameras.isEmpty) {
        logger.warning('No cameras available', tag: 'CameraProvider');
        return null;
      }

      try {
        // Rechercher la caméra avant (front-facing)
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first, // Fallback sur première caméra
        );
        logger.info(
          'Using front camera: ${frontCamera.name}',
          tag: 'CameraProvider',
        );
        return frontCamera;
      } catch (e) {
        logger.warning(
          'Error selecting front camera, using first: $e',
          tag: 'CameraProvider',
        );
        return cameras.isNotEmpty ? cameras.first : null;
      }
    },
    loading: () {
      logger.debug('Loading cameras...', tag: 'CameraProvider');
      return null;
    },
    error: (error, stack) {
      logger.error(
        'Error loading cameras',
        tag: 'CameraProvider',
        error: error,
        stackTrace: stack,
      );
      return null;
    },
  );
});

/// Camera Controller Provider avec gestion d'état adaptée par plateforme
final cameraControllerProvider =
    FutureProvider.family<CameraController?, CameraDescription>((
      ref,
      camera,
    ) async {
      final platform = ref.watch(platformTypeProvider);
      final cameraProfile = ref.watch(
        appSettingsProvider.select((s) => s.cameraProfile),
      );
      final profile = _cameraProfileFromSettings(cameraProfile);
      final resolutionPreset = _getResolutionForPlatform(platform, profile);
      final timeout = _getTimeoutForPlatform(platform);
      final formatFallbacks = _getImageFormatFallbacks(platform);

      logger.info(
        'Initializing camera controller on ${platform.toString()}...',
        tag: 'CameraProvider',
      );
      logger.debug(
        'Resolution: ${resolutionPreset.toString()} (profile: ${profile.name})',
        tag: 'CameraProvider',
      );
      logger.debug('Timeout: ${timeout.inSeconds}s', tag: 'CameraProvider');
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
            logger.info(
              'Camera controller initialized (res=${resolution.name}, format=${format.name})',
              tag: 'CameraProvider',
            );

            ref.onDispose(() {
              logger.debug(
                'Disposing camera controller',
                tag: 'CameraProvider',
              );
              controller.dispose();
            });

            return controller;
          } catch (e) {
            logger.warning(
              'Init failed (res=${resolution.name}, format=${format.name}): $e',
              tag: 'CameraProvider',
            );
            await controller.dispose();
          }
        }
      }

      logger.error(
        'Erreur initialisation caméra (toutes les options ont échoué)',
        tag: 'CameraProvider',
      );
      return null;
    });

final isRecordingProvider = StateProvider<bool>((ref) => false);
