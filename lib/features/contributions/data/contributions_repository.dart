import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/contribution.dart';

part 'contributions_repository.g.dart';

/// Cotisations du membre. Paiements et reçus arrivent au lot 5.
abstract interface class ContributionsRepository {
  /// `GET /me/contributions` : situation par année.
  Future<List<Contribution>> fetchContributions();
}

class ApiContributionsRepository implements ContributionsRepository {
  const ApiContributionsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Contribution>> fetchContributions() =>
      _api.getList('/me/contributions', Contribution.fromJson);
}

class MockContributionsRepository implements ContributionsRepository {
  const MockContributionsRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<List<Contribution>> fetchContributions() async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    final data =
        persona.contributionsJson(DateTime.now())['data']! as List<Object?>;
    return [
      for (final item in data)
        Contribution.fromJson(item! as Map<String, dynamic>),
    ];
  }
}

@Riverpod(keepAlive: true)
ContributionsRepository contributionsRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockContributionsRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiContributionsRepository(ref.watch(apiClientProvider));
