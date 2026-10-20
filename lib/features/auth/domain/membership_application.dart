import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'membership_application.freezed.dart';
part 'membership_application.g.dart';

/// `GET /membership-application` : suivi de la demande du candidat.
@freezed
abstract class MembershipApplication with _$MembershipApplication {
  const factory MembershipApplication({
    required int id,
    @JsonKey(unknownEnumValue: AdmissionState.unknown)
    required AdmissionState state,
    required DateTime submittedAt,
    DateTime? reviewedAt,
    String? decisionReason,
  }) = _MembershipApplication;

  factory MembershipApplication.fromJson(Map<String, dynamic> json) =>
      _$MembershipApplicationFromJson(json);
}

/// `GET /membership-fees` : droit d'adhésion en vigueur par catégorie.
@freezed
abstract class MembershipFee with _$MembershipFee {
  const factory MembershipFee({
    @JsonKey(unknownEnumValue: MemberCategory.unknown)
    required MemberCategory category,

    /// En F CFA.
    required int amount,
  }) = _MembershipFee;

  factory MembershipFee.fromJson(Map<String, dynamic> json) =>
      _$MembershipFeeFromJson(json);
}
