import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'password_form.dart';
import 'session_controller.dart';
import 'widgets/auth_layout.dart';

/// Nouveau mot de passe (`/reinitialiser-mot-de-passe?token=…&email=…`).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token, this.email});

  final String? token;
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.email ?? '');
  final _form = GlobalKey<PasswordFormState>();
  String? _emailRequired;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final token = widget.token;
    if (token == null || token.isEmpty) {
      return AuthLayout(
        title: l10n.screenResetPassword,
        children: [
          InvalidLinkView(
            message: l10n.resetLinkInvalid,
            action: AppButton(
              label: l10n.requestNewLink,
              expand: true,
              onPressed: () => context.go(AppRoutes.forgotPassword),
            ),
          ),
        ],
      );
    }

    return AuthLayout(
      title: l10n.screenResetPassword,
      children: [
        PasswordForm(
          key: _form,
          submitLabel: l10n.resetSubmit,
          extraErrorFields: const ['token'],
          leading: [
            Text(l10n.resetIntro, style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.space6),
            AppTextField(
              label: l10n.loginEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              errorText:
                  _emailRequired ?? _form.currentState?.errorFor('email'),
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          onSubmit: (password, confirmation) async {
            final emailError = requiredField(l10n, _email.text);
            setState(() => _emailRequired = emailError);
            if (emailError != null) return;
            try {
              await ref
                  .read(sessionControllerProvider.notifier)
                  .resetPassword(
                    token: token,
                    email: _email.text,
                    password: password,
                    passwordConfirmation: confirmation,
                  );
            } finally {
              // Le champ e-mail relit l'erreur 422 du formulaire.
              if (mounted) setState(() {});
            }
          },
        ),
      ],
    );
  }
}
