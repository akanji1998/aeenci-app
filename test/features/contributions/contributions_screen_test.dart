import 'dart:convert';

import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/api/paginated.dart';
import 'package:aeenci_app/core/cache/file_store.dart';
import 'package:aeenci_app/core/mock/mock_behavior.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/core/utils/academic_year.dart';
import 'package:aeenci_app/core/utils/device_services.dart';
import 'package:aeenci_app/features/contributions/data/contributions_repository.dart';
import 'package:aeenci_app/features/contributions/domain/contribution.dart';
import 'package:aeenci_app/features/contributions/presentation/contributions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_device_services.dart';
import '../../helpers/pump_aeenci.dart';

/// Réseau coupé pour toutes les requêtes (mode avion).
const offline = MockBehavior(
  latency: Duration.zero,
  failure: MockFailure.network,
  failOnce: false,
);

Future<void> openContributions(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Cotisations'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byType(ContributionsScreen),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// Ouvre la feuille du reçu du paiement [label].
Future<void> openReceipt(WidgetTester tester, String label) async {
  final row = find.bySemanticsLabel(RegExp('^Reçu : ${RegExp.escape(label)}'));
  await scrollTo(tester, row);
  await tester.tap(row);
  await tester.pumpAndSettle();
}

class _ReceiptNotFound implements ContributionsRepository {
  _ReceiptNotFound(this._inner);

  final ContributionsRepository _inner;

  @override
  Future<List<int>> downloadReceipt(int paymentId) async =>
      throw const NotFoundException();
  @override
  Future<List<Contribution>> fetchContributions() =>
      _inner.fetchContributions();
  @override
  Future<Paginated<Payment>> fetchPayments({int page = 1}) =>
      _inner.fetchPayments(page: page);
}

void main() {
  final year = academicYearOf(DateTime.now());
  final previous = academicYearOf(
    DateTime(DateTime.now().year - 1, DateTime.now().month),
  );

  testWidgets('année en cours, comment payer, mes années, paiements', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAeenci(tester, token: MockPersona.member.token);
    await openContributions(tester);

    expect(find.text('Année $year'), findsWidgets);
    expect(find.text('Payée en partie'), findsWidgets);
    expect(
      find.textContaining(RegExp(r'2\s000 / 6\s000 F CFA')),
      findsOneWidget,
    );
    expect(find.text('Reste à payer'), findsOneWidget);

    await scrollTo(tester, find.text('Comment payer ?'));
    expect(find.text('Orange Money'), findsOneWidget);
    expect(find.text('+225 00 00 00 00 91'), findsOneWidget);
    expect(find.text('Au nom de AEENCI (compte de test)'), findsWidgets);

    await scrollTo(tester, find.text('Année $previous'));
    expect(find.text('Payée'), findsWidgets);

    // Première page des paiements : l'année en cours et la précédente.
    await scrollTo(tester, find.text('Cotisation $previous'));
    expect(find.text('Cotisation $year'), findsOneWidget);
    expect(find.text('Droit d\'adhésion'), findsNothing);

    // Page suivante : le droit d'adhésion apparaît dans les paiements et
    // dans « Mes années ».
    await scrollTo(tester, find.text('Voir les paiements précédents'));
    await tester.tap(find.text('Voir les paiements précédents'));
    await tester.pumpAndSettle();
    expect(find.text('Droit d\'adhésion'), findsNWidgets(2));
    expect(find.text('Voir les paiements précédents'), findsNothing);
    semantics.dispose();
  });

  testWidgets('copier un numéro Mobile Money', (tester) async {
    final device = FakeDeviceServices();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await openContributions(tester);
    await scrollTo(tester, find.text('+225 00 00 00 00 91'));
    await tester.tap(find.text('Copier').first);
    await tester.pumpAndSettle();
    expect(device.copied, ['+225 00 00 00 00 91']);
    expect(find.text('Copié'), findsOneWidget);
  });

  testWidgets('un reçu s\'ouvre et se partage', (tester) async {
    final semantics = tester.ensureSemantics();
    final device = FakeDeviceServices();
    final files = MemoryFileStore();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      files: files,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await openContributions(tester);
    await openReceipt(tester, 'Cotisation $year');

    expect(find.textContaining('Reçu REC-'), findsOneWidget);
    expect(find.textContaining('dès que tu l\'auras ouvert'), findsOneWidget);

    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    expect(device.openedFiles, hasLength(1));
    final stored = files.files.values.single;
    expect(ascii.decode(stored.take(8).toList()), startsWith('%PDF'));
    expect(find.textContaining('gardé sur ton téléphone'), findsOneWidget);

    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();
    expect(device.sharedFiles, [device.openedFiles.single]);
    semantics.dispose();
  });

  testWidgets('un reçu déjà ouvert s\'ouvre en mode avion', (tester) async {
    final semantics = tester.ensureSemantics();
    final device = FakeDeviceServices();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await openContributions(tester);
    await openReceipt(tester, 'Cotisation $year');
    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    // Mode avion : aucune requête ne passe.
    container.read(mockBehaviorControllerProvider.notifier).set(offline);
    await openReceipt(tester, 'Cotisation $year');
    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    expect(device.openedFiles, hasLength(2));
    expect(device.openedFiles.toSet(), hasLength(1));
    expect(
      find.text('Connecte-toi à Internet pour télécharger ce reçu.'),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('reçu jamais ouvert, hors connexion : message clair', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final device = FakeDeviceServices();
    final container = await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [deviceServicesProvider.overrideWithValue(device)],
    );
    await openContributions(tester);
    container.read(mockBehaviorControllerProvider.notifier).set(offline);
    await openReceipt(tester, 'Cotisation $year');
    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    expect(
      find.text('Connecte-toi à Internet pour télécharger ce reçu.'),
      findsOneWidget,
    );
    expect(device.openedFiles, isEmpty);
    semantics.dispose();
  });

  testWidgets('reçu introuvable (404)', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [
        contributionsRepositoryProvider.overrideWith(
          (ref) => _ReceiptNotFound(
            MockContributionsRepository(
              ref.watch(mockRuntimeProvider),
              ref.watch(tokenStoreProvider),
            ),
          ),
        ),
      ],
    );
    await openContributions(tester);
    await openReceipt(tester, 'Cotisation $year');
    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Ce reçu est introuvable.'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('aucune application pour ouvrir le PDF', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      overrides: [
        deviceServicesProvider.overrideWithValue(
          FakeDeviceServices(canOpenFiles: false),
        ),
      ],
    );
    await openContributions(tester);
    await openReceipt(tester, 'Cotisation $year');
    await tester.tap(find.text('Ouvrir le PDF'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune application ne peut ouvrir ce PDF sur ton téléphone.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('à 200 % sur un petit écran, sans débordement', (tester) async {
    await pumpAeenci(
      tester,
      token: MockPersona.member.token,
      size: const Size(320, 568),
      textScale: 2,
    );
    await openContributions(tester);
    await scrollTo(tester, find.text('Voir les paiements précédents'));
    expect(tester.takeException(), isNull);
  });
}
