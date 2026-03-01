import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/camera_provider.dart';
import '../providers/permission_provider.dart';
import 'package:magicmirror/features/agenda/presentation/providers/agenda_provider.dart';
import 'package:magicmirror/features/agenda/data/models/event_model.dart';
import 'package:magicmirror/features/weather/presentation/widgets/weather_widget.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import '../widgets/camera_view.dart';
import '../widgets/mirror_overlay.dart';
import '../widgets/permission_request_widget.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/responsive_helper.dart';

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  String? _detectedMorphology;
  double? _confidence;

  @override
  Widget build(BuildContext context) {
    // Check if all required permissions are granted
    final allPermissionsGranted = ref.watch(allPermissionsGrantedProvider);

    return allPermissionsGranted.when(
      data: (granted) {
        if (!granted) {
          return PermissionRequestWidget(
            title: 'Permission Caméra Requise',
            message:
                'L\'application a besoin d\'accéder à votre caméra pour fonctionner correctement.',
            permissionType: 'camera',
            child: const SizedBox(),
          );
        }

        return _buildMirrorContent();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $error'))),
    );
  }

  Widget _buildMirrorContent() {
    final frontCamera = ref.watch(frontCameraProvider);
    final isRecording = ref.watch(isRecordingProvider);
    final eventsAsync = ref.watch(agendaEventsProvider);
    final isMirror = ResponsiveHelper.isMirror(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isMirror
          ? null
          : AppBar(title: const Text('Miroir Intelligent'), elevation: 0),
      body: frontCamera.when(
        data: (camera) {
          if (camera == null) {
            return const Center(
              child: Text(
                'Aucune caméra frontale disponible',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final cameraController = ref.watch(cameraControllerProvider(camera));

          return cameraController.when(
            data: (controller) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Camera View (Centrée et légèrement assombrie pour le miroir)
                  Center(
                    child: Opacity(
                      opacity: isMirror ? 0.7 : 1.0,
                      child: CameraView(
                        controller: controller,
                        onCapturePressed: () async {
                          setState(() {
                            _detectedMorphology = 'Sablier';
                            _confidence = 0.92;
                          });
                        },
                      ),
                    ),
                  ),

                  // Overlay Miroir (Informations ML)
                  MirrorOverlay(
                    morphologyType: _detectedMorphology,
                    confidence: _confidence,
                  ),

                  // Widget Heure & Date (Haut Droite)
                  Positioned(
                    top: 40,
                    right: 40,
                    child: GlassContainer(child: _MirrorClock()),
                  ),

                  // Widget Météo (Sous l'horloge)
                  const Positioned(top: 250, right: 40, child: WeatherWidget()),

                  // Widget Agenda réduit (Haut Gauche)
                  Positioned(
                    top: 40,
                    left: 20,
                    child: GlassContainer(
                      width: 300,
                      child: eventsAsync.when(
                        data: (events) => _MirrorAgendaOverlay(events: events),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ),

                  // Contrôles (Seulement si pas en mode miroir pur ou via interaction)
                  if (!isMirror)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: isRecording
                                  ? AppColors.error
                                  : AppColors.secondary,
                              onPressed: () {
                                ref.read(isRecordingProvider.notifier).state =
                                    !isRecording;
                                if (isRecording) {
                                  controller.stopVideoRecording();
                                } else {
                                  controller.startVideoRecording();
                                }
                              },
                              child: Icon(
                                isRecording ? Icons.stop : Icons.circle,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _MirrorClock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat.Hm().format(now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.w300,
              ),
            ),
            Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(now),
              style: const TextStyle(color: Colors.white70, fontSize: 24),
            ),
          ],
        );
      },
    );
  }
}

class _MirrorAgendaOverlay extends StatelessWidget {
  final List<AgendaEvent> events;
  const _MirrorAgendaOverlay({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'À VENIR',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...events
            .take(3)
            .map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat.Hm().format(event.startTime),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
