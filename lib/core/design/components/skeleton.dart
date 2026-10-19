import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../app_theme.dart';

/// Bloc de chargement statique (pas d'animation : téléphones modestes).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Liste de cartes fantômes, annoncée « Chargement… » aux lecteurs d'écran.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.space3),
              const _SkeletonCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.colors.line),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 160, height: 20),
            SizedBox(height: AppSpacing.space3),
            SkeletonBox(),
            SizedBox(height: AppSpacing.space2),
            SkeletonBox(width: 220),
          ],
        ),
      ),
    );
  }
}
