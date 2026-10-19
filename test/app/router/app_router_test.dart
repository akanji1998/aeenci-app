import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/auth/presentation/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

/// Adresse de l'écran visible (y compris un écran empilé).
String location(ProviderContainer container) =>
    container.read(appRouterProvider).state.uri.toString();

Finder appBarTitle(String text) =>
    find.descendant(of: find.byType(AppBar), matching: find.text(text));

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('connexion', () {
    testWidgets('sans jeton : écran de connexion', (tester) async {
      final container = await pumpAeenci(tester);
      expect(location(container), AppRoutes.login);
      expect(find.text('Comptes de démonstration'), findsOneWidget);
    });

    testWidgets('membre : connexion puis accueil à cinq onglets', (
      tester,
    ) async {
      final container = await pumpAeenci(tester);
      await tester.tap(find.text('Membre'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.home);
      expect(find.byType(NavigationBar), findsOneWidget);
      for (final tab in [
        'Accueil',
        'Carte',
        'Événements',
        'Cotisations',
        'Profil',
      ]) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('formulaire : erreur 422 sous le champ e-mail', (tester) async {
      await pumpAeenci(tester);
      await tester.enterText(
        find.byType(TextField).first,
        MockPersona.member.email,
      );
      await tester.enterText(find.byType(TextField).last, 'mauvais');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ces identifiants ne correspondent à aucun compte.'),
        findsOneWidget,
      );
    });

    testWidgets('candidat : seulement le suivi, sans onglets', (tester) async {
      final container = await pumpAeenci(tester);
      await tester.tap(find.text('Candidat'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.membershipStatus);
      expect(find.byType(NavigationBar), findsNothing);

      container.read(appRouterProvider).go(AppRoutes.card);
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.membershipStatus);
    });

    testWidgets('compte sans fiche : message et reste déconnecté', (
      tester,
    ) async {
      // Écran haut : tout le formulaire tient sans défilement.
      final container = await pumpAeenci(tester, size: const Size(390, 1400));
      await tester.tap(find.text('Sans fiche'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.login);
      expect(find.text('Ce compte n\'a pas d\'espace membre.'), findsOneWidget);
    });

    testWidgets(
      'lien protégé sans session → connexion, puis l\'écran demandé',
      (tester) async {
        final container = await pumpAeenci(tester);
        container.read(appRouterProvider).go('/evenements/joe-2026');
        await tester.pumpAndSettle();
        expect(location(container), '/connexion?from=%2Fevenements%2Fjoe-2026');

        await tester.tap(find.text('Membre'));
        await tester.pumpAndSettle();
        expect(location(container), '/evenements/joe-2026');
        expect(appBarTitle('Événement'), findsOneWidget);
      },
    );
  });

  group('membre connecté', () {
    testWidgets('chaque onglet garde sa pile', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
      );
      expect(location(container), AppRoutes.home);

      await tapTab(tester, 'Profil');
      await tester.tap(find.text('Ma fiche'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.profileSheet);

      await tapTab(tester, 'Carte');
      expect(appBarTitle('Ma carte'), findsOneWidget);

      await tapTab(tester, 'Profil');
      expect(location(container), AppRoutes.profileSheet);

      // Second appui : retour à la racine de l'onglet.
      await tapTab(tester, 'Profil');
      expect(location(container), AppRoutes.profile);
    });

    testWidgets('écrans hors onglets, avec retour', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
      );
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(location(container), AppRoutes.notifications);

      // pageBack() cherche l'infobulle anglaise « Back » ; ici « Retour ».
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.home);
    });

    testWidgets('scan : lien et accès réservés au bureau', (tester) async {
      final member = await pumpAeenci(tester, token: MockPersona.member.token);
      expect(find.text('Scanner les présences'), findsNothing);
      member.read(appRouterProvider).go(AppRoutes.scan);
      await tester.pumpAndSettle();
      expect(location(member), AppRoutes.home);
    });

    testWidgets('scan accessible au bureau', (tester) async {
      final bureau = await pumpAeenci(tester, token: MockPersona.bureau.token);
      await tester.tap(find.text('Scanner les présences'));
      await tester.pumpAndSettle();
      expect(location(bureau), AppRoutes.scan);
    });

    testWidgets('déconnexion → connexion', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
      );
      await tapTab(tester, 'Profil');
      await tester.scrollUntilVisible(
        find.text('Se déconnecter'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.login);
      expect(
        container.read(sessionControllerProvider),
        isA<SessionSignedOut>(),
      );
    });

    testWidgets('session expirée (401) → connexion avec message et retour', (
      tester,
    ) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
      );
      await tapTab(tester, 'Cotisations');
      await container.read(apiClientProvider).signalUnauthorized();
      await tester.pumpAndSettle();
      expect(location(container), '/connexion?from=%2Fcotisations');
      expect(find.text('Ta session a expiré. Reconnecte-toi.'), findsOneWidget);

      await tester.tap(find.text('Membre'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.contributions);
    });

    testWidgets('barre d\'onglets à 200 % sur un petit écran', (tester) async {
      await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        size: const Size(320, 568),
        textScale: 2,
      );
      for (final tab in [
        'Carte',
        'Événements',
        'Cotisations',
        'Profil',
        'Accueil',
      ]) {
        await tapTab(tester, tab);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
