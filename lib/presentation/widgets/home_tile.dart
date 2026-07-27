import 'package:flutter/material.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const HomeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final iconBubbleSize = isMobile ? 52.0 : 62.0;
    final iconSize = isMobile ? 28.0 : 34.0;
    final labelFontSize = isMobile ? 14.0 : 17.0;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 30,
        blur: 34,
        opacity: 0.11,
        tintColor: color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: isMobile ? 10 : 12,
          ),
          child: Column(
            children: [
              const Spacer(flex: 4),
              Container(
                width: iconBubbleSize,
                height: iconBubbleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              SizedBox(height: isMobile ? 10 : 14),
              SizedBox(
                height: isMobile ? 34 : 42,
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: const StrutStyle(height: 1.15),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
