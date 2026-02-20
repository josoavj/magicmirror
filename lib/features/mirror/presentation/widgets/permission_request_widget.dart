import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_provider.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/dimensions.dart';

class PermissionRequestDialog extends ConsumerWidget {
  final String title;
  final String message;
  final String permissionType; // 'camera', 'microphone', 'location', 'photos'
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const PermissionRequestDialog({
    super.key,
    required this.title,
    required this.message,
    required this.permissionType,
    required this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDenied?.call();
          },
          child: const Text('Refuser'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _requestPermission(ref);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Accepter'),
        ),
      ],
    );
  }

  Future<void> _requestPermission(WidgetRef ref) async {
    late final Future<PermissionStatus> asyncValue;

    switch (permissionType) {
      case 'camera':
        asyncValue = ref.read(requestCameraPermissionProvider.future);
        break;
      case 'microphone':
        asyncValue = ref.read(requestMicrophonePermissionProvider.future);
        break;
      case 'location':
        asyncValue = ref.read(requestLocationPermissionProvider.future);
        break;
      case 'photos':
        asyncValue = ref.read(requestPhotosPermissionProvider.future);
        break;
      default:
        return;
    }

    final result = await asyncValue;
    if (result.isGranted) {
      onGranted.call();
    } else if (result.isPermanentlyDenied) {
      // Show dialog to open app settings
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    // TODO: Implement settings dialog
  }
}

class PermissionRequestWidget extends ConsumerWidget {
  final String title;
  final String message;
  final String permissionType;
  final Widget child;

  const PermissionRequestWidget({
    super.key,
    required this.title,
    required this.message,
    required this.permissionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionFuture = permissionType == 'camera'
        ? ref.watch(cameraPermissionProvider)
        : ref.watch(microphonePermissionProvider);

    return permissionFuture.when(
      data: (permission) {
        final status = permission as PermissionStatus;
        if (status.isGranted) {
          return child;
        } else if (status.isPermanentlyDenied) {
          return _buildPermissionDeniedScreen(context, ref);
        } else {
          return _buildPermissionRequestScreen(context, ref);
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Erreur: $error'))),
    );
  }

  Widget _buildPermissionRequestScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                permissionType == 'camera' ? Icons.camera_alt : Icons.mic,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  late final Future<PermissionStatus> asyncValue;

                  switch (permissionType) {
                    case 'camera':
                      asyncValue = ref.read(
                        requestCameraPermissionProvider.future,
                      );
                      break;
                    case 'microphone':
                      asyncValue = ref.read(
                        requestMicrophonePermissionProvider.future,
                      );
                      break;
                    default:
                      return;
                  }

                  final result = await asyncValue;
                  if (!result.isGranted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Permission refusée. Veuillez l\'autoriser dans les paramètres.',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
                child: const Text('Autoriser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                'Permission Refusée',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Veuillez autoriser la permission dans les paramètres de l\'application.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final permissionService = ref.read(permissionServiceProvider);
                  await permissionService.openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
                child: const Text('Ouvrir les paramètres'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
