import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// Démarrage : symbole pendant le chargement de la session, erreur avec
/// « Réessayer » si la fiche ne peut pas être chargée.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: switch (session) {
            SessionUnavailable(:final error) => SingleChildScrollView(
              child: ErrorState(
                error: error,
                onRetry: () =>
                    ref.read(sessionControllerProvider.notifier).restore(),
              ),
            ),
            _ => Semantics(
              label: l10n.loading,
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/logos/aeenci-symbole.svg',
                      width: 96,
                      height: 96,
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ],
                ),
              ),
            ),
          },
        ),
      ),
    );
  }
}
