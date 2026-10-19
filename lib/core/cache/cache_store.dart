import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Une valeur mise en cache et sa date d'écriture.
@immutable
class CachedEntry {
  const CachedEntry(this.json, this.updatedAt);

  /// JSON décodé (Map, List, scalaire).
  final Object? json;
  final DateTime updatedAt;
}

/// Cache hors connexion des réponses de l'API.
///
/// Vidé entièrement à la déconnexion et à la suppression du compte.
abstract interface class CacheStore {
  Future<CachedEntry?> read(String key);

  Future<void> write(String key, Object? json);

  Future<void> remove(String key);

  /// Efface tout, y compris les fichiers (reçus PDF).
  Future<void> clear();
}

/// Un fichier JSON par clé, dans le répertoire de support de l'application.
class FileCacheStore implements CacheStore {
  FileCacheStore(this._root, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Fourni de façon paresseuse : `path_provider` est asynchrone.
  final Future<Directory> Function() _root;
  final DateTime Function() _clock;

  Future<File> _file(String key) async {
    final root = await _root();
    // base64url : aucun caractère interdit, aucune collision entre clés.
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${root.path}/json/$name.json');
  }

  @override
  Future<CachedEntry?> read(String key) async {
    final file = await _file(key);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?>) throw const FormatException();
      final updatedAt = DateTime.parse(decoded['updated_at']! as String);
      return CachedEntry(decoded['data'], updatedAt);
    } on Object {
      // Fichier corrompu (écriture interrompue d'une ancienne version…).
      await _delete(file);
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? json) async {
    final file = await _file(key);
    await file.parent.create(recursive: true);
    final content = jsonEncode({
      'updated_at': _clock().toUtc().toIso8601String(),
      'data': json,
    });
    // Écriture atomique : fichier temporaire puis renommage.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(content, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> remove(String key) async => _delete(await _file(key));

  @override
  Future<void> clear() async {
    final root = await _root();
    if (root.existsSync()) await root.delete(recursive: true);
  }

  Future<void> _delete(File file) async {
    if (file.existsSync()) await file.delete();
  }
}

/// Pour les tests.
class MemoryCacheStore implements CacheStore {
  MemoryCacheStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _entries = <String, CachedEntry>{};

  @override
  Future<CachedEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, Object? json) async =>
      _entries[key] = CachedEntry(jsonDecode(jsonEncode(json)), _clock());

  @override
  Future<void> remove(String key) async => _entries.remove(key);

  @override
  Future<void> clear() async => _entries.clear();

  bool get isEmpty => _entries.isEmpty;
}
