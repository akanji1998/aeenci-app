import 'package:flutter/material.dart';

import 'tokens.g.dart';

export 'tokens.g.dart';

/// Les thèmes clair et sombre, construits uniquement à partir des tokens.
abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  /// Hauteur des boutons et des champs, comme dans les maquettes.
  static const double controlHeight = 54;

  /// Cible tactile minimale (accessibilité).
  static const double minTapTarget = 48;

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.green,
      onPrimary: c.onGreen,
      primaryContainer: c.greenSoft,
      onPrimaryContainer: c.green,
      secondary: c.blue,
      onSecondary: c.onBlue,
      secondaryContainer: c.blueSoft,
      onSecondaryContainer: c.blue,
      tertiary: c.red,
      // Pas de token « on-red » : on-green est blanc en clair et presque noir
      // en sombre, ce qui convient aussi sur red (contraste vérifié en test).
      onTertiary: c.onGreen,
      tertiaryContainer: c.redSoft,
      onTertiaryContainer: c.red,
      error: c.danger,
      onError: c.onGreen,
      errorContainer: c.redSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      surfaceTint: Colors.transparent,
      outline: c.line,
      outlineVariant: c.line,
    );

    final textTheme = _textTheme(c);
    final buttonLabel = AppTypography.body.toTextStyle().copyWith(
      fontWeight: FontWeight.w700,
    );
    const pill = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.space6,
      vertical: AppSpacing.space3,
    );
    final focusRing = WidgetStateProperty.resolveWith<BorderSide?>(
      (states) => states.contains(WidgetState.focused)
          ? BorderSide(color: c.focus, width: 2)
          : null,
    );

    OutlineInputBorder fieldBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      fontFamily: AppFontFamilies.sans,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      dividerColor: c.line,
      // Ondulation simple : plus légère que InkSparkle sur les téléphones modestes.
      splashFactory: InkRipple.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.green,
          foregroundColor: c.onGreen,
          disabledBackgroundColor: c.line,
          disabledForegroundColor: c.inkMuted,
          minimumSize: const Size(minTapTarget, controlHeight),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonLabel,
          elevation: 0,
        ).copyWith(side: focusRing),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: c.green,
              disabledForegroundColor: c.inkMuted,
              minimumSize: const Size(minTapTarget, controlHeight),
              padding: buttonPadding,
              shape: pill,
              textStyle: buttonLabel,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => switch (states) {
                  _ when states.contains(WidgetState.focused) => BorderSide(
                    color: c.focus,
                    width: 2,
                  ),
                  _ when states.contains(WidgetState.disabled) => BorderSide(
                    color: c.line,
                    width: 1.5,
                  ),
                  _ => BorderSide(color: c.green, width: 1.5),
                },
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.link,
          disabledForegroundColor: c.inkMuted,
          minimumSize: const Size(minTapTarget, minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
          shape: pill,
          textStyle: buttonLabel,
        ).copyWith(side: focusRing),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size(minTapTarget, minTapTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: c.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space4,
        ),
        border: fieldBorder(c.line, 1.5),
        enabledBorder: fieldBorder(c.line, 1.5),
        focusedBorder: fieldBorder(c.focus, 2),
        errorBorder: fieldBorder(c.danger, 1.5),
        focusedErrorBorder: fieldBorder(c.danger, 2),
        disabledBorder: fieldBorder(c.line, 1),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.inkMuted),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: c.ink,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.inkMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: c.inkMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: c.danger),
        errorMaxLines: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onGreen : c.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.green : c.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.green : c.inkMuted,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: c.greenSoft,
          selectedForegroundColor: c.green,
          foregroundColor: c.ink,
          side: BorderSide(color: c.line, width: 1.5),
          shape: pill,
          minimumSize: const Size(minTapTarget, minTapTarget),
          textStyle: AppTypography.label.toTextStyle(),
        ),
      ),
      // Barre d'onglets des maquettes : pas de pastille, onglet actif en vert.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.label.toTextStyle().copyWith(
            fontSize: 12,
            letterSpacing: 0,
            color: states.contains(WidgetState.selected) ? c.green : c.inkMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? c.green : c.inkMuted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.green),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppColors c) {
    TextStyle style(AppTextToken token, [Color? color]) =>
        token.toTextStyle(color: color ?? c.ink);

    final body = style(AppTypography.body);
    final small = style(AppTypography.small);
    return TextTheme(
      displayLarge: style(AppTypography.displayXl),
      displayMedium: style(AppTypography.display),
      displaySmall: style(AppTypography.h1),
      headlineLarge: style(AppTypography.h1),
      headlineMedium: style(AppTypography.h2),
      headlineSmall: style(AppTypography.h3),
      titleLarge: style(AppTypography.h3),
      titleMedium: body.copyWith(fontWeight: FontWeight.w700),
      titleSmall: small.copyWith(fontWeight: FontWeight.w600),
      // Le texte courant ne descend jamais sous `body` (16 px). bodyLarge
      // reste à 16 px : c'est le style des champs de saisie. Pour les chapeaux,
      // AppTypography.bodyLg.
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: style(AppTypography.small, c.inkMuted),
      labelLarge: style(AppTypography.label),
      labelMedium: style(AppTypography.label),
      labelSmall: style(AppTypography.label),
    );
  }
}

extension AppThemeContext on BuildContext {
  /// Les couleurs du thème courant.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
