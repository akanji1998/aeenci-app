import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/design/components/skeleton.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_repository.dart';
import '../domain/invitation.dart';
import 'password_form.dart';
import 'session_controller.dart';
import 'widgets/auth_layout.dart';

/// Invitation lue d'après le jeton du lien.
final invitationProvider = FutureProvider.autoDispose
    .family<Invitation, String>(
      (ref, token) => ref.watch(authRepositoryProvider).fetchInvitation(token),
    );

/// Activation d'un compte recensé (`/activer-mon-compte?token=…`).
class ActivateAccountScreen extends ConsumerWidget {
  const ActivateAccountScreen({super.key, required this.token});

  /// Jeton du lien ; `null` ou vide si le lien est incomplet.
  final String? token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final token = this.token;
    if (token == null || token.isEmpty) {
      return AuthLayout(
        title: l10n.screenActivateAccount,
        children: [InvalidLinkView(message: l10n.invitationNotFound)],
      );
    }

    final invitation = ref.watch(invitationProvider(token));
    return AuthLayout(
      title: l10n.screenActivateAccount,
      children: [
        switch (invitation) {
          AsyncData(:final value) => PasswordForm(
            submitLabel: l10n.activationSubmit,
            extraErrorFields: const ['token'],
            leading: [
              AuthTitle(l10n.activationGreeting(value.firstNames)),
              const SizedBox(height: AppSpacing.space2),
              Text(l10n.activationIntro, style: context.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.space6),
            ],
            onSubmit: (password, confirmation) async {
              try {
                await ref
                    .read(sessionControllerProvider.notifier)
                    .activate(
                      token: token,
                      password: password,
                      passwordConfirmation: confirmation,
                    );
              } on GoneException {
                // Utilisée ou expirée entre-temps : on relit l'invitation.
                ref.invalidate(invitationProvider(token));
              }
            },
          ),
          AsyncError(error: NotFoundException()) => InvalidLinkView(
            message: l10n.invitationNotFound,
          ),
          AsyncError(error: GoneException()) => InvalidLinkView(
            message: l10n.invitationExpired,
          ),
          AsyncError(:final error) => ErrorState(
            error: error,
            onRetry: () => ref.invalidate(invitationProvider(token)),
          ),
          _ => const SkeletonList(count: 1),
        },
      ],
    );
  }
}
