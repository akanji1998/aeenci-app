import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'event.freezed.dart';
part 'event.g.dart';

/// `GET /events`, `GET /events/{slug}`.
@freezed
abstract class Event with _$Event {
  const factory Event({
    required int id,
    required String slug,
    @JsonKey(unknownEnumValue: EventType.unknown) required EventType type,
    required String title,
    required String summary,
    required String description,
    int? edition,
    required DateTime startsAt,
    DateTime? endsAt,
    String? location,
    String? audience,
    String? imageUrl,
    required bool registrationOpen,
    int? attendeesCount,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

/// Événement résumé, dans une inscription.
@freezed
abstract class EventSummary with _$EventSummary {
  const factory EventSummary({
    required String slug,
    @JsonKey(unknownEnumValue: EventType.unknown) required EventType type,
    required String title,
    required DateTime startsAt,
    String? location,
  }) = _EventSummary;

  factory EventSummary.fromJson(Map<String, dynamic> json) =>
      _$EventSummaryFromJson(json);
}

/// `GET /me/registrations`, réponse de `POST /me/registrations`.
@freezed
abstract class Registration with _$Registration {
  const factory Registration({
    required int id,
    required EventSummary event,
    required DateTime createdAt,
    required bool canCancel,
  }) = _Registration;

  factory Registration.fromJson(Map<String, dynamic> json) =>
      _$RegistrationFromJson(json);
}

/// `GET /me/attendances` : présence à une assemblée.
@freezed
abstract class Attendance with _$Attendance {
  const factory Attendance({
    @DateOnlyConverter() required DateTime date,
    @JsonKey(unknownEnumValue: AttendanceState.unknown)
    required AttendanceState state,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

/// `GET /meetings/next` : prochaine assemblée (204 s'il n'y en a pas).
@freezed
abstract class NextMeeting with _$NextMeeting {
  const factory NextMeeting({required DateTime date, String? location}) =
      _NextMeeting;

  factory NextMeeting.fromJson(Map<String, dynamic> json) =>
      _$NextMeetingFromJson(json);
}
