import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const ProfileSectionCard({super.key, required this.title, required this.child});

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

class ProfileReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileReadOnlyInfoRow({
    super.key,
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

class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String avatarUrl;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.avatarUrl,
  });

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
          child:
              hasNetworkAvatar
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
