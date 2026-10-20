import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/features/app_config/presentation/app_gate_controller.dart';
import 'package:flutter_riverpod/misc.dart';

final devMocksConfig = EnvConfig.resolve(flavor: Flavor.dev, apiBaseUrl: '');

/// Surcharges communes : mocks instantanés, jeton et cache en mémoire.
List<Override> testOverrides({
  required MemoryTokenStore tokens,
  required MemoryCacheStore cache,
  EnvConfig? env,
  MockBehavior behavior = MockBehavior.instant,
}) => [
  envConfigProvider.overrideWithValue(env ?? devMocksConfig),
  tokenStoreProvider.overrideWithValue(tokens),
  cacheStoreProvider.overrideWithValue(cache),
  mockBehaviorControllerProvider.overrideWith(() => _TestMocks(behavior)),
  installedVersionProvider.overrideWith((ref) async => '1.0.0'),
];

class _TestMocks extends MockBehaviorController {
  _TestMocks(this._initial);

  final MockBehavior _initial;

  @override
  MockBehavior build() => _initial;
}
