import 'package:flutter/material.dart';

import '../app_theme.dart';

enum AppBadgeTone { green, blue, red }

/// Badge en pilule : texte coloré sur son fond teinté.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.tone = AppBadgeTone.green});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (foreground, background) = switch (tone) {
      AppBadgeTone.green => (c.green, c.greenSoft),
      AppBadgeTone.blue => (c.blue, c.blueSoft),
      AppBadgeTone.red => (c.red, c.redSoft),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        child: Text(
          label,
          style: AppTypography.label.toTextStyle(color: foreground),
        ),
      ),
    );
  }
}
