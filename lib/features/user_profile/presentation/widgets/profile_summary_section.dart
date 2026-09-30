import 'package:flutter/material.dart';
import 'package:magicmirror/core/utils/date_formatting.dart';
import 'package:magicmirror/features/user_profile/data/models/user_profile_model.dart';
import 'package:magicmirror/features/user_profile/presentation/widgets/profile_widgets.dart';

class ProfileSummarySection extends StatelessWidget {
  const ProfileSummarySection({
    super.key,
    required this.profile,
    required this.username,
  });

  final UserProfile profile;
  final String username;

  bool _isEnglish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en';

  String _tr(BuildContext context, String fr, String en) =>
      _isEnglish(context) ? en : fr;

  String _formatDate(BuildContext context, DateTime date) =>
      formatDisplayDate(date, locale: _isEnglish(context) ? 'en_US' : 'fr_FR');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        ProfileSectionCard(
          title: _tr(context, 'Identité', 'Identity'),
          child: Column(
            children: [
              ProfileHeader(
                displayName: profile.displayName,
                username: username,
                avatarUrl: profile.avatarUrl,
              ),
              const SizedBox(height: 18),
              _infoLine(
                Icons.person_outline,
                _tr(context, 'Nom et prénom', 'Full name'),
                profile.displayName,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.alternate_email,
                _tr(context, 'Nom d’utilisateur', 'Username'),
                username,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.wc,
                _tr(context, 'Genre', 'Gender'),
                profile.gender,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: _tr(
            context,
            'Mesure et morphologie',
            'Measurements and shape',
          ),
          child: Column(
            children: [
              _infoLine(
                Icons.cake_outlined,
                _tr(context, 'Âge', 'Age'),
                '${profile.age} ${_tr(context, 'ans', 'years')}',
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.straighten,
                _tr(context, 'Taille', 'Height'),
                '${profile.heightCm} cm',
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.accessibility_new,
                _tr(context, 'Morphologie', 'Body shape'),
                profile.morphology,
              ),
              const SizedBox(height: 12),
              _infoLine(
                Icons.event_outlined,
                _tr(context, 'Date de naissance', 'Birth date'),
                profile.birthDate == null
                    ? _tr(context, 'Non renseignée', 'Not set')
                    : _formatDate(context, profile.birthDate!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: _tr(context, 'Styles préférés', 'Preferred styles'),
          child: profile.preferredStyles.isEmpty
              ? Text(
                  _tr(
                    context,
                    'Aucun style sélectionné.',
                    'No styles selected.',
                  ),
                  style: TextStyle(color: colors.onSurfaceVariant),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: profile.preferredStyles
                      .map(
                        (style) => Chip(
                          avatar: Icon(
                            Icons.check,
                            size: 16,
                            color: colors.onSecondaryContainer,
                          ),
                          label: Text(
                            style,
                            style: TextStyle(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                          backgroundColor: colors.secondaryContainer,
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _infoLine(IconData icon, String label, String value) =>
      ProfileReadOnlyInfoRow(icon: icon, label: label, value: value);
}
