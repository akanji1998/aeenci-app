import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../domain/membership_application.dart';
import 'auth_repository.dart';

part 'membership_repository.g.dart';

/// Suivi de la demande d'adhésion du candidat connecté.
abstract interface class MembershipRepository {
  /// `GET /membership-application`.
  Future<MembershipApplication> fetchApplication();

  /// `GET /membership-fees` (public).
  Future<List<MembershipFee>> fetchFees();
}

class ApiMembershipRepository implements MembershipRepository {
  const ApiMembershipRepository(this._api);

  final ApiClient _api;

  @override
  Future<MembershipApplication> fetchApplication() =>
      _api.getData('/membership-application', MembershipApplication.fromJson);

  @override
  Future<List<MembershipFee>> fetchFees() =>
      _api.getList('/membership-fees', MembershipFee.fromJson);
}

class MockMembershipRepository implements MembershipRepository {
  const MockMembershipRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<MembershipApplication> fetchApplication() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    return MembershipApplication.fromJson(persona.membershipApplicationJson);
  }

  @override
  Future<List<MembershipFee>> fetchFees() async {
    await _runtime.simulate();
    return mockMembershipFeesJson.map(MembershipFee.fromJson).toList();
  }
}

@Riverpod(keepAlive: true)
MembershipRepository membershipRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockMembershipRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiMembershipRepository(ref.watch(apiClientProvider));
