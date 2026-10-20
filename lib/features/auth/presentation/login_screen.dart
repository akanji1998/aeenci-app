import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/env_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/utils/external_links.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';
import 'widgets/auth_layout.dart';
import 'widgets/mock_accounts_sheet.dart';

/// Connexion (maquette `app-connexion`).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  ApiException? _error;
  String? _emailRequired;
  String? _passwordRequired;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _emailRequired = requiredField(l10n, _email.text);
      _passwordRequired = requiredField(l10n, _password.text);
      _error = null;
    });
    if (_emailRequired != null || _passwordRequired != null) return;
    await signInWith(_email.text, _password.text);
  }

  /// Aussi utilisé par l'encart des comptes de démonstration.
  Future<void> signInWith(String email, String password) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // En cas de succès, la garde du routeur quitte cet écran.
      await ref
          .read(sessionControllerProvider.notifier)
          .signIn(email: email, password: password);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final env = ref.watch(envConfigProvider);
    final session = ref.watch(sessionControllerProvider);
    final error = _error;
    final validation = error is ValidationException ? error : null;

    final notice = switch (session) {
      SessionSignedOut(reason: SignedOutReason.expired) => l10n.loginExpired,
      SessionSignedOut(reason: SignedOutReason.noMemberProfile) =>
        l10n.loginNoMemberProfile,
      _ => null,
    };

    return AuthLayout(
      children: [
        const SizedBox(height: AppSpacing.space6),
        const BrandHeader(),
        const SizedBox(height: AppSpacing.space8),
        AuthTitle(l10n.loginTitle),
        if (notice != null) ...[
          const SizedBox(height: AppSpacing.space4),
          NoticeBox(notice),
        ],
        const SizedBox(height: AppSpacing.space4),
        AppTextField(
          label: l10n.loginEmail,
          hint: l10n.loginEmailHint,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailRequired ?? validation?.errorFor('email'),
        ),
        const SizedBox(height: AppSpacing.space4),
        AppTextField(
          label: l10n.loginPassword,
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordRequired ?? validation?.errorFor('password'),
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: AppButton.text(
            label: l10n.loginForgotPassword,
            onPressed: () => context.push(AppRoutes.forgotPassword),
          ),
        ),
        if (error != null && validation == null) ...[
          FormErrorText(errorMessage(l10n, error)),
          const SizedBox(height: AppSpacing.space3),
        ],
        AppButton(
          label: l10n.loginSubmit,
          loading: _submitting,
          expand: true,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.space8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loginNoAccountTitle,
                style: context.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(l10n.loginNoAccountText, style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.space1),
              AppButton.text(
                label: l10n.loginJoinLink,
                onPressed: () => openExternal(SiteLinks.membership),
              ),
            ],
          ),
        ),
        // Comptes factices : saveur dev avec mocks seulement.
        if (env.isDev && env.useMocks) ...[
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: AppButton.text(
              label: l10n.loginDevAccounts,
              onPressed: _submitting
                  ? null
                  : () => showMockAccountsSheet(context, onAccount: signInWith),
            ),
          ),
        ],
      ],
    );
  }
}
