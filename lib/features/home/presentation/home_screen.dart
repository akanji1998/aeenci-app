import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/env_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/router/placeholder_screen.dart';
import '../../../core/domain/enums.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';

/// Accueil provisoire : liens vers les écrans hors onglets (lot 3 à venir).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final canScan =
        session is SessionMember && session.can(Abilities.attendanceScan);
    final devTools = ref.watch(envConfigProvider).isDev;
    return PlaceholderScreen(
      title: l10n.screenHome,
      links: [
        PlaceholderLink(l10n.screenNews, AppRoutes.news, push: true),
        PlaceholderLink(
          l10n.screenNotifications,
          AppRoutes.notifications,
          push: true,
        ),
        PlaceholderLink(
          l10n.screenOpportunities,
          AppRoutes.opportunities,
          push: true,
        ),
        if (canScan)
          PlaceholderLink(l10n.screenScan, AppRoutes.scan, push: true),
        if (devTools)
          PlaceholderLink(l10n.demoTitle, AppRoutes.devComponents, push: true),
      ],
    );
  }
}
