import 'package:aeenci_app/app/app.dart';
import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/core/api/token_store.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
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
}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final container = ProviderContainer(
    overrides: testOverrides(
      tokens: MemoryTokenStore(token),
      cache: MemoryCacheStore(),
      env: env,
    ),
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AeenciApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
