import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/components/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// Démarrage : symbole pendant la lecture de la configuration et de la
/// session, erreur avec « Réessayer » si la fiche ne peut pas être chargée.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  /// Taille du symbole de l'écran natif : 640 px dans `splash.png`
  /// (1152 px), que flutter_native_splash traite comme une image @4x, soit
  /// 160 points. Même taille et même place : la transition ne se voit pas.
  static const _nativeSymbolSize = 160.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: switch (session) {
        SessionUnavailable(:final error) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ErrorState(
                error: error,
                onRetry: () =>
                    ref.read(sessionControllerProvider.notifier).restore(),
              ),
            ),
          ),
        ),
        _ => Semantics(
          label: l10n.loading,
          child: ExcludeSemantics(
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/logos/aeenci-symbole.svg',
                    width: _nativeSymbolSize,
                    height: _nativeSymbolSize,
                  ),
                  const Positioned(
                    bottom: AppSpacing.space20,
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}
