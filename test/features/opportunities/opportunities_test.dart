import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/paginated.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/mock/mock_profile_store.dart';
import 'package:aeenci_app/core/utils/device_services.dart';
import 'package:aeenci_app/features/opportunities/data/opportunities_repository.dart';
import 'package:aeenci_app/features/opportunities/domain/opportunity.dart';
import 'package:flutter/material.dart';
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

Future<void> go(ProviderContainer c, WidgetTester tester, String to) async {
  c.read(appRouterProvider).go(to);
  await tester.pumpAndSettle();
}

/// Offre clôturée entre-temps : 422 sous `opportunity`.
class _Closed implements OpportunitiesRepository {
  _Closed(this._inner);

  final OpportunitiesRepository _inner;

  @override
  Future<Paginated<Opportunity>> fetchPage({int page = 1}) =>
      _inner.fetchPage(page: page);
  @override
  Future<OpportunityDetail> fetchDetail(int id) => _inner.fetchDetail(id);
  @override
  Future<void> expressInterest(int id, {required bool shareCv}) async =>
      throw const ValidationException(
        message: 'Cette offre est clôturée.',
        errors: {
          'opportunity': ['Cette offre est clôturée.'],
        },
      );
  @override
  Future<void> withdrawInterest(int id) => _inner.withdrawInterest(id);
  @override
  Future<List<int>> downloadJobDescription(OpportunityDetail o) =>
      _inner.downloadJobDescription(o);
}

void main() {
  testWidgets('de l\'accueil à la liste : nouvelles, vues, page suivante', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await scrollTo(tester, find.text('Opportunités pour toi'));
    await tester.tap(find.text('Opportunités pour toi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('relayées par le bureau'), findsOneWidget);
    expect(find.text('Nouvelle'), findsNWidgets(2));
    expect(find.text('Vue'), findsOneWidget);
    await scrollTo(tester, find.text('Voir les offres précédentes'));
    await tester.tap(find.text('Voir les offres précédentes'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Formation de test'));
    expect(find.textContaining('Profil › Notifications'), findsOneWidget);
  });

  testWidgets('détail : pourquoi, postuler, vue ensuite dans la liste', (
    tester,
  ) async {
    final device = FakeDeviceServices();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await go(container, tester, '/opportunites');
    await tester.tap(find.text('Offre d\'emploi de test'));
    await tester.pumpAndSettle();

    expect(find.text('Pourquoi tu la reçois'), findsOneWidget);
    expect(
      find.text(
        'Ton domaine (Domaine de test) et ta ville (Abidjan) correspondent '
        'au profil recherché.',
      ),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Postuler directement'));
    await tester.tap(find.text('Postuler directement'));
    await tester.pumpAndSettle();
    expect(device.urls, ['https://exemple.com/candidature']);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle'), findsOneWidget);
  });

  testWidgets('postuler par e-mail, fiche de poste, via le bureau', (
    tester,
  ) async {
    final device = FakeDeviceServices();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await go(container, tester, '/opportunites/39');
    expect(
      find.text(
        'Tes compétences (Compétence de test) et ta catégorie (Élève ou '
        'étudiant) correspondent au profil recherché.',
      ),
      findsOneWidget,
    );
    await scrollTo(tester, find.text('Ouvrir la fiche de poste'));
    await tester.tap(find.text('Ouvrir la fiche de poste'));
    await tester.pumpAndSettle();
    expect(device.openedFiles.single, endsWith('fiche-de-poste-39.pdf'));
    await scrollTo(tester, find.text('Postuler par e-mail'));
    await tester.tap(find.text('Postuler par e-mail'));
    await tester.pumpAndSettle();
    expect(device.urls.single, startsWith('mailto:recrutement@exemple.com'));

    await go(container, tester, '/opportunites/38');
    await scrollTo(tester, find.text('Candidature par le bureau'));
    expect(find.textContaining('secrétariat du bureau'), findsOneWidget);
    expect(find.text('Postuler directement'), findsNothing);
  });

  testWidgets('intérêt sans CV : case désactivée et jamais cochée', (
    tester,
  ) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await go(container, tester, '/opportunites/40');
    await scrollTo(tester, find.text('Je suis intéressée'));
    await tester.tap(find.text('Je suis intéressée'));
    await tester.pumpAndSettle();

    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isFalse);
    expect(box.onChanged, isNull);
    expect(find.text('Ajouter mon CV'), findsOneWidget);

    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Le bureau sait que tu es intéressée ✓'));
    expect(
      find.text('Ton CV ne sera pas transmis sans ton accord.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retirer mon intérêt'));
    await tester.pumpAndSettle();
    expect(find.text('Ton intérêt est retiré.'), findsOneWidget);
    expect(find.text('Je suis intéressée'), findsOneWidget);
  });

  testWidgets('intérêt avec CV : accord donné explicitement', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.bureau.token);
    await go(container, tester, '/opportunites/40');
    await scrollTo(tester, find.text('Je suis intéressé'));
    await tester.tap(find.text('Je suis intéressé'));
    await tester.pumpAndSettle();

    final tile = find.byType(CheckboxListTile);
    expect(tester.widget<CheckboxListTile>(tile).value, isFalse);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Le bureau sait que tu es intéressé ✓'));
    expect(
      find.text('Tu as autorisé la transmission de ton CV pour cette offre.'),
      findsOneWidget,
    );
    final store = container.read(mockProfileStoreProvider);
    final offer = store
        .opportunities(MockPersona.bureau)
        .firstWhere((o) => o['id'] == 40);
    expect(offer['cv_shared'], isTrue);
  });

  testWidgets('offre clôturée : erreur 422 dans la feuille', (tester) async {
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [
        opportunitiesRepositoryProvider.overrideWith(
          (ref) => _Closed(
            MockOpportunitiesRepository(
              ref.watch(mockRuntimeProvider),
              ref.watch(tokenStoreProvider),
              ref.watch(mockProfileStoreProvider),
            ),
          ),
        ),
      ],
    );
    await go(container, tester, '/opportunites/40');
    await scrollTo(tester, find.text('Je suis intéressée'));
    await tester.tap(find.text('Je suis intéressée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(find.text('Cette offre est clôturée.'), findsOneWidget);
  });

  testWidgets('offre non reçue : message clair', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await go(container, tester, '/opportunites/999');
    expect(
      find.text('Cette offre n\'existe pas ou ne t\'a pas été adressée.'),
      findsOneWidget,
    );
  });

  for (final route in ['/opportunites', '/opportunites/40']) {
    testWidgets('$route à 200 % sur un petit écran', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        size: const Size(320, 640),
        textScale: 2,
      );
      await go(container, tester, route);
      for (var i = 0; i < 8; i++) {
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
