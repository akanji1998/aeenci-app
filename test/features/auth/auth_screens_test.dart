import 'package:aeenci_app/app/config/env_config.dart';
import 'package:aeenci_app/app/router/app_router.dart';
import 'package:aeenci_app/app/router/app_routes.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/design/components/app_button.dart';
import 'package:aeenci_app/core/design/components/app_text_field.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

String location(ProviderContainer container) =>
    container.read(appRouterProvider).state.uri.toString();

Future<void> open(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  container.read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, text);
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.byWidgetPredicate(
    (w) => w is AppButton && w.label == label,
  );
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('connexion', () {
    testWidgets('champs vides : « Ce champ est obligatoire. » sous chacun', (
      tester,
    ) async {
      await pumpAeenci(tester);
      await tapButton(tester, 'Se connecter');
      expect(find.text('Ce champ est obligatoire.'), findsNWidgets(2));
    });

    testWidgets('encart « Pas encore de compte ? » de la maquette', (
      tester,
    ) async {
      await pumpAeenci(tester);
      await tester.scrollUntilVisible(
        find.text('Adhérer sur aeenci.com'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pas encore de compte ?'), findsOneWidget);
    });

    testWidgets('formulaire rempli → accueil', (tester) async {
      final container = await pumpAeenci(tester);
      await enterField(tester, 'E-mail', MockPersona.member.email);
      await enterField(tester, 'Mot de passe', mockPassword);
      await tapButton(tester, 'Se connecter');
      expect(location(container), AppRoutes.home);
    });

    testWidgets('sans mocks : pas de comptes de démonstration', (tester) async {
      await pumpAeenci(
        tester,
        env: EnvConfig.resolve(
          flavor: Flavor.dev,
          apiBaseUrl: 'http://10.0.2.2:8000/api/v1',
          useMocks: false,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Adhérer sur aeenci.com'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Comptes de démonstration'), findsNothing);
    });
  });

  group('mot de passe oublié', () {
    testWidgets('depuis la connexion, envoi puis confirmation', (tester) async {
      final container = await pumpAeenci(tester);
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.forgotPassword);

      await tapButton(tester, 'Envoyer le lien');
      expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

      await enterField(tester, 'E-mail', 'inconnu@exemple.com');
      await tapButton(tester, 'Envoyer le lien');
      expect(find.text('Vérifie ta boîte e-mail'), findsOneWidget);
      expect(find.textContaining('inconnu@exemple.com'), findsOneWidget);

      await tapButton(tester, 'Retour à la connexion');
      expect(location(container), AppRoutes.login);
    });

    testWidgets('pas de réseau : message clair', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, AppRoutes.forgotPassword);
      container
          .read(mockBehaviorControllerProvider.notifier)
          .set(MockBehavior.instant.copyWith(failure: MockFailure.network));
      await enterField(tester, 'E-mail', MockPersona.member.email);
      await tapButton(tester, 'Envoyer le lien');
      expect(find.textContaining('Pas de connexion'), findsOneWidget);
    });
  });

  group('activation d\'un compte recensé', () {
    String link(String token) => '${AppRoutes.activateAccount}?token=$token';

    testWidgets('invitation valide → mot de passe → accueil', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, link(MockInvitations.valid));
      expect(find.text('Bonjour Membre'), findsOneWidget);

      await enterField(tester, 'Nouveau mot de passe', 'motdepasse-neuf');
      await enterField(tester, 'Confirme le mot de passe', 'autre-chose');
      await tapButton(tester, 'Activer mon compte');
      expect(
        find.text('Les deux mots de passe ne correspondent pas.'),
        findsOneWidget,
      );

      await enterField(tester, 'Confirme le mot de passe', 'motdepasse-neuf');
      await tapButton(tester, 'Activer mon compte');
      expect(location(container), AppRoutes.home);
    });

    testWidgets(
      'mot de passe refusé par le backend : erreur 422 sous le champ',
      (tester) async {
        final container = await pumpAeenci(tester);
        await open(tester, container, link(MockInvitations.valid));
        await enterField(tester, 'Nouveau mot de passe', 'court');
        await enterField(tester, 'Confirme le mot de passe', 'court');
        await tapButton(tester, 'Activer mon compte');
        expect(
          find.text('Le mot de passe doit contenir au moins 8 caractères.'),
          findsOneWidget,
        );
        expect(location(container), startsWith(AppRoutes.activateAccount));
      },
    );

    testWidgets('invitation expirée (410)', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, link(MockInvitations.expired));
      expect(find.textContaining('a expiré ou a déjà servi'), findsOneWidget);
      await tapButton(tester, 'Retour à la connexion');
      expect(location(container), AppRoutes.login);
    });

    testWidgets('invitation inconnue (404)', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, link('inconnue'));
      expect(find.textContaining('n\'est pas valide'), findsOneWidget);
    });

    testWidgets('lien sans jeton', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, AppRoutes.activateAccount);
      expect(find.text('Lien non valide'), findsOneWidget);
    });
  });

  group('nouveau mot de passe', () {
    testWidgets('lien valide : e-mail prérempli, session ouverte', (
      tester,
    ) async {
      final container = await pumpAeenci(tester);
      final uri = Uri(
        path: AppRoutes.resetPassword,
        queryParameters: {
          'token': mockResetToken,
          'email': MockPersona.member.email,
        },
      );
      await open(tester, container, uri.toString());
      expect(find.text(MockPersona.member.email), findsOneWidget);

      await enterField(tester, 'Nouveau mot de passe', 'motdepasse-neuf');
      await enterField(tester, 'Confirme le mot de passe', 'motdepasse-neuf');
      await tapButton(tester, 'Enregistrer le mot de passe');
      expect(location(container), AppRoutes.home);
    });

    testWidgets('jeton refusé : erreur sous l\'e-mail', (tester) async {
      final container = await pumpAeenci(tester);
      final uri = Uri(
        path: AppRoutes.resetPassword,
        queryParameters: {'token': 'faux', 'email': MockPersona.member.email},
      );
      await open(tester, container, uri.toString());
      await enterField(tester, 'Nouveau mot de passe', 'motdepasse-neuf');
      await enterField(tester, 'Confirme le mot de passe', 'motdepasse-neuf');
      await tapButton(tester, 'Enregistrer le mot de passe');
      await tester.scrollUntilVisible(
        find.text('E-mail'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Ce lien de réinitialisation est invalide ou expiré.'),
        findsOneWidget,
      );
    });

    testWidgets('lien sans jeton : nouvelle demande possible', (tester) async {
      final container = await pumpAeenci(tester);
      await open(tester, container, AppRoutes.resetPassword);
      await tapButton(tester, 'Demander un nouveau lien');
      expect(location(container), AppRoutes.forgotPassword);
    });
  });

  group('suivi de l\'adhésion', () {
    testWidgets('demande en attente : étapes, montant, contact', (
      tester,
    ) async {
      final container = await pumpAeenci(tester);
      await signInAs(tester, 'Candidat');
      expect(location(container), AppRoutes.membershipStatus);
      expect(find.text('Ta demande est en cours d\'examen'), findsOneWidget);
      expect(find.textContaining('12 octobre 2026'), findsOneWidget);
      expect(find.text('Examen par le bureau'), findsOneWidget);
      // Droit d'adhésion de la catégorie « élève ou étudiant » : 2 000 F CFA.
      expect(find.textContaining(RegExp(r'2\s000 F CFA')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('contact@exemple.com'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Une question ?'), findsOneWidget);
    });

    testWidgets('demande refusée : motif et nouvelle demande', (tester) async {
      await pumpAeenci(tester);
      await signInAs(tester, 'Candidat refusé');
      expect(find.text('Ta demande n\'a pas été validée'), findsOneWidget);
      expect(find.text('Motif'), findsOneWidget);
      expect(find.textContaining('pièce justificative'), findsOneWidget);
      expect(find.text('Refaire ma demande sur aeenci.com'), findsOneWidget);
    });

    testWidgets('se déconnecter', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.candidate.token,
      );
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.login);
    });

    testWidgets('tirer pour actualiser', (tester) async {
      await pumpAeenci(tester, token: MockPersona.candidate.token);
      await tester.fling(
        find.text('Ta demande est en cours d\'examen'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text('Ta demande est en cours d\'examen'), findsOneWidget);
    });
  });

  group('configuration au démarrage', () {
    testWidgets('mise à jour forcée : écran bloquant', (tester) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        behavior: MockBehavior.instant.copyWith(updateRequired: true),
      );
      expect(location(container), AppRoutes.updateRequired);
      expect(find.text('Mise à jour nécessaire'), findsOneWidget);
      expect(find.text('Mettre à jour'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      container.read(appRouterProvider).go(AppRoutes.card);
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.updateRequired);
    });

    testWidgets('maintenance, puis « Réessayer » quand elle est finie', (
      tester,
    ) async {
      final container = await pumpAeenci(
        tester,
        token: MockPersona.member.token,
        behavior: MockBehavior.instant.copyWith(maintenance: true),
      );
      expect(location(container), AppRoutes.maintenance);
      expect(find.text('Maintenance en cours'), findsOneWidget);
      expect(find.textContaining('Maintenance de test'), findsOneWidget);

      await tapButton(tester, 'Réessayer');
      expect(location(container), AppRoutes.home);
    });

    testWidgets(
      'configuration illisible (hors connexion, sans cache) : on démarre',
      (tester) async {
        final container = await pumpAeenci(
          tester,
          behavior: MockBehavior.instant.copyWith(failure: MockFailure.network),
        );
        expect(location(container), AppRoutes.login);
      },
    );
  });
}
