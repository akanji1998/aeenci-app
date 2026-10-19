// Génère lib/core/design/tokens.g.dart depuis docs/design/tokens.json.
//
//   dart run tool/generate_theme.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'src/theme_generator.dart';

const _input = 'docs/design/tokens.json';
const _output = 'lib/core/design/tokens.g.dart';

Future<void> main() async {
  final json = jsonDecode(await File(_input).readAsString());
  if (json is! Map<String, Object?>) {
    stderr.writeln('$_input : objet JSON attendu à la racine.');
    exitCode = 1;
    return;
  }
  final source = renderTokens(parseTokens(json));
  final file = File(_output);
  await file.parent.create(recursive: true);
  await file.writeAsString(source);

  final format = await Process.run(Platform.resolvedExecutable, [
    'format',
    _output,
  ]);
  if (format.exitCode != 0) {
    stderr.write(format.stderr);
    exitCode = format.exitCode;
    return;
  }
  print('$_output généré.');
}
