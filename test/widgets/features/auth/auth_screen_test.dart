import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/auth/presentation/screens/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-key',
      );
    }
  });

  testWidgets('AuthScreen shows Login mode by default', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Pas de compte ? S\'inscrire'), findsOneWidget);
  });

  testWidgets('AuthScreen switches to Signup mode when link is tapped', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    final signupLink = find.text('Pas de compte ? S\'inscrire');
    await tester.tap(signupLink);
    await tester.pumpAndSettle();

    expect(find.text('Inscription'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}
