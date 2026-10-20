import 'package:aeenci_app/core/cache/cached_fetch.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/app_config/domain/app_config.dart';
import 'package:aeenci_app/features/app_config/presentation/app_gate_controller.dart';
import 'package:flutter_test/flutter_test.dart';

AppConfig config({String minVersion = '1.0.0', bool maintenance = false}) =>
    AppConfig.fromJson(
      mockAppConfigJson(minVersion: minVersion, maintenance: maintenance),
    );

void main() {
  test('version suffisante → ouvert', () {
    expect(evaluateGate(Cached(config()), '1.0.0'), isA<GateOpen>());
    expect(evaluateGate(Cached(config()), '1.2.0'), isA<GateOpen>());
  });

  test('version inférieure à min_version → mise à jour nécessaire', () {
    expect(
      evaluateGate(Cached(config(minVersion: '1.1.0')), '1.0.9'),
      isA<GateUpdateRequired>(),
    );
  });

  test('la mise à jour passe avant la maintenance', () {
    expect(
      evaluateGate(
        Cached(config(minVersion: '2.0.0', maintenance: true)),
        '1.0.0',
      ),
      isA<GateUpdateRequired>(),
    );
  });

  test('maintenance annoncée par une configuration fraîche', () {
    expect(
      evaluateGate(Cached(config(maintenance: true)), '1.0.0'),
      isA<GateMaintenance>(),
    );
  });

  test('maintenance lue dans le cache hors connexion : ne bloque pas', () {
    final cached = Cached(
      config(maintenance: true),
      offlineSince: DateTime(2026, 10, 18),
    );
    expect(evaluateGate(cached, '1.0.0'), isA<GateOpen>());
  });

  test('mise à jour exigée, même d\'après le cache', () {
    final cached = Cached(
      config(minVersion: '1.5.0'),
      offlineSince: DateTime(2026, 10, 18),
    );
    expect(evaluateGate(cached, '1.0.0'), isA<GateUpdateRequired>());
  });

  test('version installée inconnue : pas de blocage', () {
    expect(
      evaluateGate(Cached(config(minVersion: '9.0.0')), null),
      isA<GateOpen>(),
    );
  });
}
