import 'package:flutter/material.dart';

import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_button.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Ouvre une feuille de formulaire au-dessus des onglets.
Future<void> showFormSheet(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );

/// Mise en page d'une feuille de formulaire : titre, champs défilants,
/// boutons Annuler / Enregistrer, et un bouton Supprimer facultatif.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
    this.saving = false,
    this.onDelete,
    this.deleteLabel,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final bool saving;
  final VoidCallback? onDelete;
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            0,
            AppSpacing.space4,
            AppSpacing.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.textTheme.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.space4),
              ...children,
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: [
                  AppButton.text(
                    label: l10n.cancel,
                    onPressed: saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  AppButton(
                    label: l10n.save,
                    loading: saving,
                    onPressed: onSave,
                  ),
                ],
              ),
              if (onDelete != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.danger,
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: saving ? null : onDelete,
                    child: Text(deleteLabel ?? l10n.delete),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Espace sous chaque champ d'une feuille.
class FieldGap extends StatelessWidget {
  const FieldGap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
    child: child,
  );
}
