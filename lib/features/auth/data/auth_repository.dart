import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../domain/auth_user.dart';
import '../domain/invitation.dart';

part 'auth_repository.g.dart';

/// Connexion et déconnexion par jeton.
abstract interface class AuthRepository {
  /// `POST /auth/login`. 422 sous `email` si les identifiants sont faux.
  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceName,
  });

  /// `POST /auth/logout` : révoque le jeton courant.
  Future<void> logout();

  /// `POST /auth/forgot-password` : 204 même si l'adresse est inconnue.
  Future<void> forgotPassword({required String email});

  /// `POST /auth/reset-password` : nouveau mot de passe, session ouverte.
  Future<AuthSession> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  });

  /// `GET /invitations/{token}` : 404 si inconnue, 410 si expirée ou utilisée.
  Future<Invitation> fetchInvitation(String token);

  /// `POST /invitations/{token}/accept` avec `device_name` : compte créé,
  /// session ouverte.
  Future<AuthSession> acceptInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  });
}

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceName,
  }) async => AuthSession.fromJson(
    await _api.sendObject(
      'POST',
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
    ),
  );

  @override
  Future<void> logout() => _api.send('POST', '/auth/logout');

  @override
  Future<void> forgotPassword({required String email}) =>
      _api.send('POST', '/auth/forgot-password', data: {'email': email});

  @override
  Future<AuthSession> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async => AuthSession.fromJson(
    await _api.sendObject(
      'POST',
      '/auth/reset-password',
      data: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      },
    ),
  );

  @override
  Future<Invitation> fetchInvitation(String token) async => Invitation.fromJson(
    await _api.getObject('/invitations/${Uri.encodeComponent(token)}'),
  );

  @override
  Future<AuthSession> acceptInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async => AuthSession.fromJson(
    await _api.sendObject(
      'POST',
      '/invitations/${Uri.encodeComponent(token)}/accept',
      data: {
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      },
    ),
  );
}

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._runtime);

  final MockRuntime _runtime;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    await _runtime.simulate();
    if (password == mockPassword &&
        email.trim().toLowerCase() == mockNoMemberEmail) {
      return const AuthSession(
        token: 'mock-admin-token',
        user: AuthUser(id: 999, email: mockNoMemberEmail, roles: ['admin']),
      );
    }
    final persona = mockPersonaForEmail(email);
    if (persona == null || password != mockPassword) {
      throw const ValidationException(
        message: 'Ces identifiants ne correspondent à aucun compte.',
        errors: {
          'email': ['Ces identifiants ne correspondent à aucun compte.'],
        },
      );
    }
    return AuthSession.fromJson({
      'token': persona.token,
      'user': persona.userJson,
    });
  }

  @override
  Future<void> logout() => _runtime.simulate();

  @override
  Future<void> forgotPassword({required String email}) async {
    await _runtime.simulate();
    if (!email.contains('@')) {
      throw const ValidationException(
        errors: {
          'email': ['Saisis une adresse e-mail valide.'],
        },
      );
    }
  }

  @override
  Future<AuthSession> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    await _runtime.simulate();
    final persona = mockPersonaForEmail(email);
    if (token != mockResetToken || persona == null) {
      throw const ValidationException(
        errors: {
          'email': ['Ce lien de réinitialisation est invalide ou expiré.'],
        },
      );
    }
    _checkPasswords(password, passwordConfirmation);
    return AuthSession.fromJson({
      'token': persona.token,
      'user': persona.userJson,
    });
  }

  @override
  Future<Invitation> fetchInvitation(String token) async {
    await _runtime.simulate();
    return switch (token) {
      MockInvitations.valid => Invitation.fromJson(MockInvitations.validJson),
      MockInvitations.expired => throw const GoneException(),
      _ => throw const NotFoundException(),
    };
  }

  @override
  Future<AuthSession> acceptInvitation({
    required String token,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    await fetchInvitation(token);
    _checkPasswords(password, passwordConfirmation);
    return AuthSession.fromJson({
      'token': MockPersona.member.token,
      'user': MockPersona.member.userJson,
    });
  }

  /// Règles imitant celles du backend (Laravel), pour démontrer les 422.
  void _checkPasswords(String password, String confirmation) {
    if (password.length < 8) {
      throw const ValidationException(
        errors: {
          'password': ['Le mot de passe doit contenir au moins 8 caractères.'],
        },
      );
    }
    if (password != confirmation) {
      throw const ValidationException(
        errors: {
          'password': ['La confirmation ne correspond pas.'],
        },
      );
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => ref.watch(envConfigProvider).useMocks
    ? MockAuthRepository(ref.watch(mockRuntimeProvider))
    : ApiAuthRepository(ref.watch(apiClientProvider));

/// Utile aux dépôts mock : retrouve le compte factice connecté.
Future<MockPersona> currentMockPersona(TokenStore tokens) async {
  final persona = mockPersonaForToken(await tokens.read());
  if (persona == null) throw const UnauthorizedException();
  return persona;
}
