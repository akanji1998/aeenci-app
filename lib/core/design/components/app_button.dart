import 'package:flutter/material.dart';

import '../app_theme.dart';

enum AppButtonVariant { primary, secondary, text }

/// Bouton en pilule du design system. Un seul bouton principal par zone.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  final String label;

  /// `null` : bouton désactivé.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  /// Pendant un envoi : indicateur à la place de l'icône, bouton inactif.
  final bool loading;

  /// Prend toute la largeur disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final action = loading ? null : onPressed;
    final leading = loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? null
        : Icon(icon, size: 20);
    final text = Text(label, textAlign: TextAlign.center);

    final button = switch (variant) {
      AppButtonVariant.primary =>
        leading == null
            ? FilledButton(onPressed: action, child: text)
            : FilledButton.icon(onPressed: action, icon: leading, label: text),
      AppButtonVariant.secondary =>
        leading == null
            ? OutlinedButton(onPressed: action, child: text)
            : OutlinedButton.icon(
                onPressed: action,
                icon: leading,
                label: text,
              ),
      AppButtonVariant.text =>
        leading == null
            ? TextButton(onPressed: action, child: text)
            : TextButton.icon(onPressed: action, icon: leading, label: text),
    };

    final semantic = Semantics(
      button: true,
      enabled: action != null,
      // Le libellé reste lu pendant le chargement.
      child: button,
    );
    return expand
        ? SizedBox(width: double.infinity, child: semantic)
        : semantic;
  }
}

/// Espacement standard entre deux boutons empilés.
const appButtonGap = SizedBox(height: AppSpacing.space3);
