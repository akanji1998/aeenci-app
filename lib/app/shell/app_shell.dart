import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/design/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Les cinq onglets. Chaque onglet garde sa propre pile d'écrans.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.line)),
        ),
        // Libellés plafonnés à 150 % : cinq onglets doivent tenir sur un
        // petit écran. Le reste de l'application suit la taille système.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            // Un second appui sur l'onglet actif revient à sa racine.
            onDestinationSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            destinations: [
              NavigationDestination(
                icon: const Icon(LucideIcons.house),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.idCard),
                label: l10n.navCard,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.calendar),
                label: l10n.navEvents,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.creditCard),
                label: l10n.navContributions,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.user),
                label: l10n.navProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
