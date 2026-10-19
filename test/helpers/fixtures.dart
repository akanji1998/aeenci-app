import 'dart:convert';
import 'dart:io';

/// Lit `test/fixtures/contract/<name>.json`, exemple conforme au contrat v3.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/contract/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// `data` d'une ressource.
Map<String, dynamic> fixtureData(String name) =>
    fixture(name)['data'] as Map<String, dynamic>;

/// Éléments de `data` d'une liste.
List<Map<String, dynamic>> fixtureList(String name) => [
  for (final item in fixture(name)['data'] as List<dynamic>)
    item as Map<String, dynamic>,
];
