import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ml_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../../../../presentation/widgets/glass_container.dart';

/// Screen de détection morphologie temps réel
class MlDetectionScreen extends ConsumerWidget {
  const MlDetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final morphology = ref.watch(currentMorphologyProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Détection Morphologie'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Flux caméra
            const CameraPreviewWidget(),

            // Overlay d'informations
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xFF0F172A)],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: morphology != null
                    ? _buildMorphologyInfo(morphology)
                    : _buildLoadingState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphologyInfo(dynamic morphology) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résultats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          borderRadius: 16,
          blur: 20,
          opacity: 0.1,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Type de corps',
                value: morphology.bodyType ?? 'Détection...',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Confiance',
                value: '${(morphology.confidence ?? 0).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Hauteur',
                value: '${(morphology.totalHeight ?? 0).toStringAsFixed(1)} cm',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        GlassContainer(
          borderRadius: 16,
          blur: 20,
          opacity: 0.1,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analyse en cours...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
