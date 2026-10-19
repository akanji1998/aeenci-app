import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../app_theme.dart';

/// « Hors connexion · mis à jour le 18 oct. à 10:02 ».
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final local = updatedAt.toLocal();
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.blueSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(LucideIcons.cloudOff, size: 20, color: c.blue),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  l10n.offlineBanner(local, local),
                  style: context.textTheme.bodySmall?.copyWith(color: c.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
