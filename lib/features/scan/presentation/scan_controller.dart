import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/connectivity.dart';
import '../../app_config/presentation/app_gate_controller.dart';
import '../data/attendance_repository.dart';
import '../data/scan_queue_store.dart';
import '../domain/attendance_scan.dart';
import '../domain/card_verifier.dart';

/// Envoi groupé d'une file : 200 scans au plus par requête. Un scan ne
/// quitte la file qu'une fois sa réponse reçue : ni perte ni doublon.
class ScanSender {
  ScanSender(this._ref);

  final Ref _ref;

  /// Une seule boucle d'envoi par assemblée à la fois.
  final _running = <int, Future<List<ScanResult>>>{};

  /// Envoie toute la file de [meetingId] ; renvoie les résultats reçus.
  /// Lève une [ApiException] si un envoi échoue (la file reste alors
  /// intacte pour ce lot et les suivants).
  Future<List<ScanResult>> flush(int meetingId) =>
      _running[meetingId] ??= _flush(meetingId).whenComplete(() {
        // Bloc sans valeur : renvoyer le futur retiré le ferait s'attendre
        // lui-même.
        _running.remove(meetingId);
      });

  Future<List<ScanResult>> _flush(int meetingId) async {
    final store = _ref.read(scanQueueStoreProvider);
    final repo = _ref.read(attendanceRepositoryProvider);
    final all = <ScanResult>[];
    while (true) {
      final queue = await store.read(meetingId);
      if (queue.isEmpty) return all;
      final batch = queue.take(ScanBatch.maxScans).toList();
      final results = await repo.sendScans(
        ScanBatch(meetingId: meetingId, scans: batch),
      );
      // Retirés seulement maintenant, et en relisant la file : des scans
      // ont pu s'y ajouter pendant l'envoi.
      final sent = batch.toSet();
      await store.write(meetingId, [
        for (final s in await store.read(meetingId))
          if (!sent.contains(s)) s,
      ]);
      all.addAll(results);
    }
  }

  /// Toutes les files (avant une déconnexion).
  Future<void> flushAll() async {
    final store = _ref.read(scanQueueStoreProvider);
    for (final id in await store.meetingIds()) {
      await flush(id);
    }
  }
}

final scanSenderProvider = Provider<ScanSender>(ScanSender.new);

/// Ce qu'affiche le bandeau après un scan.
enum ScanFeedbackKind {
  /// Présence enregistrée par l'API.
  recorded,

  /// Carte vérifiée sur le téléphone, en file d'envoi.
  accepted,

  /// Carte lue sans pouvoir la vérifier (clé absente), en file d'envoi.
  readUnverified,
  alreadyRecorded,
  invalid,
  expired,
  notMember,
}

@immutable
class ScanFeedback {
  const ScanFeedback({
    required this.kind,
    required this.serial,
    this.payload,
    this.memberNumber,
    this.fullName,
  });

  final ScanFeedbackKind kind;

  /// Change à chaque scan : vibration et son, même pour deux résultats
  /// identiques à la suite.
  final int serial;
  final String? payload;
  final String? memberNumber;
  final String? fullName;

  bool get ok =>
      kind == ScanFeedbackKind.recorded ||
      kind == ScanFeedbackKind.accepted ||
      kind == ScanFeedbackKind.readUnverified;
}

@immutable
class ScanState {
  const ScanState({
    required this.recordedCount,
    this.pending = 0,
    this.feedback,
    this.offline = false,
    this.sendError,
    this.canVerify = true,
  });

  /// Présences enregistrées pour l'assemblée (API).
  final int recordedCount;

  /// Scans en file, pas encore envoyés.
  final int pending;
  final ScanFeedback? feedback;

  /// Dernier envoi impossible faute de réseau.
  final bool offline;

  /// Autre échec d'envoi (droits retirés, serveur).
  final ApiException? sendError;

  /// `false` : pas de `card_public_key` lisible, vérification à l'envoi.
  final bool canVerify;

  ScanState copyWith({
    int? recordedCount,
    int? pending,
    ScanFeedback? feedback,
    bool? offline,
    ApiException? sendError,
  }) => ScanState(
    recordedCount: recordedCount ?? this.recordedCount,
    pending: pending ?? this.pending,
    feedback: feedback ?? this.feedback,
    offline: offline ?? this.offline,
    sendError: sendError,
    canVerify: canVerify,
  );
}

/// Une séance de scan pour une assemblée.
class ScanController extends Notifier<ScanState> {
  ScanController(this.meeting);

  final AttendanceMeeting meeting;

  /// Une même carte reste devant la caméra : on l'ignore pendant ce délai.
  static const repeatDelay = Duration(seconds: 3);

  late CardVerifier? _verifier;
  final _seenMembers = <int>{};
  final _queuedPayloads = <String>{};
  var _serial = 0;
  String? _lastPayload;
  DateTime? _lastAt;

  @override
  ScanState build() {
    final gate = ref.read(appGateControllerProvider);
    final key = gate is GateOpen ? gate.config?.cardPublicKey : null;
    final verifier = key == null ? null : CardVerifier(key);
    _verifier = verifier != null && verifier.hasKey ? verifier : null;

    ref.listen(connectivityProvider, (_, next) {
      if (next.value ?? false) unawaited(flush());
    });
    // Scans laissés par une séance précédente : envoyés dès l'ouverture.
    unawaited(_restore());
    return ScanState(
      recordedCount: meeting.scannedCount,
      canVerify: _verifier != null,
    );
  }

  Future<void> _restore() async {
    final queue = await ref.read(scanQueueStoreProvider).read(meeting.id);
    _queuedPayloads.addAll(queue.map((s) => s.qrPayload));
    if (!ref.mounted) return;
    state = state.copyWith(pending: queue.length);
    await flush();
  }

  ScanFeedback _feedback(
    ScanFeedbackKind kind, {
    String? payload,
    String? number,
    String? name,
  }) => ScanFeedback(
    kind: kind,
    serial: ++_serial,
    payload: payload,
    memberNumber: number,
    fullName: name,
  );

  /// Une carte lue par la caméra (ou simulée).
  Future<void> onDetected(String raw) async {
    final payload = raw.trim();
    final now = ref.read(clockProvider)();
    if (payload == _lastPayload &&
        _lastAt != null &&
        now.difference(_lastAt!) < repeatDelay) {
      return;
    }
    _lastPayload = payload;
    _lastAt = now;

    final verifier = _verifier;
    if (verifier == null) {
      // Sans clé, on ne filtre que le format ; l'API vérifie à l'envoi.
      if (!payload.startsWith('${CardVerifier.prefix}.')) {
        state = state.copyWith(feedback: _feedback(ScanFeedbackKind.invalid));
      } else if (_queuedPayloads.contains(payload)) {
        state = state.copyWith(
          feedback: _feedback(ScanFeedbackKind.alreadyRecorded),
        );
      } else {
        await _enqueue(payload, now, ScanFeedbackKind.readUnverified);
      }
      return;
    }

    switch (await verifier.verify(payload, now: now)) {
      case CardInvalid():
        state = state.copyWith(feedback: _feedback(ScanFeedbackKind.invalid));
      case CardExpired(:final memberNumber):
        state = state.copyWith(
          feedback: _feedback(ScanFeedbackKind.expired, number: memberNumber),
        );
      case CardValid(:final memberId, :final memberNumber):
        if (!_seenMembers.add(memberId) || _queuedPayloads.contains(payload)) {
          state = state.copyWith(
            feedback: _feedback(
              ScanFeedbackKind.alreadyRecorded,
              number: memberNumber,
            ),
          );
          return;
        }
        await _enqueue(
          payload,
          now,
          ScanFeedbackKind.accepted,
          number: memberNumber,
        );
    }
  }

  Future<void> _enqueue(
    String payload,
    DateTime now,
    ScanFeedbackKind kind, {
    String? number,
  }) async {
    final store = ref.read(scanQueueStoreProvider);
    final queue = await store.read(meeting.id);
    await store.write(meeting.id, [
      ...queue,
      Scan(qrPayload: payload, scannedAt: now.toUtc()),
    ]);
    _queuedPayloads.add(payload);
    if (!ref.mounted) return;
    state = state.copyWith(
      pending: queue.length + 1,
      feedback: _feedback(kind, payload: payload, number: number),
    );
    await flush();
  }

  /// Envoie la file ; sans réseau, elle attend son retour.
  Future<void> flush() async {
    try {
      final results = await ref.read(scanSenderProvider).flush(meeting.id);
      if (!ref.mounted) return;
      _apply(results);
    } on NetworkException {
      if (ref.mounted) state = state.copyWith(offline: true);
    } on ApiException catch (error) {
      if (ref.mounted) state = state.copyWith(sendError: error);
    }
  }

  void _apply(List<ScanResult> results) {
    var recorded = state.recordedCount;
    var feedback = state.feedback;
    for (final r in results) {
      _queuedPayloads.remove(r.qrPayload);
      if (r.outcome == ScanOutcome.recorded) recorded++;
      // Le bandeau suit la carte qu'il montre, si l'API répond vite.
      if (feedback != null && feedback.payload == r.qrPayload) {
        feedback = ScanFeedback(
          kind: switch (r.outcome) {
            ScanOutcome.recorded => ScanFeedbackKind.recorded,
            ScanOutcome.alreadyRecorded => ScanFeedbackKind.alreadyRecorded,
            ScanOutcome.expired => ScanFeedbackKind.expired,
            ScanOutcome.notMember => ScanFeedbackKind.notMember,
            ScanOutcome.invalid ||
            ScanOutcome.unknown => ScanFeedbackKind.invalid,
          },
          serial: feedback.ok == (r.outcome == ScanOutcome.recorded)
              ? feedback.serial
              : ++_serial,
          payload: r.qrPayload,
          memberNumber: r.member?.memberNumber ?? feedback.memberNumber,
          fullName: r.member?.fullName,
        );
      }
    }
    state = ScanState(
      recordedCount: recorded,
      pending: _queuedPayloads.length,
      feedback: feedback,
      canVerify: state.canVerify,
    );
  }
}

final scanControllerProvider = NotifierProvider.autoDispose
    .family<ScanController, ScanState, AttendanceMeeting>(ScanController.new);

final attendanceMeetingsProvider =
    FutureProvider.autoDispose<List<AttendanceMeeting>>(
      (ref) => ref.read(attendanceRepositoryProvider).fetchMeetings(),
    );
