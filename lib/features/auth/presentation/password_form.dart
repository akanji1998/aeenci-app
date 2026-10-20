import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/components/app_button.dart';
import '../../../core/design/components/app_text_field.dart';
import '../../../core/design/components/error_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/auth_layout.dart';

/// Nouveau mot de passe et confirmation (activation, réinitialisation).
///
/// L'application vérifie seulement que les champs sont remplis et
/// identiques ; les règles (longueur…) viennent du backend, par 422.
class PasswordForm extends StatefulWidget {
  const PasswordForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.leading = const [],
    this.extraErrorFields = const [],
  });

  final String submitLabel;

  /// Envoi ; lève une [ApiException] en cas d'échec.
  final Future<void> Function(String password, String confirmation) onSubmit;

  /// Champs ou textes placés avant les mots de passe.
  final List<Widget> leading;

  /// Champs du 422 affichés en message général (ex. `email`, `token`).
  final List<String> extraErrorFields;

  @override
  State<PasswordForm> createState() => PasswordFormState();
}

class PasswordFormState extends State<PasswordForm> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  String? _passwordLocal;
  String? _confirmationLocal;
  ApiException? _error;

  /// Erreur 422 d'un autre champ (ex. e-mail du lien de réinitialisation).
  String? errorFor(String field) {
    final error = _error;
    return error is ValidationException ? error.errorFor(field) : null;
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final password = _password.text;
    final confirmation = _confirmation.text;
    setState(() {
      _error = null;
      _passwordLocal = requiredField(l10n, password);
      _confirmationLocal =
          requiredField(l10n, confirmation) ??
          (password != confirmation ? l10n.passwordMismatch : null);
    });
    if (_passwordLocal != null || _confirmationLocal != null) return;

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(password, confirmation);
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
    final general = switch (error) {
      null => null,
      ValidationException() => [
        for (final field in widget.extraErrorFields)
          validation!.errorFor(field),
      ].whereType<String>().firstOrNull,
      _ => errorMessage(l10n, error),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...widget.leading,
        AppTextField(
          label: l10n.newPassword,
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordLocal ?? validation?.errorFor('password'),
        ),
        const SizedBox(height: AppSpacing.space4),
        AppTextField(
          label: l10n.passwordConfirmation,
          controller: _confirmation,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText:
              _confirmationLocal ??
              validation?.errorFor('password_confirmation'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.space6),
        if (general != null) ...[
          FormErrorText(general),
          const SizedBox(height: AppSpacing.space3),
        ],
        AppButton(
          label: widget.submitLabel,
          loading: _submitting,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
