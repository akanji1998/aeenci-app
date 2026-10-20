import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';

/// Erreur que les mocks peuvent simuler.
enum MockFailure { none, network, unauthorized, validation, server }

/// Latence et erreurs simulées par les dépôts mock.
@immutable
class MockBehavior {
  const MockBehavior({
    this.latency = const Duration(milliseconds: 400),
    this.failure = MockFailure.none,
    this.failOnce = true,
    this.updateRequired = false,
    this.maintenance = false,
  });

  /// Sans latence ni erreur (tests).
  static const instant = MockBehavior(latency: Duration.zero);

  final Duration latency;
  final MockFailure failure;

  /// `true` : seule la prochaine requête échoue.
  final bool failOnce;

  /// `/app/config` exige une version plus récente (une seule fois).
  final bool updateRequired;

  /// `/app/config` annonce une maintenance (une seule fois).
  final bool maintenance;

  MockBehavior copyWith({
    Duration? latency,
    MockFailure? failure,
    bool? failOnce,
    bool? updateRequired,
    bool? maintenance,
  }) => MockBehavior(
    latency: latency ?? this.latency,
    failure: failure ?? this.failure,
    failOnce: failOnce ?? this.failOnce,
    updateRequired: updateRequired ?? this.updateRequired,
    maintenance: maintenance ?? this.maintenance,
  );

  ApiException? get exception => switch (failure) {
    MockFailure.none => null,
    MockFailure.network => const NetworkException(),
    MockFailure.unauthorized => const UnauthorizedException(),
    MockFailure.validation => const ValidationException(
      message: 'Erreur de validation simulée.',
      errors: {
        'email': ['Erreur simulée sous le champ.'],
      },
    ),
    MockFailure.server => const ServerException(statusCode: 500),
  };
}

/// Applique un [MockBehavior] à chaque appel d'un dépôt mock.
class MockRuntime {
  MockRuntime(this._read, this._write, {this.onUnauthorized});

  final MockBehavior Function() _read;
  final void Function(MockBehavior behavior) _write;

  /// Même effet qu'un 401 de l'API : jeton effacé, session prévenue.
  final Future<void> Function()? onUnauthorized;

  /// Lit puis efface les drapeaux de configuration simulés.
  ({bool updateRequired, bool maintenance}) takeConfigFlags() {
    final behavior = _read();
    if (behavior.updateRequired || behavior.maintenance) {
      _write(behavior.copyWith(updateRequired: false, maintenance: false));
    }
    return (
      updateRequired: behavior.updateRequired,
      maintenance: behavior.maintenance,
    );
  }

  /// À appeler au début de chaque méthode mock.
  Future<void> simulate() async {
    final behavior = _read();
    if (behavior.latency > Duration.zero) {
      await Future<void>.delayed(behavior.latency);
    }
    final exception = behavior.exception;
    if (exception == null) return;
    if (behavior.failOnce) _write(behavior.copyWith(failure: MockFailure.none));
    if (exception is UnauthorizedException) await onUnauthorized?.call();
    throw exception;
  }
}
