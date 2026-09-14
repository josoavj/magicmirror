import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_provider.dart';

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
    final permissionAsync = permissionType == 'camera'
        ? ref.watch(cameraPermissionProvider)
        : const AsyncValue.data(true);

    return permissionAsync.when(
      data: (isGranted) {
        if (isGranted) {
          return child;
        }
        return _buildPermissionRequest(context, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erreur: $error')),
    );
  }

  Widget _buildPermissionRequest(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (permissionType == 'camera') {
                  await ref.read(requestCameraPermissionProvider.future);
                }
              },
              child: const Text('Accorder la permission'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(permissionServiceProvider).openAppSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}
