import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:magicmirror/features/auth/presentation/screens/auth_screen.dart';
import 'package:magicmirror/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:magicmirror/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:magicmirror/presentation/screens/home_screen.dart';
import 'package:magicmirror/l10n/app_localizations.dart';

class AuthGate extends StatelessWidget {
  final bool isSupabaseReady;

  const AuthGate({super.key, required this.isSupabaseReady});

  @override
  Widget build(BuildContext context) {
    if (!isSupabaseReady) {
      final l10n = Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      );
      return Scaffold(
        body: Center(
          child: Text(
            l10n?.supabaseNotConfigured ??
                'Supabase non configure dans assets/.env',
          ),
        ),
      );
    }

    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final event = snapshot.data?.event;
        final session = snapshot.data?.session;
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }
        if (session == null) {
          return const AuthScreen();
        }

        final confirmed = session.user.emailConfirmedAt != null;
        if (!confirmed) {
          return const VerifyEmailScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
