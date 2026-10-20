import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/error_state.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Titre de groupe en petites capitales (« MES INFORMATIONS »).
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.toTextStyle(color: context.colors.inkMuted),
      ),
    ),
  );
}

/// Section titrée sur une carte, avec une action facultative (« Modifier »).
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space4),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.space2,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.textTheme.titleLarge),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ...children,
        ],
      ),
    ),
  );
}

/// Libellé et valeur l'un sous l'autre.
class KeyValue extends StatelessWidget {
  const KeyValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
    child: MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.bodySmall),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Groupe de lignes de navigation ou de réglage, séparées par des filets.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          children[i],
        ],
      ],
    ),
  );
}

/// Ligne de navigation : titre, sous-titre ou valeur, chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: danger ? c.danger : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.space2),
                Text(
                  trailing!,
                  style: context.textTheme.titleMedium?.copyWith(color: c.blue),
                ),
              ],
              const SizedBox(width: AppSpacing.space2),
              ExcludeSemantics(
                child: Icon(LucideIcons.chevronRight, color: c.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Message d'un échec d'enregistrement : le premier message 422 s'il n'est
/// rattaché à aucun champ affiché, sinon le message général.
String saveErrorMessage(AppLocalizations l10n, ApiException error) =>
    switch (error) {
      ValidationException(:final errors, :final message) =>
        errors.values.expand((m) => m).firstOrNull ??
            message ??
            l10n.saveFailed,
      _ => errorMessage(l10n, error),
    };
