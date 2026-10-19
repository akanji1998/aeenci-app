import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'contact_info.freezed.dart';
part 'contact_info.g.dart';

/// `GET /site/contact` : coordonnées et numéros Mobile Money
/// (encart « Comment payer ? »).
@freezed
abstract class ContactInfo with _$ContactInfo {
  const factory ContactInfo({
    String? email,
    String? phone,
    String? whatsapp,
    String? address,
    @Default(<MobileMoneyAccount>[]) List<MobileMoneyAccount> mobileMoney,
    @Default(<SocialLink>[]) List<SocialLink> socialLinks,
  }) = _ContactInfo;

  factory ContactInfo.fromJson(Map<String, dynamic> json) =>
      _$ContactInfoFromJson(json);
}

@freezed
abstract class MobileMoneyAccount with _$MobileMoneyAccount {
  const factory MobileMoneyAccount({
    @JsonKey(unknownEnumValue: MobileMoneyOperator.unknown)
    required MobileMoneyOperator operator,
    required String number,
    required String accountName,
  }) = _MobileMoneyAccount;

  factory MobileMoneyAccount.fromJson(Map<String, dynamic> json) =>
      _$MobileMoneyAccountFromJson(json);
}

@freezed
abstract class SocialLink with _$SocialLink {
  const factory SocialLink({required String network, required String url}) =
      _SocialLink;

  factory SocialLink.fromJson(Map<String, dynamic> json) =>
      _$SocialLinkFromJson(json);
}
