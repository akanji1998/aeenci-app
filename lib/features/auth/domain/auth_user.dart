import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// `user` de la réponse de connexion.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required int id,
    required String email,
    @Default(<String>[]) List<String> roles,
    @Default(<String>[]) List<String> abilities,

    /// `null` : compte sans fiche de membre (ex. administration seule).
    int? memberId,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}

/// Réponse de `/auth/login`, `/auth/reset-password` et de l'activation.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({required String token, required AuthUser user}) =
      _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
