import 'package:flutter/material.dart';
import 'package:magicmirror/core/constants/app_constants.dart';

class AboutHeader extends StatelessWidget {
  final bool isEnglish;

  const AboutHeader({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 124,
          height: 124,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.withValues(alpha: 0.8),
                Colors.purpleAccent.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo/magicmirrorlogo.png',
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Magic Mirror',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'v${AppConstants.appVersion}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class AboutCard extends StatelessWidget {
  final bool isEnglish;

  const AboutCard({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'Your everyday style assistant'
                  : 'Votre assistant style au quotidien',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
                  ? 'Magic Mirror brings your mirror, outfit ideas, weather and plans together. Explore each feature below to see how it can help you get ready and organize your day.'
                  : 'Magic Mirror réunit votre miroir, des idées de tenues, la météo et votre agenda. Découvrez ci-dessous comment chaque fonctionnalité peut vous aider à vous préparer et à organiser votre journée.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutFeatureList extends StatelessWidget {
  final bool isEnglish;

  const AboutFeatureList({super.key, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final features = [
      (
        Icons.camera_alt_outlined,
        isEnglish ? 'See yourself in the mirror' : 'Retrouvez votre reflet',
        isEnglish
            ? 'Use the live camera view as a mirror. You can open the camera controls and manage access from the app settings.'
            : 'Utilisez l’image de la caméra en direct comme miroir. Les commandes de la caméra et ses autorisations se gèrent depuis l’application.',
      ),
      (
        Icons.accessibility_new_rounded,
        isEnglish
            ? 'Get recommendations tailored to you'
            : 'Des conseils adaptés à votre profil',
        isEnglish
            ? 'The camera can estimate your body shape from your posture. This information helps refine the outfit suggestions.'
            : 'La caméra peut estimer votre morphologie à partir de votre posture. Cette information aide à affiner les suggestions de tenues.',
      ),
      (
        Icons.calendar_month_outlined,
        isEnglish
            ? 'Keep track of your plans'
            : 'Gardez un œil sur votre agenda',
        isEnglish
            ? 'Add events, review what is coming up and use your plans when preparing for the day.'
            : 'Ajoutez des événements, consultez ceux à venir et tenez compte de votre programme pour préparer la journée.',
      ),
      (
        Icons.wb_sunny_outlined,
        isEnglish ? 'Check the local weather' : 'Consultez la météo locale',
        isEnglish
            ? 'See current conditions and the forecast for your selected location.'
            : 'Consultez les conditions actuelles et les prévisions pour le lieu sélectionné.',
      ),
      (
        Icons.checkroom_outlined,
        isEnglish
            ? 'Find an outfit for the day'
            : 'Trouvez une tenue pour la journée',
        isEnglish
            ? 'Browse outfit ideas and take the weather and your plans into account. Save the looks you want to find again in Favorites.'
            : 'Parcourez des idées de tenues en tenant compte de la météo et de votre agenda. Ajoutez vos préférées aux Favoris pour les retrouver facilement.',
      ),
      (
        Icons.inventory_2_outlined,
        isEnglish
            ? 'Keep track of your wardrobe'
            : 'Retrouvez votre garde-robe',
        isEnglish
            ? 'The wardrobe takes the clothes and accessories you own or wear into account, so you can keep track of what is available and use those pieces in your outfit ideas.'
            : 'La Garde-robe prend en compte les vêtements et accessoires que vous possédez ou utilisez. Vous pouvez ainsi retrouver les pièces disponibles et les intégrer à vos idées de tenues.',
      ),
      (
        Icons.cloud_sync_outlined,
        isEnglish
            ? 'Manage your profile and sync'
            : 'Gérez votre profil et sa synchronisation',
        isEnglish
            ? 'Update your profile in Settings. When you use an account, profile and favorites can be synchronized with the cloud.'
            : 'Modifiez votre profil dans les Paramètres. Avec un compte, le profil et les favoris peuvent être synchronisés avec le Cloud.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEnglish ? 'What you can do' : 'Ce que vous pouvez faire',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEnglish
                    ? 'A quick guide to the main features.'
                    : 'Un aperçu des principales fonctionnalités.',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        for (final feature in features)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(feature.$1, color: Colors.blueAccent, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feature.$3,
                          style: TextStyle(color: Colors.white70, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
