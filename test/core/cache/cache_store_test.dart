import 'dart:io';

import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/cache/cached_fetch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temp;
  late Directory root;
  var now = DateTime.utc(2026, 10, 18, 10, 2);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('aeenci_cache_test');
    root = Directory('${temp.path}/cache');
  });

  tearDown(() => temp.deleteSync(recursive: true));

  FileCacheStore store() => FileCacheStore(() async => root, clock: () => now);

  group('FileCacheStore', () {
    test('écrit puis relit le JSON et la date', () async {
      final cache = store();
      await cache.write('me/card', {'member_number': 'TEST-0001', 'n': 1});
      final entry = await cache.read('me/card');
      expect(entry!.json, {'member_number': 'TEST-0001', 'n': 1});
      expect(entry.updatedAt, now);
    });

    test('clé absente → null', () async {
      expect(await store().read('absente'), isNull);
    });

    test('les clés proches ne se confondent pas', () async {
      final cache = store();
      await cache.write('me/card', 1);
      await cache.write('me_card', 2);
      expect((await cache.read('me/card'))!.json, 1);
      expect((await cache.read('me_card'))!.json, 2);
    });

    test('une nouvelle écriture remplace l\'ancienne', () async {
      final cache = store();
      await cache.write('k', 'a');
      now = now.add(const Duration(hours: 1));
      await cache.write('k', 'b');
      final entry = await cache.read('k');
      expect(entry!.json, 'b');
      expect(entry.updatedAt, now);
    });

    test('remove et clear', () async {
      final cache = store();
      await cache.write('a', 1);
      await cache.write('b', 2);
      await cache.remove('a');
      expect(await cache.read('a'), isNull);
      // Un fichier hors JSON (reçu PDF) disparaît aussi.
      File('${root.path}/files/recu.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('%PDF');
      await cache.clear();
      expect(await cache.read('b'), isNull);
      expect(root.existsSync(), isFalse);
      await cache.clear(); // sans erreur si déjà vide
    });

    test('fichier corrompu → null et supprimé', () async {
      final cache = store();
      await cache.write('k', 1);
      final file = Directory('${root.path}/json').listSync().single as File;
      file.writeAsStringSync('{pas du json');
      expect(await cache.read('k'), isNull);
      expect(file.existsSync(), isFalse);
    });
  });

  group('fetchWithCache', () {
    late MemoryCacheStore cache;

    setUp(() => cache = MemoryCacheStore(clock: () => now));

    Future<Cached<int>> run(Future<int> Function() fetch) =>
        fetchWithCache<int>(
          cache: cache,
          key: 'k',
          fetch: fetch,
          toJson: (data) => data,
          fromJson: (json) => json! as int,
        );

    test('en ligne : données fraîches, mises en cache', () async {
      final result = await run(() async => 42);
      expect(result.data, 42);
      expect(result.isOffline, isFalse);
      expect((await cache.read('k'))!.json, 42);
    });

    test('hors connexion : données en cache avec leur date', () async {
      await run(() async => 42);
      final result = await run(() async => throw const NetworkException());
      expect(result.data, 42);
      expect(result.offlineSince, now);
    });

    test('hors connexion sans cache : l\'erreur remonte', () async {
      expect(
        run(() async => throw const NetworkException()),
        throwsA(isA<NetworkException>()),
      );
    });

    test('autre erreur : pas de repli sur le cache', () async {
      await run(() async => 42);
      expect(
        run(() async => throw const ServerException(statusCode: 500)),
        throwsA(isA<ServerException>()),
      );
    });

    test('cache illisible : oublié, l\'erreur réseau remonte', () async {
      await cache.write('k', 'pas un entier');
      await expectLater(
        run(() async => throw const NetworkException()),
        throwsA(isA<NetworkException>()),
      );
      expect(await cache.read('k'), isNull);
    });
  });
}
