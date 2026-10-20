import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/opportunity.dart';
import 'opportunities_providers.dart';
import 'opportunities_screens.dart';

Future<void> showInterestSheet(
  BuildContext context,
  OpportunityDetail opportunity,
) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => InterestSheet(opportunity: opportunity),
);

/// « Je suis intéressé » : accord pour le CV jamais pré-coché, impossible
/// sans CV (lien vers le profil pro).
class InterestSheet extends ConsumerStatefulWidget {
  const InterestSheet({super.key, required this.opportunity});

  final OpportunityDetail opportunity;

  @override
  ConsumerState<InterestSheet> createState() => _InterestSheetState();
}

class _InterestSheetState extends ConsumerState<InterestSheet> {
  // Jamais pré-cochée (règle du projet).
  bool _shareCv = false;
  bool _saving = false;
  String? _error;

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(opportunityActionsProvider)
          .expressInterest(widget.opportunity.id, shareCv: _shareCv);
      if (mounted) Navigator.of(context).pop();
    } on ValidationException catch (error) {
      if (mounted) {
        setState(
          () => _error =
              error.errorFor('share_cv') ??
              error.errorFor('opportunity') ??
              error.message ??
              l10n.saveFailed,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = errorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final profile = ref.watch(professionalProfileProvider).value?.data;
    // Tant que le profil n'est pas lu, la case reste désactivée.
    final hasCv = profile?.cvUrl != null;
    return SafeArea(
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
              child: Text(
                l10n.interestButton(genderKey(ref)),
                style: context.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(l10n.interestSheetText, style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.space3),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _shareCv,
              onChanged: hasCv && !_saving
                  ? (value) => setState(() => _shareCv = value ?? false)
                  : null,
              title: Text(
                l10n.interestShareCv,
                style: context.textTheme.bodyMedium,
              ),
            ),
            if (profile != null && !hasCv) ...[
              Text(l10n.interestNoCv, style: context.textTheme.bodySmall),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton.text(
                  label: l10n.interestAddCv,
                  compact: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.profilePro);
                  },
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space2),
                child: Text(
                  _error!,
                  style: context.textTheme.bodySmall?.copyWith(color: c.danger),
                ),
              ),
            const SizedBox(height: AppSpacing.space4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                AppButton.text(
                  label: l10n.cancel,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
                AppButton(
                  label: l10n.interestConfirm,
                  loading: _saving,
                  onPressed: _confirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
