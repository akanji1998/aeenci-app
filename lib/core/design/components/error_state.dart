import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../api/api_exception.dart';
import 'empty_state.dart';

/// Message clair pour une erreur, quelle qu'elle soit.
String errorMessage(AppLocalizations l10n, Object error) => switch (error) {
  NetworkException() => l10n.errorNetwork,
  ServerException() => l10n.errorServer,
  ForbiddenException() => l10n.errorForbidden,
  NotFoundException() => l10n.errorNotFound,
  GoneException() => l10n.errorGone,
  TooManyRequestsException() => l10n.errorTooManyRequests,
  _ => l10n.errorUnknown,
};

/// Erreur de chargement, avec « Réessayer ».
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: error is NetworkException
          ? LucideIcons.wifiOff
          : LucideIcons.circleAlert,
      title: l10n.errorTitle,
      message: errorMessage(l10n, error),
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}
