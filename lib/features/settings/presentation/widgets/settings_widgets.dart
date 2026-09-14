import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

/// Widget pour une section de parametres
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SettingsGlassCard extends StatelessWidget {
  final Widget child;

  const _SettingsGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassContainer(
        borderRadius: 16,
        blur: 26,
        opacity: 0.11,
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Widget pour un toggle switch setting
class SettingsToggle extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const SettingsToggle({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: icon != null
            ? Icon(icon, color: Colors.white, size: 24)
            : null,
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 13,
                ),
              )
            : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.blue.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

/// Widget pour un setting texte/input
class SettingsTextField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final IconData? icon;

  const SettingsTextField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.icon,
    super.key,
  });

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: widget.icon != null
            ? Icon(widget.icon, color: Colors.white, size: 24)
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.52),
                    width: 1.2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour un slider setting
class SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final IconData? icon;

  const SettingsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour un bouton action
class SettingsButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;

  const SettingsButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: (color ?? Colors.blueAccent).withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
        ),
      ),
    );
  }
}

/// Widget pour un item de selection
class SettingsDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const SettingsDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                dropdownColor: const Color(0xFF1A1A1A),
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour une info text
class SettingsInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  const SettingsInfo({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: icon != null
            ? Icon(icon, color: Colors.white, size: 24)
            : null,
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        trailing: onTap != null
            ? const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 24,
              )
            : null,
      ),
    );
  }
}

/// Widget pour une action au format standard (même gabarit que les autres lignes)
class SettingsActionTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  const SettingsActionTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsGlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: icon != null
            ? Icon(icon, color: iconColor ?? Colors.white, size: 24)
            : null,
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white70,
          size: 24,
        ),
      ),
    );
  }
}
