import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/contribution.dart';
import 'contributions_providers.dart';
import 'contributions_screen.dart';

/// Feuille « Reçu REC-… » : ouvrir le PDF, le partager, fermer.
Future<void> showReceiptSheet(
  BuildContext context, {
  required Payment payment,
  required String label,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ReceiptSheet(payment: payment, label: label),
);

class _ReceiptSheet extends ConsumerStatefulWidget {
  const _ReceiptSheet({required this.payment, required this.label});

  final Payment payment;
  final String label;

  @override
  ConsumerState<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends ConsumerState<_ReceiptSheet> {
  bool? _stored;
  bool _opening = false;
  bool _sharing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(receiptActionsProvider).isStored(widget.payment).then((stored) {
      if (mounted) setState(() => _stored = stored);
    });
  }

  Future<void> _run(
    Future<void> Function() action,
    void Function(bool busy) setBusy,
  ) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      setBusy(true);
      _error = null;
    });
    try {
      await action();
      final stored = await ref
          .read(receiptActionsProvider)
          .isStored(widget.payment);
      if (mounted) setState(() => _stored = stored);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = receiptErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => setBusy(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final actions = ref.read(receiptActionsProvider);
    final number = widget.payment.receiptNumber;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          0,
          AppSpacing.space6,
          AppSpacing.space6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.receiptTitle(number),
                style: context.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              _stored ?? false
                  ? l10n.receiptStored(widget.label)
                  : l10n.receiptNotStored(widget.label),
              style: context.textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.danger,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                AppButton(
                  label: l10n.receiptOpen,
                  icon: LucideIcons.fileText,
                  compact: true,
                  loading: _opening,
                  onPressed: _sharing
                      ? null
                      : () => _run(() async {
                          final opened = await actions.open(widget.payment);
                          if (!opened && mounted) {
                            setState(() => _error = l10n.receiptNoViewer);
                          }
                        }, (busy) => _opening = busy),
                ),
                AppButton.secondary(
                  label: l10n.receiptShare,
                  icon: LucideIcons.share2,
                  compact: true,
                  loading: _sharing,
                  onPressed: _opening
                      ? null
                      : () => _run(
                          () => actions.share(
                            widget.payment,
                            text: l10n.receiptShareText(number),
                          ),
                          (busy) => _sharing = busy,
                        ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton.text(
                label: l10n.receiptClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
