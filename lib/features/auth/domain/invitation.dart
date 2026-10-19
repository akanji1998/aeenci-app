import 'package:freezed_annotation/freezed_annotation.dart';

part 'invitation.freezed.dart';
part 'invitation.g.dart';

/// `GET /invitations/{token}` : invitation d'un membre recensé.
@freezed
abstract class Invitation with _$Invitation {
  const factory Invitation({
    required String firstNames,
    required DateTime expiresAt,
  }) = _Invitation;

  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}
