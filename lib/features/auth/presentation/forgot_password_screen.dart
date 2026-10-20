import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/components/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_layout.dart';

/// Mot de passe oublié : `POST /auth/forgot-password`. Le même message
/// s'affiche que l'adresse existe ou non (le backend répond 204).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _submitting = false;
  String? _sentTo;
  String? _required;
  ApiException? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    setState(() {
      _required = requiredField(l10n, email);
      _error = null;
    });
    if (_required != null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email: email);
      if (mounted) setState(() => _sentTo = email);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    final validation = error is ValidationException ? error : null;
    final sentTo = _sentTo;

    return AuthLayout(
      title: l10n.screenForgotPassword,
      children: [
        if (sentTo != null) ...[
          EmptyState(
            icon: LucideIcons.mailCheck,
            title: l10n.forgotPasswordSentTitle,
            message: l10n.forgotPasswordSent(sentTo),
          ),
          AppButton(
            label: l10n.backToLogin,
            expand: true,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ] else ...[
          Text(l10n.forgotPasswordIntro, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.space6),
          AppTextField(
            label: l10n.loginEmail,
            hint: l10n.loginEmailHint,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorText: _required ?? validation?.errorFor('email'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.space6),
          if (error != null && validation == null) ...[
            FormErrorText(errorMessage(l10n, error)),
            const SizedBox(height: AppSpacing.space3),
          ],
          AppButton(
            label: l10n.forgotPasswordSubmit,
            loading: _submitting,
            expand: true,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
