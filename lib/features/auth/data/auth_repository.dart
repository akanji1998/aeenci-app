import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../domain/auth_user.dart';

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
    await _api.sendRaw(
      'POST',
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
    ),
  );

  @override
  Future<void> logout() => _api.send('POST', '/auth/logout');
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
