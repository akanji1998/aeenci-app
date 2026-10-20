import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/cache/file_store.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/push/push_providers.dart';
import 'package:aeenci_app/core/push/push_service.dart';
import 'package:aeenci_app/core/utils/connectivity.dart';
import 'package:aeenci_app/core/utils/screen_brightness_service.dart';
import 'package:aeenci_app/features/app_config/presentation/app_gate_controller.dart';
import 'package:aeenci_app/features/notifications/data/devices_repository.dart';
import 'package:aeenci_app/features/scan/data/scan_queue_store.dart';
import 'package:flutter_riverpod/misc.dart';

final devMocksConfig = EnvConfig.resolve(flavor: Flavor.dev, apiBaseUrl: '');

/// Surcharges communes : mocks instantanés, jeton et cache en mémoire.
List<Override> testOverrides({
  required MemoryTokenStore tokens,
  required CacheStore cache,
  EnvConfig? env,
  MockBehavior behavior = MockBehavior.instant,
  FakeBrightness? brightness,
  FileStore? files,
  PushService? push,
  ScanQueueStore? scanQueue,
}) => [
  envConfigProvider.overrideWithValue(env ?? devMocksConfig),
  tokenStoreProvider.overrideWithValue(tokens),
  cacheStoreProvider.overrideWithValue(cache),
  fileStoreProvider.overrideWithValue(files ?? MemoryFileStore()),
  mockBehaviorControllerProvider.overrideWith(() => _TestMocks(behavior)),
  installedVersionProvider.overrideWith((ref) async => '1.0.0'),
  appVersionProvider.overrideWith((ref) async => '1.0.0'),
  // Notifications déjà autorisées : pas d'écran d'explication par défaut.
  scanQueueStoreProvider.overrideWithValue(scanQueue ?? MemoryScanQueueStore()),
  pushServiceProvider.overrideWithValue(
    push ?? ManualPushService(currentPermission: PushPermission.granted),
  ),
  // Greffons de la plateforme, absents des tests.
  connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
  screenBrightnessProvider.overrideWithValue(brightness ?? FakeBrightness()),
];

/// Luminosité factice : enregistre les appels.
class FakeBrightness implements ScreenBrightnessService {
  final calls = <String>[];

  bool get isMaximized => calls.isNotEmpty && calls.last == 'max';

  @override
  Future<void> maximize() async => calls.add('max');

  @override
  Future<void> restore() async => calls.add('restore');
}

class _TestMocks extends MockBehaviorController {
  _TestMocks(this._initial);

  final MockBehavior _initial;

  @override
  MockBehavior build() => _initial;
}
