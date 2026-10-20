import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/domain/enums.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_card_signer.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/attendance_scan.dart';
import '../domain/card_verifier.dart';

part 'attendance_repository.g.dart';

/// Scan des présences (permission `attendance.scan`, sinon 403).
abstract interface class AttendanceRepository {
  /// `GET /attendance/meetings` : assemblées d'aujourd'hui et d'hier.
  Future<List<AttendanceMeeting>> fetchMeetings();

  /// `POST /attendance/scans` : 200 scans au plus ; un résultat par scan,
  /// dans le même ordre.
  Future<List<ScanResult>> sendScans(ScanBatch batch);
}

class ApiAttendanceRepository implements AttendanceRepository {
  const ApiAttendanceRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AttendanceMeeting>> fetchMeetings() =>
      _api.getList('/attendance/meetings', AttendanceMeeting.fromJson);

  @override
  Future<List<ScanResult>> sendScans(ScanBatch batch) async {
    assert(batch.scans.length <= ScanBatch.maxScans);
    final body = await _api.sendObject(
      'POST',
      '/attendance/scans',
      data: batch.toJson(),
    );
    final results = body['results'];
    if (results is! List<Object?> || results.length != batch.scans.length) {
      throw const UnknownApiException();
    }
    return [
      for (final r in results) ScanResult.fromJson(r! as Map<String, dynamic>),
    ];
  }
}

/// Assemblée du jour ; vérifie les cartes comme le backend (clé de test) et
/// garde en mémoire les présences enregistrées.
class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;
  final _verifier = CardVerifier(mockCardPublicKey);

  /// Membres enregistrés par assemblée (trois déjà scannés au départ).
  final recorded = <int, Set<int>>{
    12: {9001, 9002, 9003},
  };
  final batches = <ScanBatch>[];

  Future<void> _checkAbility() async {
    final persona = await currentMockPersona(_tokens);
    final abilities = persona.meJson['abilities'] as List<Object?>? ?? [];
    if (!abilities.contains('attendance.scan')) {
      throw const ForbiddenException();
    }
  }

  @override
  Future<List<AttendanceMeeting>> fetchMeetings() async {
    await _runtime.simulate();
    await _checkAbility();
    final now = DateTime.now();
    return [
      AttendanceMeeting(
        id: 12,
        date: DateTime(now.year, now.month, now.day),
        location: 'Lieu de l\'assemblée (test)',
        scannedCount: recorded[12]!.length,
      ),
    ];
  }

  @override
  Future<List<ScanResult>> sendScans(ScanBatch batch) async {
    await _runtime.simulate();
    await _checkAbility();
    batches.add(batch);
    final done = recorded.putIfAbsent(batch.meetingId, () => {});
    return [
      for (final scan in batch.scans)
        await _result(scan, done, batch.meetingId),
    ];
  }

  Future<ScanResult> _result(Scan scan, Set<int> done, int meetingId) async {
    final check = await _verifier.verify(scan.qrPayload, now: scan.scannedAt);
    switch (check) {
      case CardInvalid():
        return ScanResult(
          qrPayload: scan.qrPayload,
          outcome: ScanOutcome.invalid,
        );
      case CardExpired(:final memberNumber):
        return ScanResult(
          qrPayload: scan.qrPayload,
          outcome: ScanOutcome.expired,
          member: ScannedMember(
            fullName: 'Membre de test',
            memberNumber: memberNumber,
          ),
        );
      case CardValid(:final memberId, :final memberNumber):
        final persona = MockPersona.values
            .where((p) => p.meJson['id'] == memberId)
            .firstOrNull;
        final member = ScannedMember(
          fullName: persona == null
              ? 'Membre de test'
              : '${persona.meJson['first_names']} ${persona.meJson['last_name']}',
          memberNumber: memberNumber,
        );
        if (persona != null &&
            persona.meJson['admission_state'] != 'approved') {
          return ScanResult(
            qrPayload: scan.qrPayload,
            outcome: ScanOutcome.notMember,
            member: member,
          );
        }
        return ScanResult(
          qrPayload: scan.qrPayload,
          outcome: done.add(memberId)
              ? ScanOutcome.recorded
              : ScanOutcome.alreadyRecorded,
          member: member,
        );
    }
  }
}

@Riverpod(keepAlive: true)
AttendanceRepository attendanceRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockAttendanceRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiAttendanceRepository(ref.watch(apiClientProvider));
