import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/design/app_theme.dart';
import '../../../../core/design/components/app_button.dart';
import '../../../../core/design/components/empty_state.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Mise en page des écrans d'authentification (maquette `app-connexion`) :
/// marges de 24 px, défilement, retour facultatif.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.children,
    this.title,
    this.showBack = false,
  });

  final List<Widget> children;

  /// Titre de la barre d'application (avec retour) ; absent sur la connexion.
  final String? title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack || title != null
          ? AppBar(title: title == null ? null : Text(title!))
          : null,
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space6,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Symbole, nom et devise, centrés.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return MergeSemantics(
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/logos/aeenci-symbole.svg',
            width: 96,
            height: 96,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            l10n.appTitle,
            style: AppTypography.h1
                .toTextStyle(color: c.green)
                .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
          Text(l10n.motto, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Titre de page (rôle d'en-tête pour les lecteurs d'écran).
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: context.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Encart d'information sur `blue-soft`.
class NoticeBox extends StatelessWidget {
  const NoticeBox(this.text, {super.key});

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

/// Message d'erreur général d'un formulaire (hors erreurs par champ).
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colors.danger,
        ),
      ),
    );
  }
}

/// Lien expiré, inconnu ou incomplet : explication et retour à la connexion.
class InvalidLinkView extends StatelessWidget {
  const InvalidLinkView({super.key, required this.message, this.action});

  final String message;

  /// Action supplémentaire (ex. « Demander un nouveau lien »).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmptyState(
          icon: LucideIcons.link2Off,
          title: l10n.invalidLinkTitle,
          message: message,
        ),
        if (action != null) ...[action!, appButtonGap],
        AppButton.secondary(
          label: l10n.backToLogin,
          expand: true,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}

/// Vérifie qu'un champ est rempli (règles de fond : le backend, par 422).
String? requiredField(AppLocalizations l10n, String value) =>
    value.trim().isEmpty ? l10n.fieldRequired : null;
