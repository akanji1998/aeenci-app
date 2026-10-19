import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'opportunity.freezed.dart';
part 'opportunity.g.dart';

/// `GET /me/opportunities` (liste).
@freezed
abstract class Opportunity with _$Opportunity {
  const factory Opportunity({
    required int id,
    @JsonKey(unknownEnumValue: OpportunityType.unknown)
    required OpportunityType type,
    required String title,
    required String organization,
    String? location,
    @NullableDateOnlyConverter() DateTime? deadline,
    required DateTime receivedAt,
    required bool seen,
    required bool interested,
  }) = _Opportunity;

  factory Opportunity.fromJson(Map<String, dynamic> json) =>
      _$OpportunityFromJson(json);
}

/// `GET /me/opportunities/{id}` (détail).
@freezed
abstract class OpportunityDetail with _$OpportunityDetail {
  const factory OpportunityDetail({
    required int id,
    @JsonKey(unknownEnumValue: OpportunityType.unknown)
    required OpportunityType type,
    required String title,
    required String organization,
    String? location,
    @NullableDateOnlyConverter() DateTime? deadline,
    required DateTime receivedAt,
    required bool seen,
    required bool interested,
    required String description,
    @JsonKey(unknownEnumValue: ApplyMethod.unknown)
    required ApplyMethod applyMethod,
    String? applyUrl,
    String? applyEmail,
    String? applyNote,
    String? jobDescriptionUrl,
    required MatchedOn matchedOn,
    required bool cvShared,
  }) = _OpportunityDetail;

  factory OpportunityDetail.fromJson(Map<String, dynamic> json) =>
      _$OpportunityDetailFromJson(json);
}

/// Critères qui ont fait correspondre ce membre (« Pourquoi tu la reçois »).
@freezed
abstract class MatchedOn with _$MatchedOn {
  const factory MatchedOn({
    @Default(<String>[]) List<String> domains,
    @Default(<String>[]) List<String> skills,
    @Default(<String>[]) List<String> cities,
    @JsonKey(unknownEnumValue: MemberCategory.unknown)
    @Default(<MemberCategory>[])
    List<MemberCategory> categories,
    @Default(<String>[]) List<String> educationLevels,
  }) = _MatchedOn;

  factory MatchedOn.fromJson(Map<String, dynamic> json) =>
      _$MatchedOnFromJson(json);
}
