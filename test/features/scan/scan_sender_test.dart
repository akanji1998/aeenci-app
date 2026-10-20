import 'dart:io';

import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/features/scan/data/attendance_repository.dart';
import 'package:aeenci_app/features/scan/data/scan_queue_store.dart';
import 'package:aeenci_app/features/scan/domain/attendance_scan.dart';
import 'package:aeenci_app/features/scan/presentation/scan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Répond « enregistré » à tout ; peut échouer à partir du n-ième envoi.
class _Recorder implements AttendanceRepository {
  final batches = <ScanBatch>[];
  int? failFrom;

  @override
  Future<List<AttendanceMeeting>> fetchMeetings() async => [];

  @override
  Future<List<ScanResult>> sendScans(ScanBatch batch) async {
    if (failFrom != null && batches.length >= failFrom!) {
      throw const NetworkException();
    }
    batches.add(batch);
    return [
      for (final s in batch.scans)
        ScanResult(qrPayload: s.qrPayload, outcome: ScanOutcome.recorded),
    ];
  }
}

List<Scan> scans(int n) => [
  for (var i = 0; i < n; i++)
    Scan(
      qrPayload: 'AEENCI1.carte$i.sig',
      scannedAt: DateTime.utc(2026, 10, 20),
    ),
];

void main() {
  late _Recorder repo;
  late MemoryScanQueueStore queue;
  late ProviderContainer container;

  setUp(() {
    repo = _Recorder();
    queue = MemoryScanQueueStore();
    container = ProviderContainer(
      overrides: [
        attendanceRepositoryProvider.overrideWithValue(repo),
        scanQueueStoreProvider.overrideWithValue(queue),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('450 scans : trois envois de 200 au plus, dans l\'ordre', () async {
    await queue.write(12, scans(450));
    final results = await container.read(scanSenderProvider).flush(12);
    expect(repo.batches.map((b) => b.scans.length), [200, 200, 50]);
    expect(results, hasLength(450));
    expect(results.first.qrPayload, 'AEENCI1.carte0.sig');
    expect(await queue.pendingTotal(), 0);
  });

  test(
    'réseau coupé en route : rien de perdu, rien envoyé deux fois',
    () async {
      await queue.write(12, scans(450));
      repo.failFrom = 1;
      await expectLater(
        container.read(scanSenderProvider).flush(12),
        throwsA(isA<NetworkException>()),
      );
      // Le premier lot est parti et sorti de la file ; le reste attend.
      expect(await queue.read(12), hasLength(250));

      repo.failFrom = null;
      await container.read(scanSenderProvider).flush(12);
      final sent = [for (final b in repo.batches) ...b.scans];
      expect(sent, hasLength(450));
      expect(sent.toSet(), hasLength(450));
    },
  );

  test('deux appels en même temps : une seule boucle d\'envoi', () async {
    await queue.write(12, scans(3));
    final sender = container.read(scanSenderProvider);
    await Future.wait([sender.flush(12), sender.flush(12)]);
    expect(repo.batches, hasLength(1));
  });

  test('file sur disque : elle survit au redémarrage', () async {
    final dir = await Directory.systemTemp.createTemp('scan_queue_test');
    // `clear()` supprime le dossier lui-même.
    addTearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });
    final first = FileScanQueueStore(() async => dir);
    await first.write(12, scans(2));
    await first.write(13, scans(1));

    final reopened = FileScanQueueStore(() async => dir);
    expect(await reopened.read(12), scans(2));
    expect(await reopened.pendingTotal(), 3);
    expect((await reopened.meetingIds())..sort(), [12, 13]);

    await reopened.write(12, []);
    expect(await reopened.meetingIds(), [13]);
    await reopened.clear();
    expect(await reopened.pendingTotal(), 0);
  });
}
