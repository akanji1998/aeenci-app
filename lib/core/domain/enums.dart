// Énumérations du contrat d'API v3 (valeurs de `app/Enums` du backend).
//
// Chaque énumération reçue a une valeur `unknown` : une valeur ajoutée côté
// backend ne fait pas planter l'application. Les libellés français sont dans
// `core/l10n/enum_labels.dart`.

import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum Gender { female, male, unknown }

/// `admission_state` d'une fiche, `state` d'une demande d'adhésion.
@JsonEnum(fieldRename: FieldRename.snake)
enum AdmissionState { pending, approved, rejected, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum MemberStatus { member, former, elder, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum Engagement { active, dormant, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum MemberCategory { student, youngProfessional, professional, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum ShowcaseStatus { private, pending, published, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum ContributionState { unpaid, partial, paid, exempt, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum PaymentPurpose { admission, contribution, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum PaymentMethod {
  cash,
  orangeMoney,
  mtnMomo,
  moovMoney,
  wave,
  bankTransfer,
  other,
  unknown,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum MobileMoneyOperator { orangeMoney, mtnMomo, moovMoney, wave, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum EventType { joe, employmentDay, impact, other, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum AttendanceState { present, excused, absent, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum NotificationCategory {
  account,
  events,
  meetings,
  contributions,
  news,
  opportunities,
  announcements,
  unknown,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum OpportunityType { job, internship, scholarship, training, other, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum ApplyMethod { url, email, viaBureau, unknown }

@JsonEnum(fieldRename: FieldRename.snake)
enum ScanOutcome {
  recorded,
  alreadyRecorded,
  invalid,
  expired,
  notMember,
  unknown,
}

/// Envoyée seulement (`POST /me/devices`).
@JsonEnum(fieldRename: FieldRename.snake)
enum DevicePlatform { android, ios }

/// Permissions de `abilities[]`.
abstract final class Abilities {
  static const attendanceScan = 'attendance.scan';
}
