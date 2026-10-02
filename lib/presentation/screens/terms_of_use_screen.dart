import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/legal_details_text.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final sections = isEnglish
        ? const [
            (
              '1. About the service',
              'Magic Mirror provides mirror, profile, agenda, weather, wardrobe and outfit suggestion features.\nPublisher / maintainer: josoavj (GitHub)\nAddress: Antananarivo 101, Madagascar\nPublic contact: +261 33 60 223 60\nThe legal entity and any additional mandatory publisher information must be confirmed before public commercial distribution.',
            ),
            (
              '2. Your account',
              'Provide accurate account information, keep your password confidential and tell the publisher if you suspect unauthorized access. You are responsible for activity performed through your account, subject to applicable law.',
            ),
            (
              '3. Appropriate use',
              'Use the service lawfully and do not attempt to disrupt it, access another user’s data, or upload content you do not have the right to use. You remain responsible for the photos and other content you submit.',
            ),
            (
              '4. Suggestions and availability',
              'Weather and outfit suggestions are provided as informational assistance. Check important decisions independently. Features may change or be temporarily unavailable while the service is maintained.',
            ),
            (
              '5. Personal data',
              'The Privacy and Personal Data notice explains the data handled by the app, its purposes, storage and your rights. It forms a separate notice and is available from the sign-up page and Settings.',
            ),
            (
              '6. Contact and applicable terms',
              'Public contact: +261 33 60 223 60\nGitHub: github.com/josoavj\nAddress: Antananarivo 101, Madagascar\nThe publisher must confirm the applicable jurisdiction and any mandatory consumer information before relying on these terms as final legal terms.',
            ),
          ]
        : const [
            (
              '1. À propos du service',
              'Magic Mirror propose des fonctions de miroir, de profil, d’agenda, de météo, de garde-robe et de suggestions de tenues.\nÉditeur / mainteneur : josoavj (GitHub)\nAdresse : Antananarivo 101, Madagascar\nContact public : +261 33 60 223 60\nLa forme juridique et les autres mentions obligatoires doivent être confirmées avant toute diffusion commerciale.',
            ),
            (
              '2. Votre compte',
              'Fournissez des informations de compte exactes, gardez votre mot de passe confidentiel et prévenez l’éditeur si vous suspectez un accès non autorisé. Vous êtes responsable des activités effectuées depuis votre compte, dans les limites prévues par la loi applicable.',
            ),
            (
              '3. Utilisation appropriée',
              'Utilisez le service conformément à la loi. Ne tentez pas de le perturber, d’accéder aux données d’un autre utilisateur ou de téléverser un contenu que vous n’avez pas le droit d’utiliser. Vous restez responsable des photos et autres contenus que vous soumettez.',
            ),
            (
              '4. Suggestions et disponibilité',
              'Les informations météo et les suggestions de tenues sont fournies à titre indicatif. Vérifiez par vous-même les décisions importantes. Les fonctionnalités peuvent évoluer ou être temporairement indisponibles pendant la maintenance du service.',
            ),
            (
              '5. Données personnelles',
              'La notice Confidentialité et données personnelles explique les données utilisées par l’application, leurs finalités, leur stockage et vos droits. Elle constitue une information distincte, accessible depuis l’inscription et les Paramètres.',
            ),
            (
              '6. Contact et conditions applicables',
              'Contact public : +261 33 60 223 60\nGitHub : github.com/josoavj\nAdresse : Antananarivo 101, Madagascar\nL’éditeur doit confirmer la juridiction applicable et les autres mentions obligatoires destinées aux consommateurs avant de considérer ces conditions comme définitives.',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Terms of use' : 'Conditions d’utilisation'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isEnglish
                    ? 'Informational terms · Version 1.0.1 · 2 October 2026. These terms do not replace a review against the law applicable to the publisher and users.'
                    : 'Conditions informatives · Version 1.0.1 · 2 octobre 2026. Elles doivent être vérifiées au regard des lois applicables à l’éditeur et aux utilisateurs.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final section in sections)
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.$1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LegalDetailsText(text: section.$2),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
