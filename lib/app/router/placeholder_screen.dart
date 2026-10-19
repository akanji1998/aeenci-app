import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/components/app_card.dart';
import '../../core/design/components/empty_state.dart';
import '../../l10n/generated/app_localizations.dart';

/// Lien d'un écran provisoire vers un autre écran.
class PlaceholderLink {
  const PlaceholderLink(this.label, this.location, {this.push = false});

  final String label;
  final String location;

  /// `true` : empile l'écran (hors onglets, retour possible) ;
  /// `false` : navigation par adresse (sous-écran d'un onglet).
  final bool push;
}

/// Écran vide, en attendant le lot qui le réalise.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.links = const [],
    this.footer,
  });

  final String title;
  final List<PlaceholderLink> links;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          EmptyState(
            icon: LucideIcons.hammer,
            title: l10n.placeholderTitle,
            message: l10n.placeholderMessage,
          ),
          for (final link in links) ...[
            AppCard(
              onTap: () => link.push
                  ? context.push(link.location)
                  : context.go(link.location),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link.label,
                      style: context.textTheme.titleMedium,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: context.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.space4),
            footer!,
          ],
        ],
      ),
    );
  }
}
