import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'attendance_scan.freezed.dart';
part 'attendance_scan.g.dart';

/// `GET /attendance/meetings` : assemblée du jour ou de la veille.
@freezed
abstract class AttendanceMeeting with _$AttendanceMeeting {
  const factory AttendanceMeeting({
    required int id,
    @DateOnlyConverter() required DateTime date,
    String? location,
    required int scannedCount,
  }) = _AttendanceMeeting;

  factory AttendanceMeeting.fromJson(Map<String, dynamic> json) =>
      _$AttendanceMeetingFromJson(json);
}

/// Un scan à envoyer (`POST /attendance/scans`).
@freezed
abstract class Scan with _$Scan {
  const factory Scan({required String qrPayload, required DateTime scannedAt}) =
      _Scan;

  factory Scan.fromJson(Map<String, dynamic> json) => _$ScanFromJson(json);
}

/// Corps de `POST /attendance/scans` (200 scans au plus).
@freezed
abstract class ScanBatch with _$ScanBatch {
  const factory ScanBatch({required int meetingId, required List<Scan> scans}) =
      _ScanBatch;

  factory ScanBatch.fromJson(Map<String, dynamic> json) =>
      _$ScanBatchFromJson(json);

  static const maxScans = 200;
}

/// Résultat d'un scan, dans le même ordre que l'envoi.
@freezed
abstract class ScanResult with _$ScanResult {
  const factory ScanResult({
    required String qrPayload,
    @JsonKey(unknownEnumValue: ScanOutcome.unknown)
    required ScanOutcome outcome,
    ScannedMember? member,
  }) = _ScanResult;

  factory ScanResult.fromJson(Map<String, dynamic> json) =>
      _$ScanResultFromJson(json);
}

@freezed
abstract class ScannedMember with _$ScannedMember {
  const factory ScannedMember({
    required String fullName,
    required String memberNumber,
    String? photoUrl,
  }) = _ScannedMember;

  factory ScannedMember.fromJson(Map<String, dynamic> json) =>
      _$ScannedMemberFromJson(json);
}
