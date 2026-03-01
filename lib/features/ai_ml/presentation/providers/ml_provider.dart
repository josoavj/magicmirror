import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/morphology_model.dart';
import '../../data/services/morphology_service.dart';

final morphologyServiceProvider = Provider<MorphologyService>((ref) {
  final service = MorphologyService();
  ref.onDispose(() => service.dispose());
  return service;
});

final currentMorphologyProvider = StateProvider<MorphologyData?>((ref) => null);

// Provider pour gérer l'état de détection ML
final isMlProcessingProvider = StateProvider<bool>((ref) => false);
