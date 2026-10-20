import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/config/env_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/domain/enums.dart';
import '../../../core/mock/mock_behavior.dart';
import '../domain/app_notification.dart';

part 'devices_repository.g.dart';

/// Téléphones enregistrés pour les notifications push.
abstract interface class DevicesRepository {
  /// `POST /me/devices` : 204. Un jeton déjà connu est rattaché au compte
  /// qui appelle.
  Future<void> register(DeviceRegistration device);

  /// `DELETE /me/devices/{token}` : 204.
  Future<void> unregister(String token);
}

class ApiDevicesRepository implements DevicesRepository {
  const ApiDevicesRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> register(DeviceRegistration device) =>
      _api.send('POST', '/me/devices', data: device.toJson());

  @override
  Future<void> unregister(String token) =>
      _api.send('DELETE', '/me/devices/${Uri.encodeComponent(token)}');
}

/// Garde les jetons enregistrés en mémoire (visibles dans les tests).
class MockDevicesRepository implements DevicesRepository {
  MockDevicesRepository(this._runtime);

  final MockRuntime _runtime;
  final registered = <String, DeviceRegistration>{};
  final unregistered = <String>[];

  @override
  Future<void> register(DeviceRegistration device) async {
    await _runtime.simulate();
    registered[device.token] = device;
  }

  @override
  Future<void> unregister(String token) async {
    await _runtime.simulate();
    registered.remove(token);
    unregistered.add(token);
  }
}

@Riverpod(keepAlive: true)
DevicesRepository devicesRepository(Ref ref) =>
    ref.watch(envConfigProvider).useMocks
    ? MockDevicesRepository(ref.watch(mockRuntimeProvider))
    : ApiDevicesRepository(ref.watch(apiClientProvider));

/// Version de l'application envoyée avec le jeton.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

/// Enregistre le jeton du téléphone et le retire à la déconnexion. Les
/// échecs sont silencieux : un nouvel essai a lieu au prochain démarrage
/// ou au prochain renouvellement du jeton.
class DeviceRegistrar {
  DeviceRegistrar(this._ref);

  final Ref _ref;
  String? _registered;

  /// Jeton enregistré pendant cette session de l'application.
  String? get registeredToken => _registered;

  Future<void> register(String token) async {
    try {
      final version = await _ref.read(appVersionProvider.future);
      await _ref
          .read(devicesRepositoryProvider)
          .register(
            DeviceRegistration(
              token: token,
              platform: Platform.isIOS
                  ? DevicePlatform.ios
                  : DevicePlatform.android,
              appVersion: version,
            ),
          );
      _registered = token;
    } on ApiException {
      // Hors connexion : réessai au prochain démarrage.
    }
  }

  /// Avant la déconnexion, tant que le jeton d'accès est valable.
  Future<void> unregisterQuietly() async {
    final token = _registered;
    if (token == null) return;
    _registered = null;
    try {
      await _ref.read(devicesRepositoryProvider).unregister(token);
    } on ApiException {
      // Hors connexion : le backend retirera le jeton invalide plus tard.
    }
  }

  /// Le compte a été supprimé : rien à retirer côté API.
  void forget() => _registered = null;
}

@Riverpod(keepAlive: true)
DeviceRegistrar deviceRegistrar(Ref ref) => DeviceRegistrar(ref);
