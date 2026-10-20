import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/utils/device_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_device_services.dart';
import '../../helpers/pump_aeenci.dart';

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> go(
  ProviderContainer container,
  WidgetTester tester,
  String to,
) async {
  container.read(appRouterProvider).go(to);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('de l\'accueil à la liste, page suivante, puis un article', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await scrollTo(tester, find.text('Toutes les actualités'));
    await tester.tap(find.text('Toutes les actualités'));
    await tester.pumpAndSettle();

    expect(find.text('Actualité de test n° 1'), findsOneWidget);
    expect(find.text('Actualité de test n° 4'), findsNothing);
    await scrollTo(tester, find.text('Voir les actualités précédentes'));
    await tester.tap(find.text('Voir les actualités précédentes'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Actualité de test n° 4'));
    await tester.tap(find.text('Actualité de test n° 4'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.textContaining('Publiée le'), findsOneWidget);
  });

  testWidgets('article : Markdown, lien ouvert, HTML non interprété', (
    tester,
  ) async {
    final device = FakeDeviceServices();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await go(container, tester, '/actualites/actualite-test-1');

    expect(find.text('Intertitre de test'), findsOneWidget);
    expect(find.textContaining('Premier point de test'), findsOneWidget);
    // Balise affichée telle quelle, jamais interprétée.
    expect(find.textContaining('<b>'), findsOneWidget);

    // Le lien est une partie du paragraphe : on touche ces mots-là.
    await tester.tapOnText(find.textRange.ofSubstring('lien de test'));
    await tester.pumpAndSettle();
    expect(device.urls, ['https://aeenci.com']);
  });

  testWidgets('article inconnu : message clair', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await go(container, tester, '/actualites/brouillon-ou-programmee');
    expect(
      find.text('Cette actualité n\'existe pas ou n\'est plus en ligne.'),
      findsOneWidget,
    );
  });

  for (final route in ['/actualites', '/actualites/actualite-test-1']) {
    testWidgets('$route à 200 % sur un petit écran', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        size: const Size(320, 640),
        textScale: 2,
      );
      await go(container, tester, route);
      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
