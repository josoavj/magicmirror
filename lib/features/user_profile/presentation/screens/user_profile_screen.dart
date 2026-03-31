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
  static const List<String> _genders = [
    'Femme',
    'Homme',
    'Non precise',
  ];

  static const List<String> _morphologies = [
    'Silhouette non definie',
    'Hanches et epaules equilibrees',
    'Hanches plus marquees',
    'Silhouette droite',
    'Epaules plus larges',
    'Epaules tres marquees',
    'Taille tres marquee',
    'Hanches tres marquees',
  ];

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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return;
      }
      final notifier = ref.read(userProfileProvider.notifier);
      await notifier.setUserId(currentUser.id);
      await notifier.pullFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final detectedMorphology = ref.watch(currentMorphologyProvider);
    final syncStatus = ref.watch(profileSyncStatusProvider);
    final syncMessage = ref.watch(profileSyncMessageProvider);
    final activeUser = Supabase.instance.client.auth.currentUser;
    final activeEmail = activeUser?.email ?? 'Non connecte';
    final isEmailVerified = activeUser?.emailConfirmedAt != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil utilisateur'),
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
                _SectionCard(
                  title: 'Compte actif',
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
                        isEmailVerified ? 'Email verifie' : 'Email non verifie',
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
                          label: const Text('Gerer mon compte'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Identite',
                  child: Column(
                    children: [
                      _ProfileHeader(
                        displayName: profile.displayName,
                        avatarUrl: profile.avatarUrl,
                      ),
                      const SizedBox(height: 12),
                      _EditableTextRow(
                        icon: Icons.person,
                        label: 'Nom',
                        value: profile.displayName,
                        hint: 'Ex: Alex',
                        onSubmitted: (value) {
                          ref
                              .read(userProfileProvider.notifier)
                              .setDisplayName(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _EditableTextRow(
                        icon: Icons.photo,
                        label: 'Avatar (URL)',
                        value: profile.avatarUrl,
                        hint: 'https://...',
                        onSubmitted: (value) {
                          ref
                              .read(userProfileProvider.notifier)
                              .setAvatarUrl(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _DropdownField(
                        icon: Icons.wc,
                        label: 'Sexe',
                        value: profile.gender,
                        items: _genders,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(userProfileProvider.notifier)
                                .setGender(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _BirthDateField(
                        age: profile.age,
                        birthDate: profile.birthDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Morphologie',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DropdownField(
                        icon: Icons.accessibility_new,
                        label: 'Morphologie',
                        value: profile.morphology,
                        items: _morphologies,
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(userProfileProvider.notifier)
                                .setMorphology(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (detectedMorphology != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Detection IA: ${detectedMorphology.bodyType}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(userProfileProvider.notifier)
                                    .setMorphology(detectedMorphology.bodyType);
                              },
                              child: const Text('Utiliser'),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Lancez la detection ML pour proposer une morphologie automatiquement.',
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
                  title: 'Preferences vestimentaires',
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
                        onSelected: (_) {
                          ref
                              .read(userProfileProvider.notifier)
                              .togglePreferredStyle(style);
                        },
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
                  title: 'Synchronisation cloud',
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
                              label: const Text('Envoyer'),
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
                              label: const Text('Recuperer actif'),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Resume',
                  child: Text(
                    'Profil: ${profile.displayName}, ${profile.gender}, ${profile.age} ans, ${profile.morphology} - styles: ${profile.preferredStyles.join(', ')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/outfit-suggestion'),
                    icon: const Icon(Icons.checkroom_rounded),
                    label: const Text('Voir les tenues recommandees'),
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

class _DropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A1A),
              iconEnabledColor: Colors.white,
              style: const TextStyle(color: Colors.white),
              hint: Text(label, style: const TextStyle(color: Colors.white70)),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _BirthDateField extends ConsumerWidget {
  final int age;
  final DateTime? birthDate;

  const _BirthDateField({required this.age, required this.birthDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birthDateText = birthDate == null
        ? 'Non renseignee'
        : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cake, color: Colors.white70),
            const SizedBox(width: 12),
            Text('Age: $age ans', style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final maxDate = DateTime(now.year - 12, now.month, now.day);
              final minDate = DateTime(now.year - 100, now.month, now.day);
              final initialDate =
                  birthDate ?? DateTime(now.year - 25, now.month, now.day);

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
            label: Text('Date de naissance: $birthDateText'),
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

class _EditableTextRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _EditableTextRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    required this.onSubmitted,
  });

  @override
  State<_EditableTextRow> createState() => _EditableTextRowState();
}

class _EditableTextRowState extends State<_EditableTextRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EditableTextRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
