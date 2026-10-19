import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'member.freezed.dart';
part 'member.g.dart';

/// `GET /me` : fiche du membre connecté (ou du candidat).
@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required int id,

    /// Matricule, `null` tant que l'adhésion n'est pas validée.
    String? memberNumber,
    required String lastName,
    required String firstNames,
    @JsonKey(unknownEnumValue: Gender.unknown) required Gender gender,
    @DateOnlyConverter() required DateTime birthDate,
    required String birthPlace,
    required String nationality,
    String? photoUrl,
    required String phone,
    String? whatsapp,
    required String email,
    String? address,
    required String city,
    @JsonKey(unknownEnumValue: AdmissionState.unknown)
    required AdmissionState admissionState,
    @JsonKey(unknownEnumValue: MemberStatus.unknown) MemberStatus? status,
    @JsonKey(unknownEnumValue: Engagement.unknown) Engagement? engagement,
    @JsonKey(unknownEnumValue: MemberCategory.unknown)
    required MemberCategory category,
    @NullableDateOnlyConverter() DateTime? joinedAt,
    @Default(<String>[]) List<String> abilities,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  bool get isAdmitted => admissionState == AdmissionState.approved;

  bool can(String ability) => abilities.contains(ability);
}
