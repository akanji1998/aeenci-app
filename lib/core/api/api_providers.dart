import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/config/env_config.dart';
import '../cache/cache_store.dart';
import '../mock/mock_behavior.dart';
import 'api_client.dart';
import 'token_store.dart';

part 'api_providers.g.dart';

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore();

@Riverpod(keepAlive: true)
CacheStore cacheStore(Ref ref) => FileCacheStore(
  () async =>
      Directory('${(await getApplicationSupportDirectory()).path}/offline_cache'),
);

@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final env = ref.watch(envConfigProvider);
  final client = ApiClient(
    // Avec les mocks sans API, aucune requête ne part : l'URL est fictive.
    baseUrl: env.apiBaseUrl.isEmpty ? 'http://mocks.invalid' : env.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    log: env.isDev ? (line) => developer.log(line, name: 'api') : null,
  );
  ref.onDispose(client.dispose);
  return client;
}

/// Latence et erreurs simulées, réglables depuis la page des composants.
@Riverpod(keepAlive: true)
class MockBehaviorController extends _$MockBehaviorController {
  @override
  MockBehavior build() => const MockBehavior();

  void set(MockBehavior behavior) => state = behavior;
}

@Riverpod(keepAlive: true)
MockRuntime mockRuntime(Ref ref) => MockRuntime(
  () => ref.read(mockBehaviorControllerProvider),
  (behavior) => ref.read(mockBehaviorControllerProvider.notifier).set(behavior),
  onUnauthorized: () => ref.read(apiClientProvider).signalUnauthorized(),
);
