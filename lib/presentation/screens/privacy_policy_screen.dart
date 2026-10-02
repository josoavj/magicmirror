import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/legal_details_text.dart';

/// Privacy notice based on data flows currently present in the app.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Privacy and personal data' : 'Confidentialité',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnglish ? 'Privacy notice' : 'Notice de confidentialité',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish
                        ? 'This notice describes the personal data used by the current app. It is a technical description; the publisher must confirm the actual deployed services and applicable legal requirements before release.'
                        : 'Cette notice décrit les données personnelles utilisées par la version actuelle de l’application. C’est une description technique ; l’éditeur doit confirmer les services réellement déployés et les exigences légales applicables avant diffusion.',
                  ),
                  const SizedBox(height: 12),
                  LegalDetailsText(
                    text: isEnglish
                        ? 'Publisher / project maintainer: josoavj (GitHub)\nAddress: Antananarivo 101, Madagascar\nPublic contact: +261 33 60 223 60\nGitHub: github.com/josoavj\nThe legal identity of the data controller must still be confirmed.'
                        : 'Éditeur et mainteneur du projet : josoavj (GitHub)\nAdresse : Antananarivo 101, Madagascar\nContact public : +261 33 60 223 60\nGitHub : github.com/josoavj\nL’identité juridique du responsable du traitement reste à confirmer.',
                  ),
                ],
              ),
            ),
          ),
          _PolicySection(
            title: isEnglish ? 'Data and purposes' : 'Données et utilisations',
            icon: Icons.dataset_outlined,
            paragraphs: isEnglish
                ? const [
                    'Account and profile: email address managed by the authentication service, user ID, display name, avatar, gender, age or date of birth, height, body-shape information and preferred styles. Used to manage your account, synchronize your profile and personalize outfit suggestions.',
                    'Agenda and favorites: event title, description, dates, location and completion status, plus identifiers of favorite outfits and local personalization preferences. Used to display and synchronize your plans and selections.',
                    'Weather: when location access is allowed, the app obtains device coordinates and sends latitude and longitude to OpenWeatherMap to retrieve weather information. Without usable location access, a default location may be used. The app also stores a local weather cache.',
                    'Camera: the live image is used by the mirror. The posture analysis uses Google ML Kit on the device. The code path reviewed does not upload or save camera frames; a profile image is uploaded only if you choose one.',
                  ]
                : const [
                    'Compte et profil : adresse e-mail gérée par le service d’authentification, identifiant utilisateur, nom affiché, avatar, genre, âge ou date de naissance, taille, morphologie et styles préférés. Ces informations servent à gérer le compte, synchroniser le profil et personnaliser les suggestions de tenues.',
                    'Agenda et favoris : titre, description, dates, lieu et état des événements, ainsi que les identifiants des tenues favorites et des préférences locales de personnalisation. Ils servent à afficher et synchroniser vos plannings et sélections.',
                    'Météo : si l’accès à la localisation est autorisé, l’application obtient les coordonnées de l’appareil et transmet latitude et longitude à OpenWeatherMap pour obtenir la météo. Sans localisation utilisable, une position par défaut peut être employée. Une copie temporaire des résultats météo est aussi conservée localement.',
                    'Caméra : l’image en direct sert de miroir. L’analyse de posture utilise Google ML Kit sur l’appareil. Le parcours de code examiné n’envoie ni n’enregistre les images de caméra ; une photo de profil n’est téléversée que si vous en choisissez une.',
                  ],
          ),
          _PolicySection(
            title: isEnglish
                ? 'Storage and retention'
                : 'Stockage et conservation',
            icon: Icons.storage_outlined,
            paragraphs: isEnglish
                ? const [
                    'Some profile values use secure device storage; other preferences, favorites and personalization values use local app storage. When signed in, profile data, favorites and agenda events can be synchronized with Supabase.',
                    'Profile avatars are uploaded to the Supabase Storage “avatars” bucket. The project setup currently configures this bucket as public, so an avatar URL may be accessible without signing in. This setting must be reviewed before claiming that avatars are private.',
                    'Weather cache: current conditions are cached for 20 minutes and forecasts for 45 minutes; stale weather may be used for up to 12 hours. The general in-memory cache defaults to one hour, and profile data caches expire after 24 hours. These are cache lifetimes, not deletion periods for cloud account data. Local account data remains until you erase it, clear app storage or uninstall; cloud profile, favorites and agenda data remain until erased or the account is deleted. The app offers password-confirmed erasure and account deletion, but these operations require the publisher to deploy and configure the Supabase account-data function. Backup expiry and legally required records must be confirmed by the publisher.',
                  ]
                : const [
                    'Certaines valeurs du profil utilisent le stockage sécurisé de l’appareil ; d’autres préférences, favoris et données de personnalisation utilisent le stockage local de l’application. Une fois connecté, le profil, les favoris et les événements de l’agenda peuvent être synchronisés avec Supabase.',
                    'Les avatars sont téléversés dans le bucket Supabase Storage « avatars ». La configuration présente dans le projet le déclare public : une URL d’avatar peut donc être accessible sans connexion. Ce réglage doit être vérifié avant d’affirmer que les avatars sont privés.',
                    'Cache météo : les conditions actuelles sont mises en cache pendant 20 minutes et les prévisions pendant 45 minutes ; une ancienne météo peut être réutilisée jusqu’à 12 heures. Le cache général en mémoire utilise une heure par défaut et le cache du profil expire après 24 heures. Ces durées concernent les caches, pas la suppression des données de compte dans le Cloud. Les données locales restent jusqu’à leur effacement, à la suppression des données de l’application ou à sa désinstallation ; les données cloud du profil, des favoris et de l’agenda restent jusqu’à leur effacement ou à la suppression du compte. Les Paramètres proposent l’effacement et la suppression du compte avec confirmation du mot de passe, mais ces opérations nécessitent le déploiement et la configuration par l’éditeur de la fonction Supabase dédiée. La durée de conservation des sauvegardes et des éventuels documents légalement requis doit être confirmée par l’éditeur.',
                  ],
          ),
          _PolicySection(
            title: isEnglish
                ? 'Security and integrity'
                : 'Sécurité et intégrité',
            icon: Icons.shield_outlined,
            paragraphs: isEnglish
                ? const [
                    'The app uses authenticated cloud access and stores some local secrets using the platform secure-storage plugin. The repository includes per-user Supabase Row Level Security policies, but the deployed project configuration must be checked separately. These measures reduce risk; they do not guarantee that a system is risk-free.',
                    'The app should collect only data needed for its features, restrict access, keep dependencies and server policies current, and remove data when its purpose or approved retention period ends. These operational controls and the actual Supabase configuration require publisher verification.',
                  ]
                : const [
                    'L’application utilise un accès cloud authentifié et conserve certains secrets locaux via le mécanisme de stockage sécurisé de la plateforme. Le dépôt contient des règles Supabase Row Level Security par utilisateur, mais la configuration réellement déployée doit être contrôlée séparément. Ces mesures réduisent les risques sans garantir un système sans risque.',
                    'L’application doit limiter la collecte aux besoins de ses fonctions, restreindre les accès, maintenir à jour les dépendances et les règles serveur, puis supprimer les données lorsque leur finalité ou leur durée approuvée prend fin. L’éditeur doit vérifier ces contrôles opérationnels et la configuration Supabase réellement déployée.',
                  ],
          ),
          _PolicySection(
            title: isEnglish ? 'Your rights' : 'Vos droits',
            icon: Icons.person_search_outlined,
            paragraphs: isEnglish
                ? const [
                    'Depending on the law that applies to you, you may request access, correction, deletion, restriction or portability of your data, object to certain processing, or withdraw consent where processing relies on it. Use the public GitHub profile above to contact the publisher; a dedicated privacy contact should be provided. Password-confirmed self-service erasure and account deletion are available in Account Settings only when the publisher has deployed and configured the Supabase function.',
                    'For users in Madagascar, the notice and processing must be checked against Law No. 2014-038 and applicable CMIL formalities. For users in the European Economic Area, the publisher must identify a valid legal basis for each purpose and meet GDPR transparency, minimization, storage limitation, security and rights requirements.',
                  ]
                : const [
                    'Selon la loi qui vous est applicable, vous pouvez demander l’accès, la rectification, l’effacement, la limitation ou la portabilité de vos données, vous opposer à certains traitements ou retirer votre consentement lorsque le traitement repose sur celui-ci. Vous pouvez contacter l’éditeur via le profil GitHub public indiqué plus haut ; un contact dédié à la confidentialité devrait être fourni. L’effacement autonome et la suppression du compte avec confirmation du mot de passe sont accessibles dans les Paramètres du compte uniquement si l’éditeur a déployé et configuré la fonction Supabase.',
                    'Pour les personnes à Madagascar, la notice et les traitements doivent être vérifiés au regard de la loi n° 2014-038 et des formalités applicables auprès de la CMIL. Pour les personnes dans l’Espace économique européen, l’éditeur doit déterminer une base légale pour chaque finalité et satisfaire aux exigences du RGPD en matière de transparence, minimisation, durée de conservation, sécurité et exercice des droits.',
                  ],
          ),
          _PolicySection(
            title: isEnglish
                ? 'Hosting and service providers'
                : 'Hébergement et prestataires',
            icon: Icons.cloud_outlined,
            paragraphs: isEnglish
                ? const [
                    'The project integrates Supabase for authentication, database and avatar storage, and OpenWeatherMap for weather. The Supabase project region and the actual production project are not recorded in this repository and must be confirmed in the publisher’s service dashboards. Location coordinates are sent to OpenWeatherMap only when location is used for weather. Consult those providers’ current privacy notices for their own processing and retention.',
                    'The app source alone cannot establish where production data is hosted, the provider’s backup schedule, or the exact legal basis chosen for each purpose. The publisher must record and disclose those verified details.',
                  ]
                : const [
                    'Le projet intègre Supabase pour l’authentification, la base de données et le stockage des avatars, ainsi qu’OpenWeatherMap pour la météo. La région du projet Supabase et le projet réellement utilisé en production ne sont pas documentés dans ce dépôt : l’éditeur doit les vérifier dans les consoles des prestataires. Les coordonnées sont transmises à OpenWeatherMap lorsque la localisation sert à obtenir la météo. Consultez les notices à jour de ces prestataires pour leurs propres traitements et durées.',
                    'Le code source ne permet pas de connaître la région d’hébergement en production, le calendrier des sauvegardes des prestataires ni la base légale retenue pour chaque finalité. L’éditeur doit vérifier et publier ces informations.',
                  ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Text(
              isEnglish
                  ? 'Last reviewed: 2 October 2026. This in-app notice is not a substitute for publisher and legal review.'
                  : 'Dernière revue technique : 2 octobre 2026. Cette notice intégrée ne remplace pas la validation de l’éditeur et une revue juridique.',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.icon,
    required this.paragraphs,
  });

  final String title;
  final IconData icon;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final paragraph in paragraphs) ...[
              Text(paragraph, style: Theme.of(context).textTheme.bodyMedium),
              if (paragraph != paragraphs.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
