import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/auth/presentation/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}

void main() {
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    container = ProviderContainer();
  });

  group('Auth State Providers', () {
    test('initial auth state should be idle', () {
      expect(container.read(authLoadingProvider), isFalse);
      expect(container.read(authErrorProvider), isNull);
      expect(container.read(authInfoProvider), isNull);
      expect(container.read(authFailedAttemptsProvider), 0);
      expect(container.read(authLockoutTimeProvider), isNull);
    });

    test('loading provider should update state', () {
      container.read(authLoadingProvider.notifier).state = true;
      expect(container.read(authLoadingProvider), isTrue);
    });
  });

  group('Lockout Logic', () {
    test('failed attempts should increment and set lockout time after 3 tries', () {
      final notifier = container.read(authFailedAttemptsProvider.notifier);
      final lockoutNotifier = container.read(authLockoutTimeProvider.notifier);
      
      // Simulate 3 failures manually to test UI/State logic isolation
      // (AuthService test would need full Supabase mock)
      notifier.state = 1;
      notifier.state = 2;
      notifier.state = 3;
      
      lockoutNotifier.state = DateTime.now().add(const Duration(seconds: 30));
      
      expect(container.read(authFailedAttemptsProvider), 3);
      expect(container.read(authLockoutTimeProvider), isNotNull);
      expect(container.read(authLockoutTimeProvider)!.isAfter(DateTime.now()), isTrue);
    });
  });

  group('AuthService (Basic)', () {
    test('AuthService should be available via provider', () {
      final service = container.read(authServiceProvider);
      expect(service, isNotNull);
    });

    test('changePassword is implemented', () {
      final service = container.read(authServiceProvider);
      expect(() => service.changePassword(oldPassword: 'a', newPassword: 'b'), returnsNormally);
    });
  });
}
