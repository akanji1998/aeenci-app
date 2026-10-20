import 'package:aeenci_app/app/app.dart';
import 'package:aeenci_app/app/bootstrap.dart';
import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_container.dart';

/// Lance l'application entière sur les mocks instantanés.
/// [token] : jeton factice déjà enregistré (ex. `MockPersona.member.token`).
Future<ProviderContainer> pumpAeenci(
  WidgetTester tester, {
  String? token,
  EnvConfig? env,
  Size size = const Size(390, 844),
  double textScale = 1,
  MockBehavior behavior = MockBehavior.instant,
  FakeBrightness? brightness,
  CacheStore? cache,
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: testOverrides(
      tokens: MemoryTokenStore(token),
      cache: cache ?? MemoryCacheStore(),
      env: env,
      behavior: behavior,
      brightness: brightness,
    ),
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AeenciApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Connexion par la feuille des comptes de démonstration (dev + mocks).
Future<void> signInAs(WidgetTester tester, String account) async {
  final open = find.text('Comptes de démonstration');
  // La liste construit ses éléments à la demande : on fait défiler.
  await tester.scrollUntilVisible(
    open,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(open);
  await tester.pumpAndSettle();
  await tester.tap(find.text(account));
  await tester.pumpAndSettle();
}
