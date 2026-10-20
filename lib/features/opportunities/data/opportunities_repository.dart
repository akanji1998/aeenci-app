import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/paginated.dart';
import '../../../core/api/token_store.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_content.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/opportunity.dart';

part 'opportunities_repository.g.dart';

/// Opportunités reçues. Détail et intérêt arrivent au lot 8.
abstract interface class OpportunitiesRepository {
  /// `GET /me/opportunities?page=` ; `meta.unseen_count` : non vues.
  Future<Paginated<Opportunity>> fetchPage({int page = 1});
}

class ApiOpportunitiesRepository implements OpportunitiesRepository {
  const ApiOpportunitiesRepository(this._api);

  final ApiClient _api;

  @override
  Future<Paginated<Opportunity>> fetchPage({int page = 1}) =>
      _api.getPage('/me/opportunities', Opportunity.fromJson, page: page);
}

class MockOpportunitiesRepository implements OpportunitiesRepository {
  const MockOpportunitiesRepository(this._runtime, this._tokens);

  final MockRuntime _runtime;
  final TokenStore _tokens;

  @override
  Future<Paginated<Opportunity>> fetchPage({int page = 1}) async {
    await _runtime.simulate();
    final persona = await currentMockPersona(_tokens);
    return Paginated.fromJson(
      persona.opportunitiesPageJson(DateTime.now()),
      Opportunity.fromJson,
    );
  }
}

@Riverpod(keepAlive: true)
OpportunitiesRepository opportunitiesRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockOpportunitiesRepository(
        ref.watch(mockRuntimeProvider),
        ref.watch(tokenStoreProvider),
      )
    : ApiOpportunitiesRepository(ref.watch(apiClientProvider));
