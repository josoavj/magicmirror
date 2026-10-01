import 'package:flutter/material.dart';

class FramedListTile extends StatelessWidget {
  final Widget child;
  final bool? showBorder;
  final double inset;

  const FramedListTile({
    super.key,
    required this.child,
    this.showBorder,
    this.inset = 6,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorder =
        showBorder ?? ListTileBorderScope.maybeOf(context) ?? true;
    final outline = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.5);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    final tile = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ListTileTheme(shape: shape, child: child),
    );

    if (!hasBorder) return tile;

    return Container(
      margin: EdgeInsets.all(inset),
      decoration: ShapeDecoration(
        shape: shape.copyWith(side: BorderSide(color: outline)),
      ),
      child: tile,
    );
  }
}

class ListTileBorderScope extends InheritedWidget {
  final bool showBorder;

  const ListTileBorderScope({
    super.key,
    required this.showBorder,
    required super.child,
  });

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ListTileBorderScope>()
      ?.showBorder;

  @override
  bool updateShouldNotify(ListTileBorderScope oldWidget) =>
      showBorder != oldWidget.showBorder;
}
