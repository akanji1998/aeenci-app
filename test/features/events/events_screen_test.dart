import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/design/components/app_button.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/utils/device_services.dart';
import 'package:aeenci_app/features/events/data/events_repository.dart';
import 'package:aeenci_app/features/events/domain/event.dart';
import 'package:aeenci_app/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

class FakeDeviceServices implements DeviceServices {
  final calendar =
      <({String title, DateTime start, DateTime end, String? location})>[];
  final maps = <String>[];

  @override
  Future<bool> addToCalendar({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    calendar.add((title: title, start: start, end: end, location: location));
    return true;
  }

  @override
  Future<bool> openMap(String location) async {
    maps.add(location);
    return true;
  }

  @override
  Future<bool> openUrl(String url) async => true;
}

/// Dépôt mock dont l'inscription répond 422 « inscriptions fermées » :
/// l'événement a été fermé entre-temps côté backend.
class _ClosedMeanwhile implements EventsRepository {
  _ClosedMeanwhile(this._inner);

  final EventsRepository _inner;

  @override
  Future<Registration> register(String eventSlug) async =>
      throw const ValidationException(
        errors: {
          'event': ['Les inscriptions à cet événement viennent de fermer.'],
        },
      );

  @override
  Future<void> cancel(int registrationId) => _inner.cancel(registrationId);
  @override
  Future<List<Attendance>> fetchAttendances({int months = 12}) =>
      _inner.fetchAttendances(months: months);
  @override
  Future<Event> fetchEvent(String slug) => _inner.fetchEvent(slug);
  @override
  Future<NextMeeting?> fetchNextMeeting() => _inner.fetchNextMeeting();
  @override
  Future<List<Registration>> fetchRegistrations() =>
      _inner.fetchRegistrations();
  @override
  Future<List<Event>> fetchUpcomingEvents({EventType? type}) =>
      _inner.fetchUpcomingEvents(type: type);
}

Future<void> openEvents(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Événements'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openView(WidgetTester tester, String label) async {
  final selector = find.byWidgetPredicate((w) => w is SegmentedButton);
  await tester.tap(find.descendant(of: selector, matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// Carte de l'événement [title], défilée jusqu'à être visible.
Future<Finder> card(WidgetTester tester, String title) async {
  final finder = find.ancestor(
    of: find.text(title),
    matching: find.byType(EventCard),
  );
  await tester.scrollUntilVisible(
    find.text(title),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  return finder;
}

Finder buttonIn(Finder scope, String label) =>
    find.descendant(of: scope, matching: find.text(label));

void main() {
  testWidgets('à venir : cartes, état des inscriptions, inscriptions fermées', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openEvents(tester);

    expect(find.text('Événements'), findsWidgets);
    final joe = await card(tester, 'JOE de test');
    // Fiche au féminin : « Inscrite ».
    expect(buttonIn(joe, 'Inscrite'), findsOneWidget);
    expect(buttonIn(joe, 'Ajouter au calendrier'), findsOneWidget);

    final closed = await card(tester, 'Événement de test complet');
    final closedButton = tester.widget<AppButton>(
      find.descendant(
        of: closed,
        matching: find.byWidgetPredicate(
          (w) => w is AppButton && w.label == 'Inscriptions fermées',
        ),
      ),
    );
    expect(closedButton.onPressed, isNull);
  });

  testWidgets('filtre par type', (tester) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openEvents(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Journée de l\'emploi'));
    await tester.pumpAndSettle();
    expect(find.text('Journée de l\'emploi de test'), findsOneWidget);
    expect(find.text('JOE de test'), findsNothing);
    expect(find.text('Programme Impact de test'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tous'));
    await tester.pumpAndSettle();
    expect(find.text('JOE de test'), findsOneWidget);
  });

  testWidgets('inscription puis annulation, visibles partout', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await openEvents(tester);

    // Inscription.
    var emploi = await card(tester, 'Journée de l\'emploi de test');
    await tester.tap(buttonIn(emploi, 'S\'inscrire'));
    await tester.pumpAndSettle();
    expect(find.text('Inscription enregistrée.'), findsOneWidget);
    emploi = await card(tester, 'Journée de l\'emploi de test');
    expect(buttonIn(emploi, 'Inscrite'), findsOneWidget);

    // Mes inscriptions : la nouvelle inscription y figure.
    await openView(tester, 'Mes inscriptions');
    expect(find.text('Journée de l\'emploi de test'), findsOneWidget);
    expect(find.text('JOE de test'), findsOneWidget);

    // Annulation, avec confirmation.
    final tile = find.ancestor(
      of: find.text('Journée de l\'emploi de test'),
      matching: find.byType(Card),
    );
    await tester.tap(find.descendant(of: tile, matching: find.text('Annuler')));
    await tester.pumpAndSettle();
    expect(find.text('Annuler ton inscription ?'), findsOneWidget);
    await tester.tap(find.text('Garder'));
    await tester.pumpAndSettle();
    expect(find.text('Journée de l\'emploi de test'), findsOneWidget);

    await tester.tap(find.descendant(of: tile, matching: find.text('Annuler')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler l\'inscription'));
    await tester.pumpAndSettle();
    expect(find.text('Inscription annulée.'), findsOneWidget);
    expect(find.text('Journée de l\'emploi de test'), findsNothing);

    // Dernière inscription annulée : état vide de la maquette.
    final joeTile = find.ancestor(
      of: find.text('JOE de test'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: joeTile, matching: find.text('Annuler')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler l\'inscription'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune inscription à venir'), findsOneWidget);

    // L'accueil n'affiche plus d'événement inscrit dans « Bientôt ».
    container.read(appRouterProvider).go('/accueil');
    await tester.pumpAndSettle();
    expect(find.text('JOE de test'), findsNothing);
  });

  testWidgets('inscriptions fermées entre-temps : erreur 422 expliquée', (
    tester,
  ) async {
    late MockEventsRepository inner;
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [
        eventsRepositoryProvider.overrideWith((ref) {
          inner = MockEventsRepository(
            ref.watch(mockRuntimeProvider),
            ref.watch(tokenStoreProvider),
          );
          return _ClosedMeanwhile(inner);
        }),
      ],
    );
    await openEvents(tester);
    final emploi = await card(tester, 'Journée de l\'emploi de test');
    await tester.tap(buttonIn(emploi, 'S\'inscrire'));
    await tester.pumpAndSettle();
    expect(
      find.text('Les inscriptions à cet événement viennent de fermer.'),
      findsOneWidget,
    );
  });

  testWidgets('pas de réseau à l\'inscription : message clair', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await openEvents(tester);
    final emploi = await card(tester, 'Journée de l\'emploi de test');
    container
        .read(mockBehaviorControllerProvider.notifier)
        .set(MockBehavior.instant.copyWith(failure: MockFailure.network));
    await tester.tap(buttonIn(emploi, 'S\'inscrire'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
  });

  testWidgets('ajout au calendrier', (tester) async {
    final device = FakeDeviceServices();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await openEvents(tester);
    final joe = await card(tester, 'JOE de test');
    await tester.tap(buttonIn(joe, 'Ajouter au calendrier'));
    await tester.pumpAndSettle();
    expect(device.calendar.single.title, 'JOE de test');
    expect(device.calendar.single.location, 'Lieu de test');
    expect(
      device.calendar.single.end.isAfter(device.calendar.single.start),
      isTrue,
    );
  });

  testWidgets(
    'détail : description, public, lieu dans l\'application de cartes',
    (tester) async {
      final device = FakeDeviceServices();
      await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        overrides: [deviceServicesProvider.overrideWithValue(device)],
      );
      await openEvents(tester);
      await tester.tap(find.text('JOE de test'));
      await tester.pumpAndSettle();

      expect(
        find.text('Description de test de la journée d\'orientation.'),
        findsOneWidget,
      );
      expect(find.text('Public : Ouvert à tous'), findsOneWidget);
      await tester.tap(find.text('Lieu de test'));
      await tester.pumpAndSettle();
      expect(device.maps, ['Lieu de test']);
    },
  );

  testWidgets('détail d\'un événement inconnu : message clair', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    container.read(appRouterProvider).go('/evenements/inconnu');
    await tester.pumpAndSettle();
    expect(find.textContaining('n\'existe pas'), findsOneWidget);
  });

  testWidgets('présences : badge accordé, résumé, grille et légende', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openEvents(tester);
    await openView(tester, 'Présences');

    expect(find.text('Assemblées'), findsOneWidget);
    expect(find.text('Membre active'), findsOneWidget);
    expect(
      find.text(
        '5 présences sur les 12 derniers mois. Il en faut au moins 3 pour rester active.',
      ),
      findsOneWidget,
    );
    expect(find.text('Pas d\'assemblée'), findsOneWidget);
    expect(find.text('Excusé'), findsOneWidget);
  });

  for (final view in ['À venir', 'Mes inscriptions', 'Présences']) {
    testWidgets('$view à 200 % sur un petit écran', (tester) async {
      await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        size: const Size(320, 568),
        textScale: 2,
      );
      await openEvents(tester);
      if (view != 'À venir') await openView(tester, view);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
