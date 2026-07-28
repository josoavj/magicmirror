import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/mirror/presentation/providers/mirror_ui_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('MirrorUINotifier', () {
    test('initial state should have mobile HUD visible', () {
      final state = container.read(mirrorUIProvider);
      expect(state.showMobileHud, isTrue);
      expect(state.showCameraControls, isFalse);
    });

    test('showCameraControlsTemporarily should update state and then reset after delay', () async {
      final notifier = container.read(mirrorUIProvider.notifier);
      
      notifier.showCameraControlsTemporarily(withExposure: true);
      
      var state = container.read(mirrorUIProvider);
      expect(state.showCameraControls, isTrue);
      expect(state.showExposureControl, isTrue);

      // Wait for the timer (4 seconds)
      await Future.delayed(const Duration(seconds: 4, milliseconds: 100));
      
      state = container.read(mirrorUIProvider);
      expect(state.showCameraControls, isFalse);
      expect(state.showExposureControl, isFalse);
    });

    test('setZoomLevel should update currentZoomLevel', () {
      final notifier = container.read(mirrorUIProvider.notifier);
      notifier.setZoomLevel(2.5);
      
      final state = container.read(mirrorUIProvider);
      expect(state.currentZoomLevel, 2.5);
    });

    test('showResetFeedbackBadge should show and then hide badge', () async {
      final notifier = container.read(mirrorUIProvider.notifier);
      
      notifier.showResetFeedbackBadge();
      var state = container.read(mirrorUIProvider);
      expect(state.showResetCameraBadge, isTrue);

      await Future.delayed(const Duration(milliseconds: 1300));
      
      state = container.read(mirrorUIProvider);
      expect(state.showResetCameraBadge, isFalse);
    });
  });
}
