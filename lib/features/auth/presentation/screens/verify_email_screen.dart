import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  String? _message;
  String? _error;

  Future<void> _resend() async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      setState(() {
        _error = 'Email utilisateur introuvable.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      setState(() {
        _message = 'Email de verification renvoye.';
      });
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible de renvoyer l\'email.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _refreshSession() async {
    setState(() {
      _error = null;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.refreshSession();
      final confirmed =
          Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;
      if (!mounted) {
        return;
      }
      setState(() {
        _message = confirmed
            ? 'Email verifie. Redirection en cours...'
            : 'Email pas encore verifie.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Impossible d\'actualiser la session.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'N/A';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: Colors.white.withValues(alpha: 0.08),
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.white,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verification email requise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un email a ete envoye a: $email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    if (_message != null)
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amberAccent),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _sending ? null : _refreshSession,
                      icon: const Icon(Icons.refresh),
                      label: const Text('J\'ai verifie, actualiser'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _sending ? null : _resend,
                      icon: _sending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Renvoyer email'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Se deconnecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
