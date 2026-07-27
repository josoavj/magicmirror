import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:magicmirror/core/utils/responsive_helper.dart';
import 'package:magicmirror/presentation/widgets/glass_container.dart';

class MirrorClockCard extends StatelessWidget {
  const MirrorClockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: TextStyle(
              fontSize: ResponsiveHelper.resp(context, mobile: 56, tablet: 80),
              fontWeight: FontWeight.w200,
              color: Colors.white,
            ),
          ),
          Text(
            DateFormat(
              'EEEE d MMMM',
              Localizations.localeOf(context).toString(),
            ).format(DateTime.now()),
            style: TextStyle(
              fontSize: ResponsiveHelper.resp(context, mobile: 14, tablet: 20),
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
