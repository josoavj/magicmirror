import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/permission_provider.dart';

class PermissionRequestWidget extends ConsumerStatefulWidget {
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
  ConsumerState<PermissionRequestWidget> createState() =>
      _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState
    extends ConsumerState<PermissionRequestWidget>
    with WidgetsBindingObserver {
  String _tr(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(cameraPermissionProvider);
      ref.invalidate(allPermissionsGrantedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionType = widget.permissionType;
    final permissionAsync = permissionType == 'camera'
        ? ref.watch(cameraPermissionProvider)
        : const AsyncValue.data(true);

    return permissionAsync.when(
      data: (isGranted) {
        if (isGranted) {
          return widget.child;
        }
        return _buildPermissionRequest(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          _tr(
            context,
            'L’état de l’autorisation n’a pas pu être vérifié. Réessayez.',
            'The permission status could not be checked. Please try again.',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (widget.permissionType == 'camera') {
                  await ref.read(requestCameraPermissionProvider.future);
                  ref.invalidate(cameraPermissionProvider);
                  ref.invalidate(allPermissionsGrantedProvider);
                }
              },
              child: Text(
                _tr(context, 'Accorder la permission', 'Allow access'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(permissionServiceProvider).openAppSettings();
              },
              child: Text(
                _tr(context, 'Ouvrir les paramètres', 'Open settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
