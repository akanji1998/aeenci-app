import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/theme_generator.dart';

Map<String, Object?> _minimalTokens({List<Map<String, Object?>>? colors}) => {
  'color': {
    'tokens':
        colors ??
        [
          {
            'name': 'blue',
            'value': {'light': '#2b3990', 'dark': '#9aa6f2'},
          },
          {'name': 'link', 'value': '{blue}'},
          {'name': 'flat', 'value': '#000000'},
        ],
  },
  'type': {
    'families': {'sans': '"Plus Jakarta Sans", system-ui, sans-serif'},
    'groups': [
      {
        'name': 'Texte',
        'family': 'sans',
        'styles': [
          {
            'name': 'display-xl',
            'fontSize': '50px',
            'lineHeight': '60px',
            'fontWeight': 800,
            'letterSpacing': '-0.02em',
          },
        ],
      },
    ],
  },
  'spacing': {
    'tokens': [
      {'name': 'space-1', 'value': '4px'},
    ],
  },
  'radius': {
    'tokens': [
      {'name': 'radius-pill', 'value': '999px'},
    ],
  },
};

void main() {
  group('parseHexColor', () {
    test('ajoute une opacité pleine à #rrggbb', () {
      expect(parseHexColor('#008751'), 0xFF008751);
    });

    test('lit l\'opacité de #rrggbbaa', () {
      expect(parseHexColor('#00875180'), 0x80008751);
    });

    test('refuse une valeur invalide', () {
      expect(
        () => parseHexColor('green'),
        throwsA(isA<TokenFormatException>()),
      );
      expect(() => parseHexColor('#fff'), throwsA(isA<TokenFormatException>()));
    });
  });

  group('unités', () {
    test('parsePx', () {
      expect(parsePx('14px'), 14);
      expect(parsePx('0.5px'), 0.5);
      expect(() => parsePx('14'), throwsA(isA<TokenFormatException>()));
    });

    test('parseLetterSpacing convertit les em en pixels', () {
      expect(parseLetterSpacing('-0.02em', 56), closeTo(-1.12, 1e-9));
      expect(parseLetterSpacing(null, 16), 0);
      expect(
        () => parseLetterSpacing('2px', 16),
        throwsA(isA<TokenFormatException>()),
      );
    });
  });

  test('camelCase et firstFontFamily', () {
    expect(camelCase('surface-raised'), 'surfaceRaised');
    expect(camelCase('space-12'), 'space12');
    expect(camelCase('ink'), 'ink');
    expect(
      firstFontFamily('"Bricolage Grotesque", "Plus Jakarta Sans", sans-serif'),
      'Bricolage Grotesque',
    );
  });

  group('parseTokens', () {
    test('résout les alias et les valeurs uniques', () {
      final tokens = parseTokens(_minimalTokens());
      final byName = {for (final c in tokens.colors) c.name: c};
      expect(byName['link']!.light, 0xFF2B3990);
      expect(byName['link']!.dark, 0xFF9AA6F2);
      expect(byName['flat']!.light, byName['flat']!.dark);
    });

    test('lit les styles de texte, espacements et rayons', () {
      final tokens = parseTokens(_minimalTokens());
      final style = tokens.textStyles.single;
      expect(style.fontSize, 50);
      expect(style.lineHeight, 60);
      expect(style.fontWeight, 800);
      expect(style.letterSpacing, closeTo(-1, 1e-9));
      expect(tokens.families['sans'], 'Plus Jakarta Sans');
      expect(tokens.spacing.single.value, 4);
      expect(tokens.radius.single.value, 999);
    });

    test('refuse un alias inconnu', () {
      expect(
        () => parseTokens(
          _minimalTokens(
            colors: [
              {'name': 'link', 'value': '{nope}'},
            ],
          ),
        ),
        throwsA(isA<TokenFormatException>()),
      );
    });

    test('refuse un alias circulaire', () {
      expect(
        () => parseTokens(
          _minimalTokens(
            colors: [
              {'name': 'a', 'value': '{b}'},
              {'name': 'b', 'value': '{a}'},
            ],
          ),
        ),
        throwsA(isA<TokenFormatException>()),
      );
    });
  });

  group('docs/design/tokens.json', () {
    late DesignTokens tokens;

    setUpAll(() {
      final json = jsonDecode(
        File('docs/design/tokens.json').readAsStringSync(),
      );
      tokens = parseTokens(json as Map<String, Object?>);
    });

    test('contient toutes les couleurs attendues par le thème', () {
      expect(
        tokens.colors.map((c) => c.name),
        containsAll(<String>[
          'surface',
          'surface-raised',
          'line',
          'ink',
          'ink-muted',
          'green',
          'green-soft',
          'on-green',
          'blue',
          'blue-soft',
          'on-blue',
          'red',
          'red-soft',
          'link',
          'focus',
          'danger',
        ]),
      );
    });

    test('le code produit déclare les classes du thème', () {
      final source = renderTokens(tokens);
      expect(
        source,
        contains('class AppColors extends ThemeExtension<AppColors>'),
      );
      expect(source, contains('static const double pill = 999;'));
      expect(
        source,
        contains("static const String display = 'Bricolage Grotesque';"),
      );
      expect(source, contains('static const displayXl = AppTextToken('));
      expect(source, contains('green: Color(0xFF008751),'));
    });

    test('lib/core/design/tokens.g.dart est à jour', () {
      // Comparaison sans les espaces : le fichier commité est passé par `dart format`.
      String squash(String s) => s
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',)', ')')
          .replaceAll(',]', ']')
          .replaceAll(',}', '}');
      final committed = File(
        'lib/core/design/tokens.g.dart',
      ).readAsStringSync();
      expect(
        squash(committed),
        squash(renderTokens(tokens)),
        reason:
            'Lancer `dart run tool/generate_theme.dart` après avoir modifié tokens.json.',
      );
    });
  });
}
