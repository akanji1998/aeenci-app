import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_data.dart';
import '../domain/app_config.dart';

part 'app_config_repository.g.dart';

/// `GET /app/config` (public).
abstract interface class AppConfigRepository {
  Future<AppConfig> fetchConfig();
}

class ApiAppConfigRepository implements AppConfigRepository {
  const ApiAppConfigRepository(this._api);

  final ApiClient _api;

  @override
  Future<AppConfig> fetchConfig() =>
      _api.getData('/app/config', AppConfig.fromJson);
}

class MockAppConfigRepository implements AppConfigRepository {
  const MockAppConfigRepository(this._runtime);

  final MockRuntime _runtime;

  @override
  Future<AppConfig> fetchConfig() async {
    await _runtime.simulate();
    final flags = _runtime.takeConfigFlags();
    return AppConfig.fromJson(
      mockAppConfigJson(
        minVersion: flags.updateRequired ? '99.0.0' : '1.0.0',
        maintenance: flags.maintenance,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockAppConfigRepository(ref.watch(mockRuntimeProvider))
    : ApiAppConfigRepository(ref.watch(apiClientProvider));
