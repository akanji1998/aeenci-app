import 'dart:math' as math;

import 'package:aeenci_app/core/design/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rapport de contraste WCAG 2.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Couples sous 4,5:1 dans tokens.json, alors que design-system.md annonce
/// le contraire. À corriger dans les tokens (trois dépôts), pas ici.
const _knownContrastGaps = <String, Set<String>>{
  'clair': {'green / surface', 'green / green-soft', 'red / red-soft'},
  'sombre': {},
};

void main() {
  for (final (name, theme, colors, brightness) in [
    ('clair', AppTheme.light, AppColors.light, Brightness.light),
    ('sombre', AppTheme.dark, AppColors.dark, Brightness.dark),
  ]) {
    group('thème $name', () {
      test('expose les tokens comme extension', () {
        expect(theme.extension<AppColors>(), same(colors));
        expect(theme.brightness, brightness);
      });

      test('le ColorScheme reprend les tokens', () {
        final s = theme.colorScheme;
        expect(s.primary, colors.green);
        expect(s.onPrimary, colors.onGreen);
        expect(s.secondary, colors.blue);
        expect(s.error, colors.danger);
        expect(s.surface, colors.surface);
        expect(s.onSurface, colors.ink);
        expect(s.outline, colors.line);
        expect(theme.scaffoldBackgroundColor, colors.surface);
      });

      test('polices du design system', () {
        expect(
          theme.textTheme.displayLarge!.fontFamily,
          AppFontFamilies.display,
        );
        expect(
          theme.textTheme.headlineMedium!.fontFamily,
          AppFontFamilies.display,
        );
        expect(theme.textTheme.bodyMedium!.fontFamily, AppFontFamilies.sans);
        expect(theme.textTheme.bodyMedium!.fontSize, 16);
        expect(theme.textTheme.bodyLarge!.fontSize, 16);
      });

      test('boutons en pilule, à la hauteur des maquettes', () {
        final filled = theme.filledButtonTheme.style!;
        expect(filled.shape!.resolve({}), isA<StadiumBorder>());
        expect(filled.minimumSize!.resolve({})!.height, AppTheme.controlHeight);
        expect(filled.backgroundColor!.resolve({}), colors.green);
        expect(
          theme.outlinedButtonTheme.style!.shape!.resolve({}),
          isA<StadiumBorder>(),
        );
        expect(
          theme.textButtonTheme.style!.shape!.resolve({}),
          isA<StadiumBorder>(),
        );
        expect(
          theme.textButtonTheme.style!.minimumSize!.resolve({})!.height,
          greaterThanOrEqualTo(AppTheme.minTapTarget),
        );
      });

      test('anneau de focus de 2 px en couleur focus', () {
        final side = theme.filledButtonTheme.style!.side!.resolve({
          WidgetState.focused,
        });
        expect(side!.color, colors.focus);
        expect(side.width, 2);
      });

      test('contrastes des couples texte/fond du design system (≥ 4,5:1)', () {
        final pairs = <String, (Color, Color)>{
          'ink / surface': (colors.ink, colors.surface),
          'ink / surface-raised': (colors.ink, colors.surfaceRaised),
          'ink-muted / surface': (colors.inkMuted, colors.surface),
          'ink-muted / surface-raised': (colors.inkMuted, colors.surfaceRaised),
          'green / surface': (colors.green, colors.surface),
          'green / green-soft': (colors.green, colors.greenSoft),
          'on-green / green': (colors.onGreen, colors.green),
          'blue / surface': (colors.blue, colors.surface),
          'blue / blue-soft': (colors.blue, colors.blueSoft),
          'on-blue / blue': (colors.onBlue, colors.blue),
          'red / surface': (colors.red, colors.surface),
          'red / red-soft': (colors.red, colors.redSoft),
          'on-error / error': (
            theme.colorScheme.onError,
            theme.colorScheme.error,
          ),
        };
        for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
          final ratio = contrast(fg, bg);
          if (_knownContrastGaps[name]!.contains(label)) {
            // Écart connu des tokens, signalé au bureau : réservé aux grands
            // textes ou au texte gras en attendant la correction de tokens.json.
            expect(
              ratio,
              inInclusiveRange(3, 4.5),
              reason: '$label : retirer de _knownContrastGaps si corrigé',
            );
          } else {
            expect(ratio, greaterThanOrEqualTo(4.5), reason: label);
          }
        }
      });
    });
  }

  test('lerp entre les deux thèmes', () {
    final mid = AppColors.light.lerp(AppColors.dark, 0.5);
    expect(
      mid.green,
      Color.lerp(AppColors.light.green, AppColors.dark.green, 0.5),
    );
    expect(AppColors.light.lerp(null, 0.5), same(AppColors.light));
    expect(
      AppColors.light.copyWith(ink: AppColors.dark.ink).ink,
      AppColors.dark.ink,
    );
  });
}
