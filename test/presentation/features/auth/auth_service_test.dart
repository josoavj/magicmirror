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
    });

    test('loading provider should update state', () {
      container.read(authLoadingProvider.notifier).state = true;
      expect(container.read(authLoadingProvider), isTrue);
    });

    test('error provider should store message', () {
      container.read(authErrorProvider.notifier).state = 'Invalid credentials';
      expect(container.read(authErrorProvider), 'Invalid credentials');
    });
  });

  group('AuthService (Basic)', () {
    test('AuthService should be available via provider', () {
      final service = container.read(authServiceProvider);
      expect(service, isNotNull);
    });
  });
}
