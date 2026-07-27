import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class AgendaGlassTile extends StatelessWidget {
  final String time;
  final String title;
  final String type;
  final bool isNow;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const AgendaGlassTile({
    super.key,
    required this.time,
    required this.title,
    required this.type,
    this.isNow = false,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final accentColor = isNow ? Colors.cyanAccent : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 24,
        blur: isNow ? 40 : 32,
        opacity: isNow ? 0.16 : 0.1,
        tintColor: isNow ? Colors.cyan.withValues(alpha: 0.8) : Colors.white,
        borderWidth: isNow ? 2.0 : 1.1,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNow)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sensors,
                        size: 14,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isEnglish ? 'NOW' : 'EN CE MOMENT',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          isCompleted
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.white,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                      decoration:
                          isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleComplete,
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        isCompleted
                            ? Colors.greenAccent
                            : (isNow ? Colors.cyanAccent : Colors.white70),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(isEnglish ? 'Edit' : 'Modifier'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(isEnglish ? 'Delete' : 'Supprimer'),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AgendaGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const AgendaGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      blur: 16,
      opacity: 0.12,
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class AgendaGlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const AgendaGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        borderRadius: 24,
        blur: 28,
        opacity: 0.11,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 20),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
