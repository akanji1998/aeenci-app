import 'package:aeenci_app/core/api/api_exception.dart';
import 'package:aeenci_app/core/api/api_providers.dart';
import 'package:aeenci_app/core/mock/mock_card_signer.dart';
import 'package:aeenci_app/core/mock/mock_data.dart';
import 'package:aeenci_app/features/scan/data/attendance_repository.dart';
import 'package:aeenci_app/features/scan/data/scan_queue_store.dart';
import 'package:aeenci_app/features/scan/domain/attendance_scan.dart';
import 'package:aeenci_app/features/scan/presentation/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/pump_aeenci.dart';

/// Caméra factice : un bouton par carte à « présenter ».
class FakeCamera {
  ValueChanged<String>? onCode;

  Widget build(BuildContext context, ValueChanged<String> onCode) {
    this.onCode = onCode;
    return const SizedBox.expand();
  }

  Future<void> show(WidgetTester tester, String payload) async {
    onCode!(payload);
    await settle(tester);
  }
}

/// La vérification Ed25519 et les envois sont de vrais travaux
/// asynchrones : on les laisse finir hors du temps simulé.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

Future<String> card(
  MockPersona persona, {
  Duration validFor = const Duration(days: 20),
}) {
  final now = DateTime.now();
  return signMockCard(
    memberId: persona.meJson['id']! as int,
    memberNumber: (persona.meJson['member_number'] as String?) ?? 'TEST',
    issuedAt: now.subtract(const Duration(days: 10)),
    expiresAt: now.add(validFor),
  );
}

/// Réseau coupé tant que [online] est faux.
class _Flaky implements AttendanceRepository {
  _Flaky(this._inner);

  final MockAttendanceRepository _inner;
  bool online = false;

  @override
  Future<List<AttendanceMeeting>> fetchMeetings() => _inner.fetchMeetings();

  @override
  Future<List<ScanResult>> sendScans(ScanBatch batch) async {
    if (!online) throw const NetworkException();
    return _inner.sendScans(batch);
  }
}

void main() {
  late FakeCamera camera;

  setUp(() => camera = FakeCamera());

  Future<ProviderContainer> openScan(
    WidgetTester tester, {
    ScanQueueStore? queue,
    List<Override> overrides = const [],
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    final container = await pumpAeenci(
      tester,
      token: MockPersona.bureau.token,
      scanQueue: queue,
      size: size,
      textScale: textScale,
      overrides: [
        scannerViewProvider.overrideWithValue(camera.build),
        ...overrides,
      ],
    );
    await tester.ensureVisible(find.text('Scanner les présences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanner les présences'));
    await settle(tester);
    return container;
  }

  testWidgets('la carte de scan n\'apparaît que pour le bureau', (
    tester,
  ) async {
    await pumpAeenci(tester, token: MockPersona.member.token);
    expect(find.text('Scanner les présences'), findsNothing);
  });

  testWidgets('scan : enregistré, déjà scanné, expiré, code quelconque', (
    tester,
  ) async {
    await openScan(tester);
    expect(find.textContaining('Assemblée du'), findsOneWidget);
    expect(find.text('3 présences enregistrées'), findsOneWidget);

    await camera.show(tester, await card(MockPersona.member));
    expect(find.text('Présence enregistrée'), findsOneWidget);
    expect(find.textContaining('Membre TEST'), findsOneWidget);
    expect(find.text('4 présences enregistrées'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    // La carte reste devant la caméra : lectures répétées ignorées.
    final first = await card(MockPersona.member);
    await camera.show(tester, first);
    await camera.show(tester, first);

    await camera.show(tester, await card(MockPersona.bureau));
    expect(find.text('5 présences enregistrées'), findsOneWidget);

    // Le même membre plus tard : déjà scanné, rien n'est envoyé.
    await camera.show(tester, await card(MockPersona.member));
    expect(find.text('Déjà enregistrée'), findsOneWidget);
    expect(find.text('5 présences enregistrées'), findsOneWidget);

    await camera.show(
      tester,
      await card(MockPersona.bureau, validFor: const Duration(days: -1)),
    );
    expect(find.text('Carte expirée'), findsOneWidget);

    await camera.show(tester, 'https://exemple.com/pas-une-carte');
    expect(find.text('Code non valide'), findsOneWidget);
    expect(find.text('5 présences enregistrées'), findsOneWidget);
  });

  testWidgets('candidat : pas de fiche admise', (tester) async {
    await openScan(tester);
    await camera.show(tester, await card(MockPersona.candidate));
    expect(find.text('Pas un membre admis'), findsOneWidget);
  });

  testWidgets('hors connexion : en file, envoyé au retour sans doublon', (
    tester,
  ) async {
    late _Flaky repo;
    final queue = MemoryScanQueueStore();
    await openScan(
      tester,
      queue: queue,
      overrides: [
        attendanceRepositoryProvider.overrideWith(
          (ref) => repo = _Flaky(
            MockAttendanceRepository(
              ref.watch(mockRuntimeProvider),
              ref.watch(tokenStoreProvider),
            ),
          ),
        ),
      ],
    );
    await camera.show(tester, await card(MockPersona.member));
    expect(find.text('Carte valide'), findsOneWidget);
    expect(find.text('1 scan en attente d\'envoi'), findsOneWidget);
    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(await queue.pendingTotal(), 1);

    // Retour du réseau : un seul envoi, la file se vide.
    repo.online = true;
    await tester.ensureVisible(find.text('Envoyer maintenant'));
    await tester.tap(find.text('Envoyer maintenant'));
    await settle(tester);
    expect(find.text('4 présences enregistrées'), findsOneWidget);
    expect(await queue.pendingTotal(), 0);
    expect(repo._inner.batches, hasLength(1));
    expect(repo._inner.batches.single.scans, hasLength(1));
    // Plus rien en attente : le bouton d'envoi disparaît.
    expect(find.text('Envoyer maintenant'), findsNothing);
  });

  testWidgets('la file d\'un démarrage précédent part à l\'ouverture', (
    tester,
  ) async {
    final queue = MemoryScanQueueStore();
    await queue.write(12, [
      Scan(
        qrPayload: await card(MockPersona.member),
        scannedAt: DateTime.now().toUtc(),
      ),
    ]);
    await openScan(tester, queue: queue);
    expect(await queue.pendingTotal(), 0);
    expect(find.text('4 présences enregistrées'), findsOneWidget);
  });

  testWidgets('déconnexion avec des scans en attente : avertissement', (
    tester,
  ) async {
    final queue = MemoryScanQueueStore();
    await queue.write(12, [
      Scan(qrPayload: 'AEENCI1.a.b', scannedAt: DateTime.now().toUtc()),
    ]);
    await pumpAeenci(tester, token: MockPersona.bureau.token, scanQueue: queue);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Se déconnecter'),
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Présences pas encore envoyées'), findsOneWidget);
    expect(find.textContaining('1 présence scannée'), findsOneWidget);

    // Annuler : toujours connecté, file intacte.
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await queue.pendingTotal(), 1);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer d\'abord'));
    await settle(tester);
    expect(await queue.pendingTotal(), 0);
    expect(find.text('Se connecter'), findsWidgets);
  });

  testWidgets('scan à 200 % sur un petit écran', (tester) async {
    await openScan(tester, size: const Size(320, 640), textScale: 2);
    await camera.show(tester, await card(MockPersona.member));
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
