// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source : docs/design/tokens.json.
// Régénérer avec `dart run tool/generate_theme.dart`.

import 'package:flutter/material.dart';

/// Les couleurs du design system, pour le thème clair ou sombre.
///
/// Accès dans un widget : `context.colors.green`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.green,
    required this.greenSoft,
    required this.onGreen,
    required this.blue,
    required this.blueSoft,
    required this.onBlue,
    required this.red,
    required this.redSoft,
    required this.link,
    required this.focus,
    required this.danger,
  });

  /// Fond de page.
  final Color surface;

  /// Cartes, menus, formulaires posés sur surface.
  final Color surfaceRaised;

  /// Filets, séparateurs, bordures de champs au repos.
  final Color line;

  /// Texte principal, sur surface et surface-raised.
  final Color ink;

  /// Texte secondaire, métadonnées, légendes, sur surface et surface-raised.
  final Color inkMuted;

  /// Couleur principale, celle des rubans du logo et du drapeau nigérian : boutons principaux, en-têtes, éléments de marque. En texte, sur surface ou green-soft.
  final Color green;

  /// Fond teinté de sections et de badges, derrière un texte green ou ink.
  final Color greenSoft;

  /// Texte et icônes posés sur un aplat green (libellé du bouton principal).
  final Color onGreen;

  /// Couleur secondaire, celle de la devise : titres d'accroche, liens, éléments de navigation. En texte, sur surface ou blue-soft.
  final Color blue;

  /// Fond teinté derrière un texte blue (encarts, étiquettes de catégorie).
  final Color blueSoft;

  /// Texte posé sur un aplat blue (bandeau, bouton secondaire plein).
  final Color onBlue;

  /// Accent rare, celui du nom AEENCI : chiffres clés, badge « Nouveau », un mot souligné. Jamais en grande surface. En texte, sur surface ou red-soft.
  final Color red;

  /// Fond teinté derrière un texte red (badge, alerte d'erreur).
  final Color redSoft;

  /// Liens : alias de blue.
  final Color link;

  /// Anneau de focus clavier, 2px, sur tous les éléments interactifs.
  final Color focus;

  /// Erreurs de formulaire et actions destructrices.
  final Color danger;

  static const light = AppColors(
    surface: Color(0xFFFBFAF6),
    surfaceRaised: Color(0xFFFFFFFF),
    line: Color(0xFFE1E5DD),
    ink: Color(0xFF13201A),
    inkMuted: Color(0xFF55615A),
    green: Color(0xFF008751),
    greenSoft: Color(0xFFE3F4EB),
    onGreen: Color(0xFFFFFFFF),
    blue: Color(0xFF2B3990),
    blueSoft: Color(0xFFE8EBF8),
    onBlue: Color(0xFFFFFFFF),
    red: Color(0xFFD7262E),
    redSoft: Color(0xFFFDE8E8),
    link: Color(0xFF2B3990),
    focus: Color(0xFF2B3990),
    danger: Color(0xFFD7262E),
  );

  static const dark = AppColors(
    surface: Color(0xFF0F1713),
    surfaceRaised: Color(0xFF17221C),
    line: Color(0xFF2B3A31),
    ink: Color(0xFFEEF3EF),
    inkMuted: Color(0xFFA7B4AC),
    green: Color(0xFF34C27F),
    greenSoft: Color(0xFF0F2F20),
    onGreen: Color(0xFF08140E),
    blue: Color(0xFF9AA6F2),
    blueSoft: Color(0xFF1C2350),
    onBlue: Color(0xFF0D1230),
    red: Color(0xFFFF7378),
    redSoft: Color(0xFF3A1214),
    link: Color(0xFF9AA6F2),
    focus: Color(0xFF9AA6F2),
    danger: Color(0xFFFF7378),
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? ink,
    Color? inkMuted,
    Color? green,
    Color? greenSoft,
    Color? onGreen,
    Color? blue,
    Color? blueSoft,
    Color? onBlue,
    Color? red,
    Color? redSoft,
    Color? link,
    Color? focus,
    Color? danger,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      onGreen: onGreen ?? this.onGreen,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      onBlue: onBlue ?? this.onBlue,
      red: red ?? this.red,
      redSoft: redSoft ?? this.redSoft,
      link: link ?? this.link,
      focus: focus ?? this.focus,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      onGreen: Color.lerp(onGreen, other.onGreen, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      onBlue: Color.lerp(onBlue, other.onBlue, t)!,
      red: Color.lerp(red, other.red, t)!,
      redSoft: Color.lerp(redSoft, other.redSoft, t)!,
      link: Color.lerp(link, other.link, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Espacements, grille de 4 px.
abstract final class AppSpacing {
  /// Écart icône–texte, espacements internes très serrés.
  static const double space1 = 4;

  /// Écart entre éléments d'un même groupe (badges, boutons côte à côte).
  static const double space2 = 8;

  /// Padding vertical des boutons et des champs.
  static const double space3 = 12;

  /// Padding des cartes sur mobile, marge latérale de page sur mobile.
  static const double space4 = 16;

  /// Padding des cartes sur grand écran, gouttière de grille.
  static const double space6 = 24;

  /// Écart entre blocs d'une même section.
  static const double space8 = 32;

  /// Écart entre sections sur mobile.
  static const double space12 = 48;

  /// Écart entre sections sur grand écran.
  static const double space20 = 80;
}

/// Rayons des coins.
abstract final class AppRadius {
  /// Champs de formulaire, petites vignettes.
  static const double sm = 8;

  /// Cartes, encarts, images.
  static const double md = 14;

  /// Grands blocs de section, héros, visuels d'événements.
  static const double lg = 24;

  /// Boutons, badges, filtres : la forme ruban, signature de la marque.
  static const double pill = 999;
}

/// Familles de polices, embarquées dans `assets/fonts/`.
abstract final class AppFontFamilies {
  static const String display = 'Bricolage Grotesque';
  static const String sans = 'Plus Jakarta Sans';
}

/// Un style de texte du design system.
@immutable
class AppTextToken {
  const AppTextToken({
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.letterSpacing,
  });

  final String fontFamily;
  final double fontSize;

  /// Interligne en pixels logiques.
  final double lineHeight;
  final FontWeight fontWeight;
  final double letterSpacing;

  TextStyle toTextStyle({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    height: lineHeight / fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
  );
}

/// Les styles de texte du design system.
abstract final class AppTypography {
  static const displayXl = AppTextToken(
    fontFamily: AppFontFamilies.display,
    fontSize: 56,
    lineHeight: 60,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.12,
  );

  static const display = AppTextToken(
    fontFamily: AppFontFamilies.display,
    fontSize: 40,
    lineHeight: 44,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );

  static const h1 = AppTextToken(
    fontFamily: AppFontFamilies.display,
    fontSize: 32,
    lineHeight: 38,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const h2 = AppTextToken(
    fontFamily: AppFontFamilies.display,
    fontSize: 24,
    lineHeight: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static const h3 = AppTextToken(
    fontFamily: AppFontFamilies.display,
    fontSize: 20,
    lineHeight: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const bodyLg = AppTextToken(
    fontFamily: AppFontFamilies.sans,
    fontSize: 18,
    lineHeight: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const body = AppTextToken(
    fontFamily: AppFontFamilies.sans,
    fontSize: 16,
    lineHeight: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const small = AppTextToken(
    fontFamily: AppFontFamilies.sans,
    fontSize: 14,
    lineHeight: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  static const label = AppTextToken(
    fontFamily: AppFontFamilies.sans,
    fontSize: 13,
    lineHeight: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.26,
  );
}
