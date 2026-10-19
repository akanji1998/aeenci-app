import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/env_config.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/error_state.dart';
import '../../../core/mock/mock_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'session_controller.dart';

/// Connexion **provisoire** (lot 1) : formulaire simple et, avec les mocks,
/// un encart pour se connecter en un geste aux comptes de démonstration.
/// Le vrai écran (maquette `app-connexion`) arrive au lot 2.
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn(String email, String password) async {
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
    final c = context.colors;
    final useMocks = ref.watch(envConfigProvider).useMocks;
    final session = ref.watch(sessionControllerProvider);
    final error = _error;
    final validation = error is ValidationException ? error : null;

    final notice = switch (session) {
      SessionSignedOut(reason: SignedOutReason.expired) => l10n.loginExpired,
      SessionSignedOut(reason: SignedOutReason.noMemberProfile) =>
        l10n.loginNoMemberProfile,
      _ => null,
    };

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space8,
            ),
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/logos/aeenci-symbole.svg',
                  width: 80,
                  height: 80,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Semantics(
                header: true,
                child: Text(
                  l10n.loginTitle,
                  style: context.textTheme.headlineLarge,
                ),
              ),
              if (notice != null) ...[
                const SizedBox(height: AppSpacing.space4),
                _Notice(text: notice),
              ],
              const SizedBox(height: AppSpacing.space6),
              AppTextField(
                label: l10n.loginEmail,
                hint: l10n.loginEmailHint,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: validation?.errorFor('email'),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppTextField(
                label: l10n.loginPassword,
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                errorText: validation?.errorFor('password'),
                onSubmitted: (_) => _signIn(_email.text, _password.text),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton.text(
                  label: l10n.loginForgotPassword,
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                ),
              ),
              if (error != null && validation == null) ...[
                Text(
                  errorMessage(l10n, error),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: c.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
              ],
              const SizedBox(height: AppSpacing.space2),
              AppButton(
                label: l10n.loginSubmit,
                loading: _submitting,
                expand: true,
                onPressed: () => _signIn(_email.text, _password.text),
              ),
              if (useMocks) ...[
                const SizedBox(height: AppSpacing.space8),
                _MockAccounts(
                  enabled: !_submitting,
                  onPick: (email) => _signIn(email, mockPassword),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.blueSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(color: c.blue),
          ),
        ),
      ),
    );
  }
}

class _MockAccounts extends StatelessWidget {
  const _MockAccounts({required this.enabled, required this.onPick});

  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accounts = <(String, String)>[
      (l10n.loginAsMember, MockPersona.member.email),
      (l10n.loginAsCandidate, MockPersona.candidate.email),
      (l10n.loginAsBureau, MockPersona.bureau.email),
      (l10n.loginAsNoMember, mockNoMemberEmail),
    ];
    return AppCard(
      color: context.colors.greenSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.loginDevAccounts, style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space1),
          Text(l10n.loginDevAccountsHint, style: context.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: [
              for (final (label, email) in accounts)
                AppButton.secondary(
                  label: label,
                  onPressed: enabled ? () => onPick(email) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
