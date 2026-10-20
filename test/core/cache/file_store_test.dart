import 'dart:io';

import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/cache/file_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late Directory root;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('aeenci_files_test');
    root = Directory('${temp.path}/offline_cache');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('écrit puis retrouve un fichier', () async {
    final store = DirectoryFileStore(() async => root);
    expect(await store.pathFor('REC-2026-00001.pdf'), isNull);
    final path = await store.write('REC-2026-00001.pdf', [37, 80, 68, 70]);
    expect(File(path).readAsBytesSync(), [37, 80, 68, 70]);
    expect(await store.pathFor('REC-2026-00001.pdf'), path);
  });

  test('nom de fichier assaini', () async {
    final store = DirectoryFileStore(() async => root);
    final path = await store.write('../../etc/passwd', [1]);
    expect(path, startsWith('${root.path}/files/'));
    expect(safeFileName('REC/2026 00001.pdf'), 'REC_2026_00001.pdf');
  });

  test('effacé avec le cache (même racine)', () async {
    final store = DirectoryFileStore(() async => root);
    final cache = FileCacheStore(() async => root);
    await store.write('recu.pdf', [1, 2, 3]);
    await cache.write('me', {'id': 1});
    await cache.clear();
    expect(await store.pathFor('recu.pdf'), isNull);
  });

  test('clear seul', () async {
    final store = DirectoryFileStore(() async => root);
    await store.write('recu.pdf', [1]);
    await store.clear();
    expect(await store.pathFor('recu.pdf'), isNull);
    await store.clear();
  });
}
