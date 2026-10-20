import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/scan_queue_store.dart';
import 'scan_controller.dart';

enum _PendingChoice { sendFirst, signOutAnyway }

/// Déconnexion : si des scans attendent encore leur envoi, on prévient
/// avant de les perdre (la file se vide avec les données du compte).
Future<void> signOutWithScanCheck(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionControllerProvider.notifier);
  final pending = await ref.read(scanQueueStoreProvider).pendingTotal();
  if (pending == 0 || !context.mounted) {
    await session.signOut();
    return;
  }
  final l10n = AppLocalizations.of(context);
  final choice = await showDialog<_PendingChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.signOutPendingTitle),
      content: Text(l10n.signOutPendingText(pending)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.colors.danger),
          onPressed: () =>
              Navigator.of(dialogContext).pop(_PendingChoice.signOutAnyway),
          child: Text(l10n.signOutAnyway),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(_PendingChoice.sendFirst),
          child: Text(l10n.signOutSendFirst),
        ),
      ],
    ),
  );
  switch (choice) {
    case null:
      return;
    case _PendingChoice.signOutAnyway:
      await session.signOut();
    case _PendingChoice.sendFirst:
      try {
        await ref.read(scanSenderProvider).flushAll();
        await session.signOut();
      } on ApiException {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signOutSendFailed)));
        }
      }
  }
}
