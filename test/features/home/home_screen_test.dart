import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/paginated.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/utils/academic_year.dart';
import 'package:aeenci_app/features/home/presentation/home_screen.dart';
import 'package:aeenci_app/features/news/data/news_repository.dart';
import 'package:aeenci_app/features/news/domain/news.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

/// Fait défiler l'accueil jusqu'à [finder], entièrement visible (pas sous
/// la barre d'onglets).
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

class _FailingNews implements NewsRepository {
  int calls = 0;

  @override
  Future<Paginated<News>> fetchPage({int page = 1}) async {
    calls++;
    throw const ServerException(statusCode: 500);
  }
}

void main() {
  final year = academicYearOf(DateTime.now());

  testWidgets('accueil du membre : tous les blocs de la maquette', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);

    expect(find.text('Bonjour Membre'), findsOneWidget);
    expect(find.text('Cotisation $year'), findsOneWidget);
    expect(find.text('Payée en partie'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'Reste 4\s000 F CFA à régler')),
      findsOneWidget,
    );

    await scrollTo(tester, find.text('Assemblée mensuelle'));
    expect(find.text('BIENTÔT'), findsOneWidget);
    expect(find.text('JOE de test'), findsOneWidget);
    // Fiche au féminin : « Tu es inscrite ».
    expect(find.textContaining('Tu es inscrite'), findsOneWidget);
    expect(
      find.textContaining('Présente ta carte à l\'entrée'),
      findsOneWidget,
    );

    await scrollTo(tester, find.text('2 nouvelles'));
    expect(find.text('Opportunités pour toi'), findsOneWidget);
    expect(find.text('Offre d\'emploi de test'), findsOneWidget);

    await scrollTo(tester, find.text('Complète ton profil pro'));
    await scrollTo(tester, find.text('Actualité de test n° 2'));
    expect(find.text('Actualité de test n° 1'), findsOneWidget);
    expect(find.text('Actualité de test n° 3'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('membre du bureau : cotisation à jour, profil complet', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.bureau.token);
    expect(find.text('Bonjour Bureau'), findsOneWidget);
    expect(find.text('Ta cotisation est à jour.'), findsOneWidget);
    await scrollTo(tester, find.text('Actualité de test n° 2'));
    expect(find.text('Complète ton profil pro'), findsNothing);
    expect(find.textContaining('Tu es inscrit'), findsOneWidget);
  });

  testWidgets('un bloc en erreur n\'empêche pas les autres', (tester) async {
    final news = _FailingNews();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [newsRepositoryProvider.overrideWithValue(news)],
    );
    expect(find.text('Cotisation $year'), findsOneWidget);
    await scrollTo(tester, find.text('Ce bloc n\'a pas pu être chargé.'));
    expect(find.text('Complète ton profil pro'), findsOneWidget);

    final callsBefore = news.calls;
    await scrollTo(tester, find.text('Réessayer'));
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(news.calls, callsBefore + 1);
  });

  testWidgets('hors connexion : données en cache et bandeau', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    expect(find.textContaining('Hors connexion'), findsNothing);

    container
        .read(mockBehaviorControllerProvider.notifier)
        .set(
          const MockBehavior(
            latency: Duration.zero,
            failure: MockFailure.network,
            failOnce: false,
          ),
        );
    await tester.fling(find.text('Bonjour Membre'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hors connexion · mis à jour le'),
      findsOneWidget,
    );
    expect(find.text('Cotisation $year'), findsOneWidget);
  });

  testWidgets('la cotisation mène à l\'onglet Cotisations', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await tester.tap(find.text('Cotisation $year'));
    await tester.pumpAndSettle();
    expect(location(container), AppRoutes.contributions);
  });

  testWidgets('l\'événement mène à son détail', (tester) async {
    final container = await pumpAeenci(tester, token: MockPersona.member.token);
    await scrollTo(tester, find.text('JOE de test'));
    await tester.tap(find.text('JOE de test'));
    await tester.pumpAndSettle();
    expect(
      location(container),
      AppRoutes.eventDetail('evenement-test-a-venir'),
    );
  });

  testWidgets('à 200 % sur un petit écran, sans débordement', (tester) async {
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      size: const Size(320, 568),
      textScale: 2,
    );
    await scrollTo(tester, find.text('Actualité de test n° 2'));
    expect(tester.takeException(), isNull);
  });
}

String location(ProviderContainer container) =>
    container.read(appRouterProvider).state.uri.toString();
