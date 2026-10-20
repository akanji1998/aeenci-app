import 'dart:async';

import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/core/cache/cache_store.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_content.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/auth/presentation/session_controller.dart';
import 'package:aeenci_app/features/card/presentation/card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../helpers/pump_aeenci.dart';
import '../../helpers/test_container.dart';

Future<void> openCard(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Carte'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Réseau coupé pour toutes les requêtes (mode avion).
const offline = MockBehavior(
  latency: Duration.zero,
  failure: MockFailure.network,
  failOnce: false,
);

/// Carte en cache qui expire après [delay].
/// La fiche (`/me`) est aussi en cache, comme après toute connexion.
Future<void> cacheCard(
  CacheStore cache,
  MockPersona persona,
  Duration delay,
) async {
  await cache.write('me', persona.meJson);
  await cache.write(CardController.cacheKey, {
    ...persona.cardJson(DateTime.now()),
    'qr_expires_at': DateTime.now().add(delay).toUtc().toIso8601String(),
    'qr_payload': 'AEENCI1.carte-en-cache.signature',
  });
}

String? cachedPayload(MemoryCacheStore cache) =>
    (cache.entries[CardController.cacheKey]?.json
            as Map<String, Object?>?)?['qr_payload']
        as String?;

void main() {
  testWidgets('carte du membre : nom, statut accordé, matricule, QR code', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openCard(tester);

    expect(find.text('Ma carte'), findsOneWidget);
    expect(find.text('Disponible hors connexion'), findsOneWidget);
    expect(find.text('Membre TEST'), findsOneWidget);
    // Fiche au féminin : « Membre active ».
    expect(find.text('Membre active'), findsOneWidget);
    expect(find.text('Élève ou étudiant'), findsOneWidget);
    expect(find.text('TEST-0001'), findsOneWidget);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr, isNotNull);
    expect(find.text('Scanner les présences'), findsNothing);
  });

  testWidgets('membre du bureau : statut et bouton de scan', (tester) async {
    await pumpAeenci(tester, token: MockPersona.bureau.token);
    await openCard(tester);
    expect(find.text('Ancien membre actif'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Scanner les présences'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Visible pour le bureau'.toUpperCase()), findsOneWidget);
  });

  testWidgets('mode avion après un premier chargement : la carte s\'affiche', (
    tester,
  ) async {
    final cache = MemoryCacheStore();
    // Premier lancement, en ligne : la carte est mise en cache.
    await pumpAeenci(tester, token: MockPersona.member.token, cache: cache);
    await openCard(tester);
    expect(find.text('TEST-0001'), findsOneWidget);
    expect(cache.entries.containsKey(CardController.cacheKey), isTrue);

    // Redémarrage en mode avion : même cache, aucune requête ne passe.
    await tester.pumpWidget(const SizedBox());
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      cache: cache,
      behavior: offline,
    );
    await openCard(tester);
    expect(find.text('TEST-0001'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('a expiré'), findsNothing);
  });

  testWidgets('expiration proche et réseau présent : la carte est renouvelée', (
    tester,
  ) async {
    final cache = MemoryCacheStore();
    await cacheCard(cache, MockPersona.member, const Duration(days: 3));
    await pumpAeenci(tester, token: MockPersona.member.token, cache: cache);
    await openCard(tester);
    expect(cachedPayload(cache), isNot('AEENCI1.carte-en-cache.signature'));
  });

  testWidgets('expiration proche, hors connexion : la carte en cache reste', (
    tester,
  ) async {
    final cache = MemoryCacheStore();
    await cacheCard(cache, MockPersona.member, const Duration(days: 3));
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      cache: cache,
      behavior: offline,
    );
    await openCard(tester);
    expect(find.text('TEST-0001'), findsOneWidget);
    expect(cachedPayload(cache), 'AEENCI1.carte-en-cache.signature');
  });

  testWidgets('carte expirée et hors connexion : avertissement', (
    tester,
  ) async {
    final cache = MemoryCacheStore();
    await cacheCard(cache, MockPersona.member, -const Duration(days: 1));
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      cache: cache,
      behavior: offline,
    );
    await openCard(tester);
    expect(
      find.text(
        'Ta carte a expiré : connecte-toi à Internet pour la renouveler.',
      ),
      findsOneWidget,
    );
    expect(find.text('TEST-0001'), findsOneWidget);
  });

  testWidgets('luminosité au maximum seulement quand la carte est visible', (
    tester,
  ) async {
    final brightness = FakeBrightness();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.bureau.token,
      brightness: brightness,
    );
    expect(brightness.calls, isEmpty);

    await openCard(tester);
    expect(brightness.isMaximized, isTrue);

    // Autre onglet : luminosité rétablie.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Accueil'),
      ),
    );
    await tester.pumpAndSettle();
    expect(brightness.isMaximized, isFalse);

    // Retour sur la carte, puis écran empilé par-dessus (scan).
    await openCard(tester);
    expect(brightness.isMaximized, isTrue);
    unawaited(container.read(appRouterProvider).push(AppRoutes.scan));
    await tester.pumpAndSettle();
    expect(brightness.isMaximized, isFalse);
  });

  testWidgets('à 200 % sur un petit écran, sans débordement', (tester) async {
    await pumpAeenci(
      tester,
      token: MockPersona.bureau.token,
      size: const Size(320, 568),
      textScale: 2,
    );
    await openCard(tester);
    await tester.scrollUntilVisible(
      find.text('Scanner les présences'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('une autre personne se connecte : sa propre carte', (
    tester,
  ) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await openCard(tester);
    expect(find.text('TEST-0001'), findsOneWidget);

    final session = container.read(sessionControllerProvider.notifier);
    await session.signOut();
    await tester.pumpAndSettle();
    await session.signIn(
      email: MockPersona.bureau.email,
      password: mockPassword,
    );
    await tester.pumpAndSettle();
    await openCard(tester);
    expect(find.text('TEST-0003'), findsOneWidget);
    expect(find.text('TEST-0001'), findsNothing);
  });
}
