/// Lecture de `docs/design/tokens.json` et génération de
/// `lib/core/design/tokens.g.dart`.
///
/// Les fonctions sont pures pour être testées sans toucher au disque.
library;

/// Une couleur et ses deux valeurs, en ARGB 32 bits.
class ColorToken {
  const ColorToken(this.name, this.light, this.dark, this.usage);

  final String name;
  final int light;
  final int dark;
  final String usage;
}

/// Une valeur numérique en pixels logiques (espacement ou rayon).
class SizeToken {
  const SizeToken(this.name, this.value, this.usage);

  final String name;
  final double value;
  final String usage;
}

/// Un style de texte.
class TextToken {
  const TextToken({
    required this.name,
    required this.family,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    required this.letterSpacing,
  });

  final String name;

  /// `display` ou `sans`.
  final String family;
  final double fontSize;
  final double lineHeight;
  final int fontWeight;

  /// En pixels logiques (les `em` sont convertis).
  final double letterSpacing;
}

/// L'ensemble des tokens lus.
class DesignTokens {
  const DesignTokens({
    required this.colors,
    required this.spacing,
    required this.radius,
    required this.families,
    required this.textStyles,
  });

  final List<ColorToken> colors;
  final List<SizeToken> spacing;
  final List<SizeToken> radius;

  /// `display` / `sans` → nom de la première police de la pile CSS.
  final Map<String, String> families;
  final List<TextToken> textStyles;
}

class TokenFormatException implements Exception {
  TokenFormatException(this.message);

  final String message;

  @override
  String toString() => 'TokenFormatException: $message';
}

/// `#rrggbb` ou `#rrggbbaa` → ARGB.
int parseHexColor(String value) {
  final match = RegExp(
    r'^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$',
  ).firstMatch(value.trim());
  if (match == null) {
    throw TokenFormatException('Couleur invalide : "$value"');
  }
  final rgb = int.parse(match.group(1)!, radix: 16);
  final alpha = match.group(2) == null
      ? 0xff
      : int.parse(match.group(2)!, radix: 16);
  return (alpha << 24) | rgb;
}

/// `12px` → 12.
double parsePx(String value) {
  final match = RegExp(r'^(-?\d+(?:\.\d+)?)px$').firstMatch(value.trim());
  if (match == null) {
    throw TokenFormatException('Valeur en px attendue : "$value"');
  }
  return double.parse(match.group(1)!);
}

/// `-0.02em` avec une taille de 56 → -1.12 ; absent → 0.
double parseLetterSpacing(String? value, double fontSize) {
  if (value == null) return 0;
  final match = RegExp(r'^(-?\d+(?:\.\d+)?)em$').firstMatch(value.trim());
  if (match == null) {
    throw TokenFormatException('Valeur en em attendue : "$value"');
  }
  return double.parse(match.group(1)!) * fontSize;
}

/// `"Bricolage Grotesque", "Plus Jakarta Sans", sans-serif` → `Bricolage Grotesque`.
String firstFontFamily(String stack) {
  final first = stack.split(',').first.trim();
  return first.replaceAll('"', '').replaceAll("'", '');
}

/// `surface-raised` → `surfaceRaised`, `space-1` → `space1`.
String camelCase(String name) {
  final parts = name.split('-');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
          .join();
}

T _field<T>(Map<String, Object?> map, String key, String context) {
  final value = map[key];
  if (value is! T) {
    throw TokenFormatException('$context : champ "$key" manquant ou invalide');
  }
  return value;
}

List<Map<String, Object?>> _objects(Object? list, String context) {
  if (list is! List<Object?>) {
    throw TokenFormatException('$context : liste attendue');
  }
  return [
    for (final item in list)
      if (item is Map<String, Object?>)
        item
      else
        throw TokenFormatException('$context : objet attendu'),
  ];
}

List<ColorToken> _parseColors(Map<String, Object?> json) {
  final color = _field<Map<String, Object?>>(json, 'color', 'racine');
  final raw = _objects(color['tokens'], 'color.tokens');
  final byName = {
    for (final t in raw) _field<String>(t, 'name', 'color.tokens'): t,
  };
  final resolved = <String, (int, int)>{};

  (int, int) resolve(String name, List<String> stack) {
    final cached = resolved[name];
    if (cached != null) return cached;
    if (stack.contains(name)) {
      throw TokenFormatException(
        'Alias circulaire : ${[...stack, name].join(' → ')}',
      );
    }
    final token = byName[name];
    if (token == null) {
      throw TokenFormatException('Alias inconnu : "{$name}"');
    }
    final value = token['value'];
    final (int, int) result;
    if (value is String) {
      final alias = RegExp(r'^\{([\w-]+)\}$').firstMatch(value.trim());
      if (alias != null) {
        result = resolve(alias.group(1)!, [...stack, name]);
      } else {
        final argb = parseHexColor(value);
        result = (argb, argb);
      }
    } else if (value is Map<String, Object?>) {
      result = (
        parseHexColor(_field<String>(value, 'light', 'couleur $name')),
        parseHexColor(_field<String>(value, 'dark', 'couleur $name')),
      );
    } else {
      throw TokenFormatException('Valeur invalide pour la couleur "$name"');
    }
    return resolved[name] = result;
  }

  return [
    for (final MapEntry(key: name, value: token) in byName.entries)
      ColorToken(
        name,
        resolve(name, []).$1,
        resolve(name, []).$2,
        (token['usage'] as String?) ?? '',
      ),
  ];
}

List<SizeToken> _parseSizes(Map<String, Object?> json, String key) {
  final group = _field<Map<String, Object?>>(json, key, 'racine');
  return [
    for (final t in _objects(group['tokens'], '$key.tokens'))
      SizeToken(
        _field<String>(t, 'name', key),
        parsePx(_field<String>(t, 'value', key)),
        (t['usage'] as String?) ?? '',
      ),
  ];
}

DesignTokens parseTokens(Map<String, Object?> json) {
  final type = _field<Map<String, Object?>>(json, 'type', 'racine');
  final families = _field<Map<String, Object?>>(type, 'families', 'type');
  final textStyles = <TextToken>[];
  for (final group in _objects(type['groups'], 'type.groups')) {
    final family = _field<String>(group, 'family', 'type.groups');
    if (!families.containsKey(family)) {
      throw TokenFormatException('Famille inconnue : "$family"');
    }
    for (final style in _objects(group['styles'], 'type.groups.styles')) {
      final name = _field<String>(style, 'name', 'style');
      final fontSize = parsePx(_field<String>(style, 'fontSize', name));
      textStyles.add(
        TextToken(
          name: name,
          family: family,
          fontSize: fontSize,
          lineHeight: parsePx(_field<String>(style, 'lineHeight', name)),
          fontWeight: _field<int>(style, 'fontWeight', name),
          letterSpacing: parseLetterSpacing(
            style['letterSpacing'] as String?,
            fontSize,
          ),
        ),
      );
    }
  }

  return DesignTokens(
    colors: _parseColors(json),
    spacing: _parseSizes(json, 'spacing'),
    radius: _parseSizes(json, 'radius'),
    families: {
      for (final MapEntry(:key, :value) in families.entries)
        key: firstFontFamily(value! as String),
    },
    textStyles: textStyles,
  );
}

String _hex(int argb) =>
    '0x${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';

String _num(double value) {
  final rounded = double.parse(value.toStringAsFixed(4));
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

String _doc(String usage) => usage.isEmpty ? '' : '  /// $usage\n';

/// Produit le source Dart (non formaté : le script appelle `dart format`).
String renderTokens(DesignTokens tokens) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Source : docs/design/tokens.json.')
    ..writeln('// Régénérer avec `dart run tool/generate_theme.dart`.')
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln();

  // Couleurs : une ThemeExtension, une instance par thème.
  final colors = tokens.colors;
  b
    ..writeln(
      '/// Les couleurs du design system, pour le thème clair ou sombre.',
    )
    ..writeln('///')
    ..writeln('/// Accès dans un widget : `context.colors.green`.')
    ..writeln('@immutable')
    ..writeln('class AppColors extends ThemeExtension<AppColors> {')
    ..writeln('  const AppColors({');
  for (final c in colors) {
    b.writeln('    required this.${camelCase(c.name)},');
  }
  b
    ..writeln('  });')
    ..writeln();
  for (final c in colors) {
    b
      ..write(_doc(c.usage))
      ..writeln('  final Color ${camelCase(c.name)};')
      ..writeln();
  }
  for (final (label, pick) in [
    ('light', (ColorToken c) => c.light),
    ('dark', (ColorToken c) => c.dark),
  ]) {
    b.writeln('  static const $label = AppColors(');
    for (final c in colors) {
      b.writeln('    ${camelCase(c.name)}: Color(${_hex(pick(c))}),');
    }
    b
      ..writeln('  );')
      ..writeln();
  }
  b
    ..writeln('  @override')
    ..writeln('  AppColors copyWith({');
  for (final c in colors) {
    b.writeln('    Color? ${camelCase(c.name)},');
  }
  b
    ..writeln('  }) {')
    ..writeln('    return AppColors(');
  for (final c in colors) {
    final n = camelCase(c.name);
    b.writeln('      $n: $n ?? this.$n,');
  }
  b
    ..writeln('    );')
    ..writeln('  }')
    ..writeln()
    ..writeln('  @override')
    ..writeln('  AppColors lerp(AppColors? other, double t) {')
    ..writeln('    if (other == null) return this;')
    ..writeln('    return AppColors(');
  for (final c in colors) {
    final n = camelCase(c.name);
    b.writeln('      $n: Color.lerp($n, other.$n, t)!,');
  }
  b
    ..writeln('    );')
    ..writeln('  }')
    ..writeln('}')
    ..writeln();

  void sizes(
    String className,
    String doc,
    List<SizeToken> list,
    String Function(String) rename,
  ) {
    b
      ..writeln('/// $doc')
      ..writeln('abstract final class $className {');
    for (final s in list) {
      b
        ..write(_doc(s.usage))
        ..writeln('  static const double ${rename(s.name)} = ${_num(s.value)};')
        ..writeln();
    }
    b
      ..writeln('}')
      ..writeln();
  }

  sizes(
    'AppSpacing',
    'Espacements, grille de 4 px.',
    tokens.spacing,
    camelCase,
  );
  sizes(
    'AppRadius',
    'Rayons des coins.',
    tokens.radius,
    (n) => camelCase(n.replaceFirst('radius-', '')),
  );

  b
    ..writeln('/// Familles de polices, embarquées dans `assets/fonts/`.')
    ..writeln('abstract final class AppFontFamilies {');
  for (final MapEntry(:key, :value) in tokens.families.entries) {
    b.writeln("  static const String ${camelCase(key)} = '$value';");
  }
  b
    ..writeln('}')
    ..writeln()
    ..writeln('/// Un style de texte du design system.')
    ..writeln('@immutable')
    ..writeln('class AppTextToken {')
    ..writeln('  const AppTextToken({')
    ..writeln('    required this.fontFamily,')
    ..writeln('    required this.fontSize,')
    ..writeln('    required this.lineHeight,')
    ..writeln('    required this.fontWeight,')
    ..writeln('    required this.letterSpacing,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final String fontFamily;')
    ..writeln('  final double fontSize;')
    ..writeln()
    ..writeln('  /// Interligne en pixels logiques.')
    ..writeln('  final double lineHeight;')
    ..writeln('  final FontWeight fontWeight;')
    ..writeln('  final double letterSpacing;')
    ..writeln()
    ..writeln('  TextStyle toTextStyle({Color? color}) => TextStyle(')
    ..writeln('    fontFamily: fontFamily,')
    ..writeln('    fontSize: fontSize,')
    ..writeln('    height: lineHeight / fontSize,')
    ..writeln('    fontWeight: fontWeight,')
    ..writeln('    letterSpacing: letterSpacing,')
    ..writeln('    color: color,')
    ..writeln('  );')
    ..writeln('}')
    ..writeln()
    ..writeln('/// Les styles de texte du design system.')
    ..writeln('abstract final class AppTypography {');
  for (final t in tokens.textStyles) {
    b
      ..writeln('  static const ${camelCase(t.name)} = AppTextToken(')
      ..writeln('    fontFamily: AppFontFamilies.${camelCase(t.family)},')
      ..writeln('    fontSize: ${_num(t.fontSize)},')
      ..writeln('    lineHeight: ${_num(t.lineHeight)},')
      ..writeln('    fontWeight: FontWeight.w${t.fontWeight},')
      ..writeln('    letterSpacing: ${_num(t.letterSpacing)},')
      ..writeln('  );')
      ..writeln();
  }
  b.writeln('}');
  return b.toString();
}
