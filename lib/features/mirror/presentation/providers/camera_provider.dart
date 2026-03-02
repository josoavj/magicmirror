import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

// Available Cameras Provider
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  try {
    // Sur Linux, on ajoute un petit délai car le plugin a besoin de temps pour s'initialiser après le chargement du binaire
    if (!kIsWeb && Platform.isLinux) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return await availableCameras();
  } catch (e) {
    debugPrint('Erreur availableCameras: $e');
    return []; // Retourne une liste vide au lieu de bloquer en erreur
  }
});

// Front Camera Provider
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
      } catch (_) {
        return cameras.first;
      }
    },
    loading: () => null, // Ne pas bloquer l'UI
    error: (_, __) => null,
  );
});

// Camera Controller Provider avec gestion d'état simplifiée pour éviter le blocage
final cameraControllerProvider = FutureProvider.family<CameraController?, CameraDescription>((ref, camera) async {
  final controller = CameraController(
    camera,
    ResolutionPreset.medium, // Plus léger pour le prototype Linux
    enableAudio: false,
  );

  try {
    await controller.initialize().timeout(const Duration(seconds: 5));
    return controller;
  } catch (e) {
    debugPrint('Erreur initialisation caméra: $e');
    return null;
  }
});

final isRecordingProvider = StateProvider<bool>((ref) => false);
