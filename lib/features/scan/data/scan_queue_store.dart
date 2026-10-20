import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/attendance_scan.dart';

/// File d'attente des scans pas encore envoyés, une par assemblée. Elle
/// survit au redémarrage de l'application, hors du cache hors connexion
/// (qui peut se vider) ; elle ne se vide qu'à l'envoi réussi ou à la
/// déconnexion, après avertissement.
abstract interface class ScanQueueStore {
  Future<List<Scan>> read(int meetingId);

  Future<void> write(int meetingId, List<Scan> scans);

  /// Assemblées qui ont des scans en attente.
  Future<List<int>> meetingIds();

  /// Scans en attente, toutes assemblées confondues.
  Future<int> pendingTotal();

  Future<void> clear();
}

class FileScanQueueStore implements ScanQueueStore {
  FileScanQueueStore(this._root);

  final Future<Directory> Function() _root;

  Future<File> _file(int meetingId) async =>
      File('${(await _root()).path}/meeting_$meetingId.json');

  @override
  Future<List<Scan>> read(int meetingId) async {
    final file = await _file(meetingId);
    if (!file.existsSync()) return [];
    try {
      final json = jsonDecode(await file.readAsString()) as List<Object?>;
      return [
        for (final item in json) Scan.fromJson(item! as Map<String, dynamic>),
      ];
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> write(int meetingId, List<Scan> scans) async {
    final file = await _file(meetingId);
    if (scans.isEmpty) {
      if (file.existsSync()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    // Écriture atomique : un fichier temporaire, puis renommé.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode([for (final s in scans) s.toJson()]));
    await temp.rename(file.path);
  }

  @override
  Future<List<int>> meetingIds() async {
    final dir = await _root();
    if (!dir.existsSync()) return [];
    return [
      for (final entity in dir.listSync().whereType<File>())
        if (RegExp(r'meeting_(\d+)\.json$').firstMatch(entity.path)
            case final match?)
          int.parse(match[1]!),
    ];
  }

  @override
  Future<int> pendingTotal() async {
    var total = 0;
    for (final id in await meetingIds()) {
      total += (await read(id)).length;
    }
    return total;
  }

  @override
  Future<void> clear() async {
    final dir = await _root();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}

/// En mémoire : tests.
class MemoryScanQueueStore implements ScanQueueStore {
  final queues = <int, List<Scan>>{};

  @override
  Future<List<Scan>> read(int meetingId) async => [...?queues[meetingId]];

  @override
  Future<void> write(int meetingId, List<Scan> scans) async =>
      scans.isEmpty ? queues.remove(meetingId) : queues[meetingId] = [...scans];

  @override
  Future<List<int>> meetingIds() async => queues.keys.toList();

  @override
  Future<int> pendingTotal() async =>
      queues.values.fold<int>(0, (sum, q) => sum + q.length);

  @override
  Future<void> clear() async => queues.clear();
}

final scanQueueStoreProvider = Provider<ScanQueueStore>(
  (ref) => FileScanQueueStore(
    () async => Directory(
      '${(await getApplicationSupportDirectory()).path}/scan_queue',
    ),
  ),
);
