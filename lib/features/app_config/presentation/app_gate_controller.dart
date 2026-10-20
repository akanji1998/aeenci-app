import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/cache/cached_fetch.dart';
import '../../../core/utils/version.dart';
import '../data/app_config_repository.dart';
import '../domain/app_config.dart';

part 'app_gate_controller.g.dart';

/// Ce que `/app/config` permet au démarrage.
@immutable
sealed class AppGateState {
  const AppGateState();
}

final class GateChecking extends AppGateState {
  const GateChecking();
}

/// L'application démarre normalement. [config] est `null` si elle n'a pas
/// pu être lue (hors connexion sans cache) : on ne bloque pas.
final class GateOpen extends AppGateState {
  const GateOpen([this.config]);

  final AppConfig? config;
}

/// Version installée inférieure à `min_version`.
final class GateUpdateRequired extends AppGateState {
  const GateUpdateRequired(this.config);

  final AppConfig config;
}

final class GateMaintenance extends AppGateState {
  const GateMaintenance(this.config);

  final AppConfig config;
}

/// Version de l'application installée (`1.0.0`).
@Riverpod(keepAlive: true)
Future<String> installedVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

/// Décision à partir de la configuration et de la version installée.
///
/// Une maintenance n'est annoncée que d'après une configuration fraîche :
/// une valeur en cache, peut-être ancienne, ne bloque pas l'application.
/// Version installée inconnue ([installed] nul) : pas de mise à jour exigée.
AppGateState evaluateGate(Cached<AppConfig> config, String? installed) {
  if (installed != null &&
      compareVersions(installed, config.data.minVersion) < 0) {
    return GateUpdateRequired(config.data);
  }
  if (config.data.maintenance && !config.isOffline) {
    return GateMaintenance(config.data);
  }
  return GateOpen(config.data);
}

@Riverpod(keepAlive: true)
class AppGateController extends _$AppGateController {
  static const _cacheKey = 'app_config';

  @override
  AppGateState build() {
    Future.microtask(check);
    return const GateChecking();
  }

  /// Au démarrage, et « Réessayer » sur l'écran de maintenance.
  Future<void> check() async {
    state = const GateChecking();
    try {
      final config = await fetchWithCache<AppConfig>(
        cache: ref.read(cacheStoreProvider),
        key: _cacheKey,
        fetch: ref.read(appConfigRepositoryProvider).fetchConfig,
        toJson: (config) => config.toJson(),
        fromJson: (json) => AppConfig.fromJson(json! as Map<String, dynamic>),
      );
      state = evaluateGate(config, await _installedVersion());
    } on ApiException {
      state = const GateOpen();
    }
  }

  Future<String?> _installedVersion() async {
    try {
      return await ref.read(installedVersionProvider.future);
    } on Object {
      return null;
    }
  }
}
