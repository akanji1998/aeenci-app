import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cache/cached_fetch.dart';
import '../app_theme.dart';
import 'error_state.dart';
import 'offline_banner.dart';
import 'skeleton.dart';

/// Affiche une donnée chargée par l'API (et peut-être lue dans le cache) :
/// squelette pendant le chargement, erreur avec « Réessayer », bandeau
/// « Hors connexion » au-dessus des données en cache.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<Cached<T>> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  /// Squelette propre à l'écran, sinon une liste de cartes fantômes.
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    // Des données déjà affichées restent visibles pendant une actualisation.
    if (value.hasValue) {
      final cached = value.requireValue;
      final content = builder(context, cached.data);
      final offlineSince = cached.offlineSince;
      if (offlineSince == null) return content;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space4,
              AppSpacing.space2,
            ),
            child: OfflineBanner(updatedAt: offlineSince),
          ),
          Expanded(child: content),
        ],
      );
    }
    if (value.hasError) {
      return Center(
        child: SingleChildScrollView(
          child: ErrorState(error: value.error!, onRetry: onRetry),
        ),
      );
    }
    return loading ??
        const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.space4),
          child: SkeletonList(),
        );
  }
}
