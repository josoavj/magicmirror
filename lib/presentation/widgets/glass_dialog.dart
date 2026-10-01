import 'dart:ui';

import 'package:flutter/material.dart';

Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        glassDialogBuilder(
          dialogContext,
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: builder(dialogContext),
            ),
          ),
        ),
  );
}

Widget glassDialogBuilder(BuildContext context, Widget? child) {
  final theme = Theme.of(context);
  final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
  final cardShape = theme.cardTheme.shape;
  return Theme(
    data: theme.copyWith(
      dialogTheme: theme.dialogTheme.copyWith(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: cardShape,
      ),
      datePickerTheme: theme.datePickerTheme.copyWith(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      timePickerTheme: theme.timePickerTheme.copyWith(
        backgroundColor: cardColor,
        shape: cardShape,
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: const ColoredBox(color: Colors.transparent),
        ),
        Center(child: child ?? const SizedBox.shrink()),
      ],
    ),
  );
}
