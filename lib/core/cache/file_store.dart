import 'dart:io';

import 'package:flutter/foundation.dart';

/// Fichiers gardés hors connexion (reçus PDF déjà ouverts).
///
/// Même dossier racine que le cache JSON : effacé avec lui à la
/// déconnexion et à la suppression du compte.
abstract interface class FileStore {
  /// Chemin du fichier [name] s'il a déjà été gardé, `null` sinon.
  Future<String?> pathFor(String name);

  /// Garde [bytes] sous [name] et renvoie son chemin.
  Future<String> write(String name, List<int> bytes);

  Future<void> clear();
}

/// Nom de fichier sûr : lettres, chiffres, `.`, `_` et `-`.
String safeFileName(String name) =>
    name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

class DirectoryFileStore implements FileStore {
  DirectoryFileStore(this._root);

  /// Racine du cache hors connexion ; les fichiers vont dans `files/`.
  final Future<Directory> Function() _root;

  Future<File> _file(String name) async =>
      File('${(await _root()).path}/files/${safeFileName(name)}');

  @override
  Future<String?> pathFor(String name) async {
    final file = await _file(name);
    return file.existsSync() && file.lengthSync() > 0 ? file.path : null;
  }

  @override
  Future<String> write(String name, List<int> bytes) async {
    final file = await _file(name);
    await file.parent.create(recursive: true);
    // Écriture atomique : un fichier interrompu n'est jamais pris pour bon.
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    return file.path;
  }

  @override
  Future<void> clear() async {
    final dir = Directory('${(await _root()).path}/files');
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// Pour les tests : chemins fictifs `memoire://nom`.
class MemoryFileStore implements FileStore {
  final _files = <String, List<int>>{};

  @visibleForTesting
  Map<String, List<int>> get files => Map.unmodifiable(_files);

  @override
  Future<String?> pathFor(String name) async =>
      _files.containsKey(safeFileName(name))
      ? 'memoire://${safeFileName(name)}'
      : null;

  @override
  Future<String> write(String name, List<int> bytes) async {
    _files[safeFileName(name)] = bytes;
    return 'memoire://${safeFileName(name)}';
  }

  @override
  Future<void> clear() async => _files.clear();
}
