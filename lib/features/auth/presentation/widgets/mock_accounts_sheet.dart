import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_button.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Comptes et liens de démonstration (saveur dev avec mocks seulement).
Future<void> showMockAccountsSheet(
  BuildContext context, {
  required void Function(String email, String password) onAccount,
}) {
  final l10n = AppLocalizations.of(context);
  final accounts = <(String, String)>[
    (l10n.loginAsMember, MockPersona.member.email),
    (l10n.loginAsCandidate, MockPersona.candidate.email),
    (l10n.loginAsRejectedCandidate, MockPersona.rejectedCandidate.email),
    (l10n.loginAsBureau, MockPersona.bureau.email),
    (l10n.loginAsNoMember, mockNoMemberEmail),
  ];
  final links = <(String, String)>[
    (
      l10n.loginDevActivation,
      Uri(
        path: AppRoutes.activateAccount,
        queryParameters: {'token': MockInvitations.valid},
      ).toString(),
    ),
    (
      l10n.loginDevActivationExpired,
      Uri(
        path: AppRoutes.activateAccount,
        queryParameters: {'token': MockInvitations.expired},
      ).toString(),
    ),
    (
      l10n.loginDevReset,
      Uri(
        path: AppRoutes.resetPassword,
        queryParameters: {
          'token': mockResetToken,
          'email': MockPersona.member.email,
        },
      ).toString(),
    ),
  ];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          0,
          AppSpacing.space6,
          AppSpacing.space6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loginDevAccounts,
              style: sheetContext.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              spacing: AppSpacing.space2,
              runSpacing: AppSpacing.space2,
              children: [
                for (final (label, email) in accounts)
                  AppButton.secondary(
                    label: label,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onAccount(email, mockPassword);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(l10n.loginDevLinks, style: sheetContext.textTheme.titleMedium),
            for (final (label, location) in links)
              AppButton.text(
                label: label,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(location);
                },
              ),
          ],
        ),
      ),
    ),
  );
}
