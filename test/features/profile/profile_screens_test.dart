import 'package:aeenci_app/core/design/components/app_button.dart';
import 'package:aeenci_app/core/design/components/app_switch_tile.dart';
import 'package:aeenci_app/core/design/components/app_text_field.dart';
import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/utils/file_picker_service.dart';
import 'package:aeenci_app/features/notifications/data/notifications_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_aeenci.dart';

/// Sélecteur de fichiers factice : renvoie le fichier préparé.
class FakeFilePicker implements FilePickerService {
  PickedFile? next;
  final calls = <String>[];

  @override
  Future<PickedFile?> pickPhoto(PhotoSource source) async {
    calls.add('photo:${source.name}');
    return next;
  }

  @override
  Future<PickedFile?> pickPdf() async {
    calls.add('pdf');
    return next;
  }

  @override
  Future<PickedFile?> pickDocument() async {
    calls.add('document');
    return next;
  }
}

Future<ProviderContainer> pumpProfile(
  WidgetTester tester, {
  MockPersona persona = MockPersona.member,
  FakeFilePicker? picker,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  final container = await pumpAeenci(
    tester,
    token: persona.token,
    size: size,
    textScale: textScale,
    overrides: [
      filePickerServiceProvider.overrideWithValue(picker ?? FakeFilePicker()),
    ],
  );
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profil'),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Fait défiler la liste visible jusqu'à [finder].
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).hitTestable().first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Remonte en haut de la liste visible.
Future<void> scrollToTop(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).hitTestable().first,
    const Offset(0, 3000),
    5000,
  );
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester, String title) async {
  final row = find.text(title);
  await scrollTo(tester, row);
  await tester.tap(row.first);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label),
  matching: find.byType(TextField),
);

Finder button(String label) =>
    find.byWidgetPredicate((w) => w is AppButton && w.label == label);

Future<void> tapButton(WidgetTester tester, String label) async {
  final target = button(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('profil : en-tête, rubriques, compte', (tester) async {
    await pumpProfile(tester);
    expect(find.text('Membre TEST'), findsOneWidget);
    expect(find.textContaining('TEST-0001 · '), findsOneWidget);
    expect(find.text('Vitrine de talents'), findsOneWidget);
    expect(find.text('2 formations'), findsOneWidget);
    expect(find.text('0 %'), findsOneWidget);
    expect(find.text('À ajouter'), findsOneWidget);
    await scrollTo(tester, find.text('Supprimer mon compte'));
    expect(find.text('Changer de mot de passe'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
  });

  testWidgets('préférences : les catégories modifiables, la note du compte', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final container = await pumpProfile(tester);
    await scrollTo(tester, find.textContaining('toujours envoyés'));
    // « Mon compte » est verrouillé : pas d'interrupteur.
    expect(find.text('Mon compte'), findsNothing);
    final events = find.bySemanticsLabel(RegExp('Notifications : Événements'));
    expect(events, findsOneWidget);

    final tile = find.ancestor(
      of: find.text('Événements'),
      matching: find.byType(AppSwitchTile),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: tile, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    final prefs = await container
        .read(notificationsRepositoryProvider)
        .fetchPreferences();
    expect(
      prefs
          .firstWhere((p) => p.category == NotificationCategory.events)
          .enabled,
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('vitrine : consentement explicite, désactivation directe', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Case jamais pré-cochée, « Activer » grisé tant qu'elle ne l'est pas.
    expect(find.text('Activer la vitrine de talents ?'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isFalse);
    FilledButton activate() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Activer'),
    );
    expect(activate().onPressed, isNull);

    // Annuler : rien ne change.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(activate().onPressed, isNotNull);
    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    expect(find.text('En attente de validation par le bureau'), findsOneWidget);

    // Désactiver : aucune fenêtre.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(find.textContaining('Vitrine désactivée'), findsOneWidget);
  });

  testWidgets('ma fiche : contacts, erreur 422 sous le champ, photo', (
    tester,
  ) async {
    final picker = FakeFilePicker()
      ..next = const PickedFile(
        path: '/tmp/photo.jpg',
        name: 'photo.jpg',
        size: 1000,
      );
    await pumpProfile(tester, picker: picker);
    await open(tester, 'Ma fiche');

    expect(find.text('TEST Membre'), findsOneWidget);
    expect(find.textContaining('secrétaire général'), findsOneWidget);

    await tapButton(tester, 'Modifier');
    await tester.enterText(field('E-mail'), 'adresse-invalide');
    await tester.enterText(field('Ville'), 'Yamoussoukro');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Saisis une adresse e-mail valide.'), findsOneWidget);

    await tester.enterText(field('E-mail'), 'membre.modifie@exemple.com');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Modifications enregistrées ✓'), findsOneWidget);
    expect(find.text('Yamoussoukro'), findsOneWidget);
    expect(find.text('membre.modifie@exemple.com'), findsOneWidget);

    await scrollToTop(tester);
    await tapButton(tester, 'Changer la photo');
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();
    expect(picker.calls, ['photo:camera']);
    expect(find.text('Photo mise à jour.'), findsOneWidget);
  });

  testWidgets('photo trop lourde : refusée avant l\'envoi', (tester) async {
    final picker = FakeFilePicker()
      ..next = const PickedFile(
        path: '/tmp/lourde.jpg',
        name: 'lourde.jpg',
        size: maxUploadBytes + 1,
      );
    await pumpProfile(tester, picker: picker);
    await open(tester, 'Ma fiche');
    await tapButton(tester, 'Changer la photo');
    await tester.tap(find.text('Choisir dans mes photos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dépasse 5 Mo'), findsOneWidget);
  });

  testWidgets('parcours : ajout avec erreur 422, modification, suppression', (
    tester,
  ) async {
    await pumpProfile(tester);
    await open(tester, 'Parcours scolaire');
    expect(find.text('Université de test'), findsOneWidget);
    expect(find.text('Lycée de test'), findsOneWidget);

    await tapButton(tester, 'Ajouter une formation');
    await tester.tap(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Master').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Établissement'), 'École de test');
    await tester.enterText(field('Filière ou spécialité'), 'Gestion');
    await tester.enterText(field('Début'), '2026');
    await tester.enterText(field('Fin'), '2024');
    await tapButton(tester, 'Enregistrer');
    expect(
      find.text('L\'année de fin doit suivre l\'année de début.'),
      findsOneWidget,
    );

    await tester.enterText(field('Fin'), '20');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Saisis une année à 4 chiffres.'), findsOneWidget);

    await tester.enterText(field('Fin'), '');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('École de test'), findsOneWidget);
    expect(find.text('Modifications enregistrées ✓'), findsOneWidget);

    // Suppression, après confirmation.
    await tester.tap(find.text('Lycée de test'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer la formation').last);
    await tester.tap(find.text('Supprimer la formation').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Supprimer « Lycée de test » de ton parcours ?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Lycée de test'), findsNothing);
  });

  testWidgets('profil pro : en bref, compétences, LinkedIn, taux', (
    tester,
  ) async {
    await pumpProfile(tester);
    await open(tester, 'Profil professionnel');
    expect(find.text('Profil complété à 0 %'), findsOneWidget);

    await tapButton(tester, 'Modifier');
    await tester.enterText(field('Titre'), 'Titre de test');
    await tester.enterText(field('Domaine'), 'Domaine de test');
    await tester.enterText(field('Ville'), 'Abidjan');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Titre de test'), findsOneWidget);
    await scrollToTop(tester);
    expect(find.text('Profil complété à 38 %'), findsOneWidget);

    final skill = find.byWidgetPredicate(
      (w) =>
          w is TextField && w.decoration?.hintText == 'Ajouter une compétence',
    );
    await scrollTo(tester, skill);
    await tester.enterText(skill, 'Compétence de test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Compétence de test'), findsOneWidget);
    await scrollToTop(tester);
    expect(find.text('Profil complété à 50 %'), findsOneWidget);
    await scrollTo(tester, find.text('Compétence de test'));

    await tester.tap(find.byTooltip('Retirer Compétence de test'));
    await tester.pumpAndSettle();
    expect(find.text('Compétence de test'), findsNothing);

    // La barre de confirmation précédente disparaît d'abord.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Profil LinkedIn : non renseigné'));
    await tester.tap(find.text('Profil LinkedIn : non renseigné'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Profil LinkedIn'), 'linkedin.com/in/test');
    await tapButton(tester, 'Enregistrer');
    expect(
      find.text('Saisis une adresse qui commence par https://.'),
      findsOneWidget,
    );
    await tester.enterText(
      field('Profil LinkedIn'),
      'https://www.linkedin.com/in/test',
    );
    await tapButton(tester, 'Enregistrer');
    expect(find.text('https://www.linkedin.com/in/test'), findsOneWidget);
  });

  testWidgets('profil pro : expérience avec dates, CV, réalisation', (
    tester,
  ) async {
    final picker = FakeFilePicker();
    await pumpProfile(tester, picker: picker);
    await open(tester, 'Profil professionnel');

    await scrollTo(tester, button('Ajouter une expérience'));
    await tapButton(tester, 'Ajouter une expérience');
    await tester.enterText(field('Poste'), 'Stagiaire de test');
    await tester.enterText(field('Organisation'), 'Organisation de test');
    // Début obligatoire, vérifié avant l'envoi.
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J\'occupe ce poste actuellement'));
    await tester.pumpAndSettle();
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Stagiaire de test'), findsOneWidget);
    expect(find.textContaining('aujourd\'hui'), findsOneWidget);

    // CV trop lourd, puis CV valable.
    picker.next = const PickedFile(
      path: '/tmp/cv.pdf',
      name: 'cv.pdf',
      size: maxUploadBytes + 1,
    );
    await scrollTo(tester, button('Téléverser'));
    await tapButton(tester, 'Téléverser');
    expect(
      find.text('Ce fichier dépasse 5 Mo. Choisis un PDF plus léger.'),
      findsOneWidget,
    );
    picker.next = const PickedFile(
      path: '/tmp/cv.pdf',
      name: 'cv.pdf',
      size: 2000,
    );
    await tapButton(tester, 'Téléverser');
    expect(find.text('CV enregistré'), findsOneWidget);
    expect(button('Remplacer'), findsOneWidget);

    // Réalisation avec un fichier joint.
    picker.next = const PickedFile(
      path: '/tmp/projet.png',
      name: 'projet.png',
      size: 3000,
    );
    await scrollTo(tester, button('Ajouter une réalisation'));
    await tapButton(tester, 'Ajouter une réalisation');
    await tester.enterText(field('Titre'), 'Réalisation de test');
    await tapButton(tester, 'Choisir un fichier');
    expect(find.text('Fichier : projet.png'), findsOneWidget);
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Réalisation de test'), findsOneWidget);
    expect(find.text('Fichier joint'), findsOneWidget);
  });

  testWidgets('mot de passe : ancien incorrect sous le champ, puis changé', (
    tester,
  ) async {
    await pumpProfile(tester);
    await open(tester, 'Changer de mot de passe');
    await tester.enterText(field('Mot de passe actuel'), 'faux');
    await tester.enterText(field('Nouveau mot de passe'), 'nouveau-mdp');
    await tester.enterText(field('Confirme le mot de passe'), 'nouveau-mdp');
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Le mot de passe actuel est incorrect.'), findsOneWidget);

    await tester.enterText(field('Mot de passe actuel'), mockPassword);
    await tapButton(tester, 'Enregistrer');
    expect(find.text('Mot de passe modifié.'), findsOneWidget);
    expect(find.text('Changer de mot de passe'), findsOneWidget);
    expect(find.byType(AppTextField), findsNothing);
  });

  testWidgets('suppression du compte : mot de passe, puis connexion', (
    tester,
  ) async {
    await pumpProfile(tester);
    await open(tester, 'Supprimer mon compte');
    final confirm = find.text('Supprimer définitivement mon compte');

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

    await tester.enterText(field('Confirme avec ton mot de passe'), 'faux');
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Le mot de passe est incorrect.'), findsOneWidget);

    await tester.enterText(
      field('Confirme avec ton mot de passe'),
      mockPassword,
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ton compte a été supprimé.'), findsOneWidget);
  });

  for (final screen in [
    null,
    'Ma fiche',
    'Parcours scolaire',
    'Profil professionnel',
  ]) {
    testWidgets('${screen ?? 'Profil'} à 200 % sur un petit écran', (
      tester,
    ) async {
      await pumpProfile(tester, size: const Size(320, 640), textScale: 2);
      if (screen != null) await open(tester, screen);
      final scrollable = find.byType(Scrollable).hitTestable().first;
      for (var i = 0; i < 12; i++) {
        await tester.drag(scrollable, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
