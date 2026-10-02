import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/core/utils/user_facing_error.dart';
import 'package:magicmirror/features/settings/data/services/account_data_service.dart';
import 'package:magicmirror/presentation/widgets/glass_dialog.dart';

Future<bool?> showAccountDataActionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required AccountDataAction action,
}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AccountDataActionDialog(action: action, ref: ref),
  );
}

class _AccountDataActionDialog extends StatefulWidget {
  const _AccountDataActionDialog({required this.action, required this.ref});

  final AccountDataAction action;
  final WidgetRef ref;

  @override
  State<_AccountDataActionDialog> createState() =>
      _AccountDataActionDialogState();
}

class _AccountDataActionDialogState extends State<_AccountDataActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _error;

  bool get _deletingAccount => widget.action == AccountDataAction.deleteAccount;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String _tr(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AccountDataService().execute(
        ref: widget.ref,
        password: _passwordController.text,
        action: widget.action,
        isEnglish: Localizations.localeOf(context).languageCode == 'en',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AccountDataException catch (error) {
      if (mounted) {
        setState(() {
          _error = userFacingError(
            context,
            error.message,
            frenchFallback:
                'La demande n’a pas abouti. Vérifiez les informations saisies et réessayez.',
            englishFallback:
                'The request could not be completed. Check the information and try again.',
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _tr(
            'La demande a échoué. Veuillez réessayer dans un instant.',
            'The request failed. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final confirmWord = _tr('SUPPRIMER', 'DELETE');

    return AlertDialog(
      title: Text(
        _deletingAccount
            ? _tr(
                'Supprimer définitivement le compte ?',
                'Delete account permanently?',
              )
            : _tr('Effacer mes données ?', 'Erase my data?'),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _deletingAccount
                    ? _tr(
                        'Le compte, le profil, les événements et les favoris seront supprimés. Les photos téléversées dans Magic Mirror seront effacées ; un lien vers une photo hébergée par un tiers sera retiré, mais pas le fichier chez cet hébergeur. Cette action est irréversible.',
                        'Your account, profile, events and favorites will be deleted. Photos uploaded to Magic Mirror will be removed; links to images hosted elsewhere will be cleared, but the source file will remain with that host. This cannot be undone.',
                      )
                    : _tr(
                        'Le profil, les événements, les favoris, les préférences de suggestions et les données météo mises en cache seront effacés. Les photos téléversées dans Magic Mirror seront supprimées ; les liens vers des photos hébergées par des tiers seront retirés sans supprimer les fichiers chez ces hébergeurs. Ton compte et ton adresse e-mail resteront actifs.',
                        'Your profile, events, favorites, outfit preferences and cached weather data will be erased. Photos uploaded to Magic Mirror will be removed; links to externally hosted images will be cleared without deleting files from those hosts. Your account and email address will remain active.',
                      ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _tr('Mot de passe actuel', 'Current password'),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? _tr(
                        'Veuillez saisir votre mot de passe.',
                        'Please enter your password.',
                      )
                    : null,
              ),
              if (_deletingAccount) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmationController,
                  decoration: InputDecoration(
                    labelText: _tr(
                      'Saisis $confirmWord pour confirmer',
                      'Type $confirmWord to confirm',
                    ),
                  ),
                  validator: (value) => value?.trim() != confirmWord
                      ? _tr(
                          'Le texte de confirmation ne correspond pas.',
                          'The confirmation text does not match.',
                        )
                      : null,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(_tr('Annuler', 'Cancel')),
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          icon: _isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _deletingAccount
                      ? Icons.delete_forever_outlined
                      : Icons.delete_sweep_outlined,
                ),
          label: Text(
            _deletingAccount
                ? _tr('Supprimer le compte', 'Delete account')
                : _tr('Effacer mes données', 'Erase my data'),
          ),
        ),
      ],
    );
  }
}
