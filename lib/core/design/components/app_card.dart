import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Carte posée sur `surface-raised`, bordée d'un filet, coins `radius-md`.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.space4),
    this.color,
  });

  final Widget child;

  /// Rend toute la carte cliquable.
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Fond teinté (ex. `green-soft`) à la place de `surface-raised`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final content = Padding(padding: padding, child: child);
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
