import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:magicmirror/features/ai_ml/presentation/providers/ml_provider.dart';
import 'package:magicmirror/features/user_profile/presentation/providers/user_profile_provider.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  String _tr(BuildContext context, String fr, String en) {
    return Localizations.localeOf(context).languageCode == 'en' ? en : fr;
  }

  static const List<String> _styles = [
    'Casual',
    'Elegant',
    'Sport',
    'Streetwear',
    'Business',
    'Minimaliste',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(userProfileProvider.notifier);
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await notifier.setUserId(currentUser.id);
      }
      await notifier.pullFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final profile = ref.watch(userProfileProvider);
    final detectedMorphology = ref.watch(currentMorphologyProvider);
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final lastSyncAt = ref.watch(profileLastSyncAtProvider);
    final schemaWarningAsync = ref.watch(profileSchemaWarningProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final activeEmail =
        activeUser?.email ?? _tr(context, 'Non connecte', 'Not connected');
    final isEmailVerified = activeUser?.emailConfirmedAt != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEnglish ? 'User Profile' : 'Profil utilisateur'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                schemaWarningAsync.when(
                  data: (warning) {
                    if (warning == null || warning.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        GlassContainer(
                          borderRadius: 14,
                          blur: 20,
                          opacity: 0.12,
                          tintColor: Colors.amber,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                if (syncStatus == ProfileSyncStatus.syncing) ...[
                  GlassContainer(
                    borderRadius: 14,
                    blur: 20,
                    opacity: 0.11,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _tr(
                              context,
                              'Chargement des donnees cloud...',
                              'Loading cloud data...',
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _SectionCard(
                  title: _tr(context, 'Compte actif', 'Active account'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: $activeEmail',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${activeUser?.id ?? profile.userId}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEmailVerified
                            ? _tr(context, 'Email verifié', 'Email verified')
                            : _tr(
                                context,
                                'Email non verifié',
                                'Email not verified',
                              ),
                        style: TextStyle(
                          color: isEmailVerified
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/account-settings');
                          },
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: Text(
                            _tr(
                              context,
                              'Gérer mon compte',
                              'Manage my account',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Identité', 'Identity'),
                  child: Column(
                    children: [
                      _ProfileHeader(
                        displayName: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                      ),
                      const SizedBox(height: 12),
                      _ReadOnlyInfoRow(
                        icon: Icons.person,
                        label: _tr(context, 'Nom', 'Name'),
                        value: profile.displayName,
                      ),
                      const SizedBox(height: 12),
                      _ReadOnlyInfoRow(
                        icon: Icons.photo,
                        label: _tr(context, 'Avatar (URL)', 'Avatar (URL)'),
                        value: profile.avatarUrl.isEmpty
                            ? _tr(context, 'Non renseignee', 'Not set')
                            : profile.avatarUrl,
                      ),
                      const SizedBox(height: 12),
                      _ReadOnlyInfoRow(
                        icon: Icons.wc,
                        label: _tr(context, 'Sexe', 'Gender'),
                        value: profile.gender,
                      ),
                      const SizedBox(height: 12),
                      _BirthDateField(
                        age: profile.age,
                        birthDate: profile.birthDate,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      _ReadOnlyInfoRow(
                        icon: Icons.height,
                        label: _tr(context, 'Taille', 'Height'),
                        value:
                            '${profile.heightCm} ${_tr(context, 'cm', 'cm')}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Morphologie', 'Body Type'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadOnlyInfoRow(
                        icon: Icons.accessibility_new,
                        label: _tr(context, 'Morphologie', 'Body Type'),
                        value: profile.morphology,
                      ),
                      const SizedBox(height: 12),
                      if (detectedMorphology != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_tr(context, 'Détection IA', 'AI detection')}: ${detectedMorphology.bodyType}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/account-settings',
                                );
                              },
                              child: Text(
                                _tr(context, 'Modifier', 'Edit in account'),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _tr(
                            context,
                            'Lancez la detection ML pour proposer une morphologie automatiquement.',
                            'Run ML detection to suggest body type automatically.',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(
                    context,
                    'Préférences vestimentaires',
                    'Style preferences',
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _styles.map((style) {
                      final isSelected = profile.preferredStyles.contains(
                        style,
                      );
                      return FilterChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: null,
                        selectedColor: Colors.blue.withValues(alpha: 0.55),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        checkmarkColor: Colors.white,
                        labelStyle: const TextStyle(color: Colors.white),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Synchronisation cloud', 'Cloud sync'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .syncToCloud();
                              },
                              icon: const Icon(Icons.cloud_upload),
                              label: Text(_tr(context, 'Sauvegarder', 'Save')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .pullFromCloud();
                              },
                              icon: const Icon(Icons.cloud_download),
                              label: Text(_tr(context, 'Synchroniser', 'Sync')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        syncMessage,
                        style: TextStyle(
                          color: _syncStatusColor(syncStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_tr(context, 'Derniere synchronisation', 'Last sync')}: ${_formatLastSync(lastSyncAt, context)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: _tr(context, 'Resume', 'Summary'),
                  child: Text(
                    '${_tr(context, 'Profil', 'Profile')}: ${profile.displayName}, ${profile.gender}, ${profile.age} ${_tr(context, 'ans', 'years')}, ${profile.heightCm} cm, ${profile.morphology} - ${_tr(context, 'styles', 'styles')}: ${profile.preferredStyles.join(', ')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _syncStatusColor(ProfileSyncStatus status) {
    switch (status) {
      case ProfileSyncStatus.success:
        return Colors.greenAccent;
      case ProfileSyncStatus.failure:
        return Colors.redAccent;
      case ProfileSyncStatus.syncing:
        return Colors.amberAccent;
      case ProfileSyncStatus.idle:
        return Colors.white70;
    }
  }

  String _formatLastSync(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) {
      return _tr(context, 'Jamais', 'Never');
    }
    final local = dateTime.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy ${_tr(context, 'a', 'at')} $hh:$min';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      blur: 24,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BirthDateField extends ConsumerWidget {
  final int age;
  final DateTime? birthDate;
  final bool enabled;

  const _BirthDateField({
    required this.age,
    required this.birthDate,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final birthDateText = birthDate == null
        ? (isEnglish ? 'Not set' : 'Non renseignee')
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake, color: Colors.white70),
            const SizedBox(width: 12),
            Text(
              isEnglish ? 'Age: $age years' : 'Age: $age ans',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final now = DateTime.now();
                    final maxDate = DateTime(now.year - 12, now.month, now.day);
                    final minDate = DateTime(
                      now.year - 100,
                      now.month,
                      now.day,
                    );
                    final initialDate =
                        birthDate ??
                        DateTime(now.year - 25, now.month, now.day);

                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initialDate.isAfter(maxDate)
                          ? maxDate
                          : initialDate,
                      firstDate: minDate,
                      lastDate: maxDate,
                    );

                    if (selected == null) {
                      return;
                    }

                    await ref
                        .read(userProfileProvider.notifier)
                        .setBirthDate(
                          DateTime(selected.year, selected.month, selected.day),
                        );
                  },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              isEnglish
                  ? 'Birth date: $birthDateText'
                  : 'Date de naissance: $birthDateText',
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String avatarUrl;

  const _ProfileHeader({required this.displayName, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasNetworkAvatar =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          backgroundImage: hasNetworkAvatar ? NetworkImage(avatarUrl) : null,
          child: hasNetworkAvatar
              ? null
              : Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
