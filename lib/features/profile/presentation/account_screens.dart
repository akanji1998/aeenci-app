import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_card.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/confirm_dialog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/account_repository.dart';
import 'widgets/profile_widgets.dart';

/// Changement de mot de passe. Les autres appareils sont déconnectés.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  ValidationException? _errors;

  @override
  void dispose() {
    for (final c in [_current, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _errors = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            password: _password.text,
            passwordConfirmation: _confirmation.text,
          );
      if (!mounted) return;
      showSnack(context, l10n.passwordChanged);
      context.go(AppRoutes.profile);
    } on ValidationException catch (error) {
      if (mounted) setState(() => _errors = error);
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.passwordTitle)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            Text(l10n.passwordIntro, style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.space4),
            AppTextField(
              label: l10n.currentPassword,
              controller: _current,
              obscure: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.next,
              errorText: _errors?.errorFor('current_password'),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppTextField(
              label: l10n.newPassword,
              controller: _password,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              errorText: _errors?.errorFor('password'),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppTextField(
              label: l10n.passwordConfirmation,
              controller: _confirmation,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              errorText: _errors?.errorFor('password_confirmation'),
            ),
            const SizedBox(height: AppSpacing.space6),
            AppButton(
              label: l10n.save,
              expand: true,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// Suppression du compte de connexion, confirmée par le mot de passe.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (_password.text.isEmpty) {
      setState(() => _error = l10n.fieldRequired);
      return;
    }
    final confirmed = await confirmDialog(
      context,
      title: l10n.deleteTitle,
      message: l10n.deleteKept,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      // Le garde de navigation renvoie ensuite à la connexion.
      await ref
          .read(sessionControllerProvider.notifier)
          .deleteAccount(password: _password.text);
    } on ValidationException catch (error) {
      if (mounted) {
        setState(() => _error = error.errorFor('password') ?? error.message);
      }
    } on ApiException catch (error) {
      if (mounted) showSnack(context, saveErrorMessage(l10n, error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          Text(l10n.deleteIntro, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.space3),
          AppCard(
            child: Text(l10n.deleteKept, style: context.textTheme.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppTextField(
            label: l10n.deletePasswordLabel,
            controller: _password,
            obscure: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            errorText: _error,
          ),
          const SizedBox(height: AppSpacing.space6),
          // Bouton destructif au trait : texte et filet rouges.
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.danger,
              side: BorderSide(color: c.danger, width: 1.5),
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            onPressed: _deleting ? null : _delete,
            child: _deleting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.deleteConfirm, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
