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
  });

  /// Sans latence ni erreur (tests).
  static const instant = MockBehavior(latency: Duration.zero);

  final Duration latency;
  final MockFailure failure;

  /// `true` : seule la prochaine requête échoue.
  final bool failOnce;

  MockBehavior copyWith({
    Duration? latency,
    MockFailure? failure,
    bool? failOnce,
  }) => MockBehavior(
    latency: latency ?? this.latency,
    failure: failure ?? this.failure,
    failOnce: failOnce ?? this.failOnce,
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
