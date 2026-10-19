import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/date_only.dart';
import '../../../core/domain/enums.dart';

part 'member_card.freezed.dart';
part 'member_card.g.dart';

/// `GET /me/card` : carte de membre. L'application affiche [qrPayload] tel
/// quel, sans jamais le fabriquer ni le modifier.
@freezed
abstract class MemberCard with _$MemberCard {
  const factory MemberCard({
    required String memberNumber,
    required String fullName,
    String? photoUrl,
    @JsonKey(unknownEnumValue: MemberStatus.unknown)
    required MemberStatus status,
    @JsonKey(unknownEnumValue: Engagement.unknown) Engagement? engagement,
    @JsonKey(unknownEnumValue: MemberCategory.unknown)
    required MemberCategory category,
    @DateOnlyConverter() required DateTime joinedAt,
    required String qrPayload,
    required DateTime qrExpiresAt,
  }) = _MemberCard;

  factory MemberCard.fromJson(Map<String, dynamic> json) =>
      _$MemberCardFromJson(json);
}
