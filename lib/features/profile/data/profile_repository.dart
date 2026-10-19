import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/member.dart';

part 'profile_repository.g.dart';

/// Fiche du membre connecté. Les modifications arrivent au lot 6.
abstract interface class ProfileRepository {
  /// `GET /me`.
  Future<Member> fetchMe();
}

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<Member> fetchMe() => _api.getData('/me', Member.fromJson);
}

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<Member> fetchMe() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    return Member.fromJson(persona.meJson);
  }
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockProfileRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiProfileRepository(ref.watch(apiClientProvider));
